#!/bin/bash

# 完全自动化部署脚本 - 适用于 Python 3.9+
# 使用方法: ./auto-deploy.sh [backend_port] [frontend_port]

set -e  # 遇到错误立即退出

BACKEND_PORT=${1:-5007}
FRONTEND_PORT=${2:-5008}

echo "=========================================="
echo "完全自动化部署脚本"
echo "=========================================="
echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo "=========================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 拉取最新代码
echo ""
echo "1. 拉取最新代码..."
git pull || echo "警告: git pull 失败，继续执行..."

# 2. 停止所有服务
echo ""
echo "2. 停止所有服务..."
./stop.sh 2>/dev/null || true
pkill -f "python3 manage.py runserver" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
pkill -f "node.*vite" 2>/dev/null || true
sleep 2

# 3. 清理端口占用
echo ""
echo "3. 清理端口占用..."
for port in $BACKEND_PORT $FRONTEND_PORT; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        echo "端口 $port 被占用，正在停止进程 $PID..."
        kill -9 $PID 2>/dev/null || true
        sleep 1
    fi
done

# 4. 安装前端依赖
echo ""
echo "4. 检查前端依赖..."
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
else
    echo "✅ 前端依赖已存在"
fi

# 5. 删除旧的虚拟环境（如果存在）
echo ""
echo "5. 准备后端环境..."
if [ -d "backend/backend-env" ]; then
    echo "删除旧的虚拟环境..."
    rm -rf backend/backend-env
fi
if [ -d "backend-env" ]; then
    echo "删除旧的虚拟环境（上级目录）..."
    rm -rf backend-env
fi

# 6. 检查 Python 版本
echo ""
echo "6. 检查 Python 版本..."
PYTHON_VERSION=$(python3 --version 2>&1 || echo "unknown")
echo "Python 版本: $PYTHON_VERSION"

PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo "3")
PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo "6")

if [ "$PYTHON_MAJOR" -lt 3 ] || ([ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]); then
    echo "⚠️  警告: Python 版本低于 3.8，将使用兼容版本的依赖"
    USE_COMPAT=true
else
    echo "✅ Python 版本符合要求（3.8+）"
    USE_COMPAT=false
fi

# 7. 创建虚拟环境
echo ""
echo "7. 创建虚拟环境..."
cd backend
python3 -m venv backend-env
source backend-env/bin/activate

# 验证虚拟环境中的 Python 版本
VENV_PYTHON_VERSION=$(python3 --version 2>&1)
echo "虚拟环境 Python 版本: $VENV_PYTHON_VERSION"

# 8. 安装后端依赖
echo ""
echo "8. 安装后端依赖..."
pip install -q --upgrade pip

if [ "$USE_COMPAT" = true ] && [ -f "requirements-compat.txt" ]; then
    echo "使用兼容版本的依赖文件..."
    pip install -q -r requirements-compat.txt
else
    echo "使用标准依赖文件..."
    pip install -q -r requirements.txt
fi

# 9. 执行数据库迁移
echo ""
echo "9. 执行数据库迁移..."
python3 manage.py migrate --noinput || echo "警告: 数据库迁移失败"

# 10. 验证 Django
echo ""
echo "10. 验证 Django 安装..."
python3 manage.py check || {
    echo "❌ Django 配置检查失败"
    cd ..
    exit 1
}
echo "✅ Django 配置正常"

cd ..

# 11. 启动服务
echo ""
echo "11. 启动服务..."
chmod +x start.sh stop.sh 2>/dev/null || true
./start.sh $BACKEND_PORT $FRONTEND_PORT

# 12. 等待服务启动
echo ""
echo "12. 等待服务启动..."
sleep 5

# 13. 检查服务状态
echo ""
echo "13. 检查服务状态..."

# 检查后端
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程运行中 (PID: $BACKEND_PID)"
    else
        echo "❌ 后端进程未运行"
        echo "后端日志:"
        tail -20 backend.log
    fi
else
    echo "⚠️  未找到 backend.pid"
fi

# 检查前端
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ 前端进程运行中 (PID: $FRONTEND_PID)"
    else
        echo "❌ 前端进程未运行"
        echo "前端日志:"
        tail -20 frontend.log
    fi
else
    echo "⚠️  未找到 frontend.pid"
fi

# 检查端口
echo ""
echo "端口监听状态:"
for port in $BACKEND_PORT $FRONTEND_PORT; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "✅ 端口 $port 正在监听"
    else
        echo "❌ 端口 $port 未监听"
    fi
done

# 14. 显示访问信息
echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo "访问地址："
echo "  前端: http://110.40.153.38:$FRONTEND_PORT"
echo "  后端 API: http://110.40.153.38:$BACKEND_PORT/api"
echo ""
echo "查看日志："
echo "  tail -f backend.log"
echo "  tail -f frontend.log"
echo ""
echo "停止服务："
echo "  ./stop.sh"
echo "=========================================="

