#!/bin/bash

# 自动化部署脚本
# 使用方法: ./deploy.sh [backend_port] [frontend_port]

# 不立即退出，允许错误处理
set +e

# 获取端口参数（如果未提供，使用默认值）
BACKEND_PORT=${1:-5000}
FRONTEND_PORT=${2:-5001}

echo "=========================================="
echo "自动化部署脚本"
echo "=========================================="
echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查是否在正确的目录
if [ ! -f "backend/manage.py" ]; then
    echo "错误: 找不到 backend/manage.py，请确保在项目根目录运行此脚本"
    exit 1
fi

# 1. 拉取最新代码
echo ""
echo "1. 拉取最新代码..."
git pull || echo "警告: git pull 失败，继续执行..."

# 2. 停止可能存在的旧服务
echo ""
echo "2. 停止旧服务..."
if [ -f "stop.sh" ]; then
    chmod +x stop.sh
    ./stop.sh || true
fi

# 清理可能的残留进程
pkill -f "python3 manage.py runserver" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

# 3. 安装前端依赖
echo ""
echo "3. 检查并安装前端依赖..."
if [ ! -d "node_modules" ]; then
    echo "安装 npm 依赖..."
    npm install
else
    echo "✅ node_modules 已存在"
fi

# 4. 安装后端依赖
echo ""
echo "4. 检查并安装后端依赖..."
cd backend

# 检查虚拟环境
if [ -d "backend-env" ]; then
    echo "✅ 虚拟环境已存在"
    source backend-env/bin/activate
elif [ -d "../backend-env" ]; then
    echo "✅ 虚拟环境已存在（在上级目录）"
    source ../backend-env/bin/activate
else
    echo "创建虚拟环境..."
    python3 -m venv backend-env
    source backend-env/bin/activate
fi

# 检测 Python 版本并选择合适的 requirements 文件
echo "检测 Python 版本..."
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))' 2>/dev/null || echo "unknown")
PYTHON_MAJOR=$(python3 -c 'import sys; print(sys.version_info[0])' 2>/dev/null || echo "3")
PYTHON_MINOR=$(python3 -c 'import sys; print(sys.version_info[1])' 2>/dev/null || echo "6")

echo "Python 版本: $PYTHON_VERSION"

# 安装 Python 依赖
echo "安装 Python 依赖..."
pip install -q --upgrade pip 2>/dev/null || pip install --upgrade pip

# 先尝试使用兼容版本（适用于旧 Python）
if [ -f "requirements-compat.txt" ]; then
    echo "尝试使用兼容版本的依赖文件..."
    if pip install -q -r requirements-compat.txt 2>/dev/null; then
        echo "✅ 使用兼容版本依赖安装成功"
    else
        echo "⚠️  兼容版本安装失败，尝试使用默认 requirements.txt..."
        if pip install -r requirements.txt 2>/dev/null; then
            echo "✅ 使用默认依赖安装成功"
        else
            echo "❌ 依赖安装失败，请检查 Python 版本和网络连接"
            echo "提示: 如果 Python 版本 < 3.8，请确保 requirements-compat.txt 存在"
            exit 1
        fi
    fi
else
    echo "使用默认 requirements.txt..."
    if pip install -q -r requirements.txt 2>/dev/null; then
        echo "✅ 依赖安装成功"
    else
        echo "❌ 依赖安装失败，请检查 Python 版本和网络连接"
        exit 1
    fi
fi

# 执行数据库迁移
echo "执行数据库迁移..."
python3 manage.py migrate --noinput || echo "警告: 数据库迁移失败，继续执行..."

cd ..

# 5. 确保脚本可执行
echo ""
echo "5. 设置脚本权限..."
chmod +x start.sh stop.sh check.sh 2>/dev/null || true

# 6. 启动服务
echo ""
echo "6. 启动服务..."
./start.sh $BACKEND_PORT $FRONTEND_PORT

# 7. 等待服务启动
echo ""
echo "7. 等待服务启动..."
sleep 5

# 8. 检查服务状态
echo ""
echo "8. 检查服务状态..."
if [ -f "check.sh" ]; then
    ./check.sh
else
    echo "检查进程..."
    if [ -f "backend.pid" ]; then
        BACKEND_PID=$(cat backend.pid)
        if ps -p $BACKEND_PID > /dev/null 2>&1; then
            echo "✅ 后端进程运行中 (PID: $BACKEND_PID)"
        else
            echo "❌ 后端进程未运行"
        fi
    fi
    
    if [ -f "frontend.pid" ]; then
        FRONTEND_PID=$(cat frontend.pid)
        if ps -p $FRONTEND_PID > /dev/null 2>&1; then
            echo "✅ 前端进程运行中 (PID: $FRONTEND_PID)"
        else
            echo "❌ 前端进程未运行"
        fi
    fi
fi

# 9. 显示访问信息
echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo "访问地址："
echo "  前端: http://110.40.153.38:$FRONTEND_PORT"
echo "  后端 API: http://110.40.153.38:$BACKEND_PORT/api"
echo ""
echo "查看日志："
echo "  tail -f backend.log    # 后端日志"
echo "  tail -f frontend.log   # 前端日志"
echo ""
echo "停止服务："
echo "  ./stop.sh"
echo "=========================================="

