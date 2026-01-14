#!/bin/bash

# 本地开发启动脚本 - Rate My Teacher 应用
# 使用方法: ./start-local.sh [backend_port] [frontend_port]
# 示例: ./start-local.sh 8000 5173  (Django默认8000，Vite默认5173)

# 获取端口参数（如果未提供，使用默认值）
BACKEND_PORT=${1:-8000}
FRONTEND_PORT=${2:-5173}

echo "=========================================="
echo "Rate My Teacher 本地开发启动脚本"
echo "=========================================="
echo "后端端口: $BACKEND_PORT (http://localhost:$BACKEND_PORT)"
echo "前端端口: $FRONTEND_PORT (http://localhost:$FRONTEND_PORT)"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查是否在正确的目录
if [ ! -f "backend/manage.py" ]; then
    echo "❌ 错误: 找不到 backend/manage.py，请确保在项目根目录运行此脚本"
    exit 1
fi

# 清理端口占用（如果存在）
echo ""
echo "检查端口占用..."
if command -v lsof > /dev/null 2>&1; then
    lsof -ti:$BACKEND_PORT | xargs kill -9 2>/dev/null || true
    lsof -ti:$FRONTEND_PORT | xargs kill -9 2>/dev/null || true
elif command -v fuser > /dev/null 2>&1; then
    fuser -k $BACKEND_PORT/tcp 2>/dev/null || true
    fuser -k $FRONTEND_PORT/tcp 2>/dev/null || true
fi
sleep 1

# 1. 检查并设置后端虚拟环境
echo ""
echo "1. 检查后端环境..."
cd backend

if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "❌ 未找到虚拟环境 backend-env"
    echo "   创建虚拟环境: python3 -m venv backend-env"
    echo "   激活虚拟环境: source backend-env/bin/activate"
    echo "   安装依赖: pip install -r requirements.txt"
    exit 1
fi

if [ ! -f "$VENV_PATH/bin/python" ]; then
    echo "❌ 虚拟环境无效: $VENV_PATH"
    exit 1
fi

echo "✅ 虚拟环境: $VENV_PATH"

# 检查数据库迁移
echo ""
echo "2. 检查数据库迁移..."
"$VENV_PATH/bin/python" manage.py migrate --noinput

if [ $? -ne 0 ]; then
    echo "⚠️  数据库迁移有警告，但继续启动..."
fi

# 启动后端 (Django)
echo ""
echo "3. 启动后端服务 (Django)..."
echo "   后端地址: http://localhost:$BACKEND_PORT"
echo "   API地址: http://localhost:$BACKEND_PORT/api"

# 使用虚拟环境的 python 启动 Django 服务器（本地使用 127.0.0.1）
"$VENV_PATH/bin/python" manage.py runserver 127.0.0.1:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "✅ 后端已启动 (PID: $BACKEND_PID, 端口: $BACKEND_PORT)"
echo "   日志文件: backend.log"

# 等待后端启动
sleep 3
if ! ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo "❌ 后端进程启动失败！"
    echo "查看错误日志:"
    tail -n 20 ../backend.log
    exit 1
fi

# 回到项目根目录
cd ..

# 2. 检查前端依赖
echo ""
echo "4. 检查前端依赖..."
if [ ! -d "node_modules" ]; then
    echo "⚠️  未找到 node_modules，正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ npm install 失败"
        exit 1
    fi
fi

# 3. 启动前端 (Vite)
echo ""
echo "5. 启动前端服务 (Vite)..."
echo "   前端地址: http://localhost:$FRONTEND_PORT"

# 设置端口并启动 Vite 服务器
PORT=$FRONTEND_PORT npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!
echo "✅ 前端已启动 (PID: $FRONTEND_PID, 端口: $FRONTEND_PORT)"
echo "   日志文件: frontend.log"

# 等待前端启动
sleep 3
if ! ps -p $FRONTEND_PID > /dev/null 2>&1; then
    echo "❌ 前端进程启动失败！"
    echo "查看错误日志:"
    tail -n 20 frontend.log
    exit 1
fi

# 保存进程ID
echo $BACKEND_PID > backend.pid
echo $FRONTEND_PID > frontend.pid

echo ""
echo "=========================================="
echo "✅ 启动完成！"
echo "=========================================="
echo ""
echo "后端地址: http://localhost:$BACKEND_PORT"
echo "前端地址: http://localhost:$FRONTEND_PORT"
echo ""
echo "查看日志:"
echo "  tail -f backend.log    # 后端日志"
echo "  tail -f frontend.log   # 前端日志"
echo ""
echo "停止服务:"
echo "  ./stop-local.sh"
echo "  或: kill $BACKEND_PID $FRONTEND_PID"
echo ""
echo "=========================================="

