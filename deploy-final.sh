#!/bin/bash

# 最终部署脚本 - 完全按照部署教程要求
# 使用方法: ./deploy-final.sh [backend_port] [frontend_port]
# 示例: ./deploy-final.sh 5009 5010  (IP访问，端口范围5000-5010)
# 示例: ./deploy-final.sh 8806 8807  (域名访问，mathew的端口是8806)

# set -e  # 暂时注释掉，允许错误处理

BACKEND_PORT=${1:-5009}
FRONTEND_PORT=${2:-5010}

echo "=========================================="
echo "🚀 最终部署脚本 - 按照部署教程"
echo "=========================================="
echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo "=========================================="

# 检查端口范围（IP访问必须在5000-5010）
if [ "$BACKEND_PORT" -lt 5000 ] || [ "$BACKEND_PORT" -gt 5010 ]; then
    if [ "$BACKEND_PORT" -ne 8806 ]; then
        echo "⚠️  警告: 后端端口 $BACKEND_PORT 不在 5000-5010 范围内"
        echo "   如果使用IP访问，端口必须在 5000-5010 之间"
        echo "   如果使用域名访问，mathew 的端口是 8806"
    fi
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 步骤 1: 从 GitHub 下载/更新代码
echo ""
echo "📥 步骤 1: 从 GitHub 更新代码..."
if [ ! -d ".git" ]; then
    echo "❌ 错误: 当前目录不是 Git 仓库"
    echo "   请先运行: git clone https://ghfast.top/https://github.com/Mathewmsj/Diss-My-Teacher.git"
    exit 1
fi

git pull || {
    echo "⚠️  警告: git pull 失败，继续执行..."
}

# 步骤 2: 停止所有旧服务
echo ""
echo "🛑 步骤 2: 停止旧服务..."
if [ -f "stop.sh" ]; then
    chmod +x stop.sh
    ./stop.sh 2>/dev/null || true
fi

# 清理所有相关进程
pkill -f "python3 manage.py runserver" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
pkill -f "node.*vite" 2>/dev/null || true
sleep 2

# 清理端口占用
echo ""
echo "🔍 检查端口占用..."
for port in $BACKEND_PORT $FRONTEND_PORT; do
    PID=$(lsof -ti :$port 2>/dev/null || true)
    if [ ! -z "$PID" ] && [ "$PID" != "" ]; then
        echo "   端口 $port 被进程 $PID 占用，正在停止..."
        kill -9 $PID 2>/dev/null || true
        sleep 1
    else
        echo "   端口 $port 空闲"
    fi
done
echo "   端口检查完成，继续执行..."

# 步骤 3: 安装前端依赖
echo ""
echo "📦 步骤 3: 安装前端依赖..."
if [ ! -d "node_modules" ]; then
    echo "   安装 npm 依赖..."
    npm install
else
    echo "   ✅ 前端依赖已存在"
fi

# 步骤 4: 准备后端环境
echo ""
echo "🐍 步骤 4: 准备后端环境..."

# 删除旧的虚拟环境（如果存在）
if [ -d "backend/backend-env" ]; then
    echo "   删除旧的虚拟环境..."
    rm -rf backend/backend-env
fi

cd backend

# 检查可用的 Python 版本
echo "   检查可用的 Python 版本..."
if command -v python3.9 >/dev/null 2>&1; then
    PYTHON_CMD="python3.9"
    echo "   ✅ 找到 Python 3.9"
elif command -v python3.8 >/dev/null 2>&1; then
    PYTHON_CMD="python3.8"
    echo "   ✅ 找到 Python 3.8"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
    echo "   ⚠️  使用默认 python3"
else
    echo "   ❌ 未找到 Python 3"
    cd ..
    exit 1
fi

# 检查 Python 版本
PYTHON_VERSION=$($PYTHON_CMD --version 2>&1)
echo "   使用 Python: $PYTHON_VERSION"

PYTHON_MAJOR=$($PYTHON_CMD -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo "3")
PYTHON_MINOR=$($PYTHON_CMD -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo "6")

# 创建虚拟环境（使用检测到的 Python 版本）
echo "   创建虚拟环境..."
$PYTHON_CMD -m venv backend-env
source backend-env/bin/activate

# 验证虚拟环境
VENV_PYTHON=$(python3 --version 2>&1)
echo "   虚拟环境 Python: $VENV_PYTHON"

# 再次检查虚拟环境中的 Python 版本
VENV_PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null || echo "3")
VENV_PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo "6")

# 安装后端依赖
echo "   安装后端依赖..."
pip install -q --upgrade pip

# 使用虚拟环境中的 Python 版本判断
if [ "$VENV_PYTHON_MAJOR" -ge 3 ] && [ "$VENV_PYTHON_MINOR" -ge 8 ]; then
    echo "   使用标准依赖文件 (Django 4.2.7)..."
    pip install -q -r requirements.txt
else
    echo "   ⚠️  Python 版本较旧 ($VENV_PYTHON_MAJOR.$VENV_PYTHON_MINOR)，使用兼容版本..."
    if [ -f "requirements-compat.txt" ]; then
        pip install -q -r requirements-compat.txt
    else
        echo "   ❌ 找不到兼容版本的依赖文件"
        cd ..
        exit 1
    fi
fi

# 执行数据库迁移
echo "   执行数据库迁移..."
python3 manage.py migrate --noinput || echo "   ⚠️  数据库迁移失败，继续执行..."

# 验证 Django
echo "   验证 Django 配置..."
python3 manage.py check || {
    echo "   ❌ Django 配置检查失败"
    cd ..
    exit 1
}
echo "   ✅ Django 配置正常"

cd ..

# 步骤 5: 启动服务（使用 nohup 后台运行）
echo ""
echo "🚀 步骤 5: 启动服务..."

# 确保脚本可执行
chmod +x start.sh stop.sh 2>/dev/null || true

# 使用启动脚本启动服务
./start.sh $BACKEND_PORT $FRONTEND_PORT

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 5

# 步骤 6: 验证服务状态
echo ""
echo "✅ 步骤 6: 验证服务状态..."

# 检查后端
BACKEND_OK=false
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "   ✅ 后端进程运行中 (PID: $BACKEND_PID)"
        BACKEND_OK=true
    else
        echo "   ❌ 后端进程未运行"
    fi
else
    echo "   ⚠️  未找到 backend.pid"
fi

# 检查前端
FRONTEND_OK=false
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "   ✅ 前端进程运行中 (PID: $FRONTEND_PID)"
        FRONTEND_OK=true
    else
        echo "   ❌ 前端进程未运行"
    fi
else
    echo "   ⚠️  未找到 frontend.pid"
fi

# 检查端口监听
echo ""
echo "🔍 检查端口监听状态..."
BACKEND_PORT_OK=false
FRONTEND_PORT_OK=false

if lsof -i :$BACKEND_PORT >/dev/null 2>&1; then
    echo "   ✅ 后端端口 $BACKEND_PORT 正在监听"
    BACKEND_PORT_OK=true
else
    echo "   ❌ 后端端口 $BACKEND_PORT 未监听"
    if [ "$BACKEND_OK" = false ]; then
        echo "   后端日志:"
        tail -20 backend.log 2>/dev/null || echo "   无法读取日志"
    fi
fi

if lsof -i :$FRONTEND_PORT >/dev/null 2>&1; then
    echo "   ✅ 前端端口 $FRONTEND_PORT 正在监听"
    FRONTEND_PORT_OK=true
else
    echo "   ❌ 前端端口 $FRONTEND_PORT 未监听"
    if [ "$FRONTEND_OK" = false ]; then
        echo "   前端日志:"
        tail -20 frontend.log 2>/dev/null || echo "   无法读取日志"
    fi
fi

# 显示访问信息
echo ""
echo "=========================================="
echo "🎉 部署完成！"
echo "=========================================="

if [ "$BACKEND_PORT_OK" = true ] && [ "$FRONTEND_PORT_OK" = true ]; then
    echo ""
    echo "✅ 服务运行正常！"
    echo ""
    echo "📱 访问地址："
    
    # 判断是IP访问还是域名访问
    if [ "$BACKEND_PORT" -ge 5000 ] && [ "$BACKEND_PORT" -le 5010 ]; then
        echo "   🌐 IP 直接访问："
        echo "      前端: http://110.40.153.38:$FRONTEND_PORT"
        echo "      后端 API: http://110.40.153.38:$BACKEND_PORT/api"
    elif [ "$BACKEND_PORT" -eq 8806 ]; then
        echo "   🌍 域名访问："
        echo "      前端: http://mathew.yunguhs.com"
        echo "      或: https://mathew.yunguhs.com"
        echo "      后端 API: http://mathew.yunguhs.com/api"
    else
        echo "      前端: http://110.40.153.38:$FRONTEND_PORT"
        echo "      后端 API: http://110.40.153.38:$BACKEND_PORT/api"
    fi
else
    echo ""
    echo "⚠️  服务可能未完全启动，请检查日志："
    echo "   tail -f backend.log"
    echo "   tail -f frontend.log"
fi

echo ""
echo "📋 常用命令："
echo "   查看日志: tail -f backend.log"
echo "   查看日志: tail -f frontend.log"
echo "   停止服务: ./stop.sh"
echo "   检查状态: ./check.sh"
echo "=========================================="

