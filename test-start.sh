#!/bin/bash

# 测试启动脚本 - 在前台运行，可以看到详细输出

BACKEND_PORT=${1:-5007}
FRONTEND_PORT=${2:-5008}

echo "=========================================="
echo "测试启动脚本（前台运行，可以看到所有输出）"
echo "=========================================="
echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo ""
echo "注意：这个脚本会在前台运行，你可以看到所有输出"
echo "按 Ctrl+C 可以停止服务"
echo "=========================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 停止旧服务
echo "停止旧服务..."
./stop.sh 2>/dev/null || true
sleep 2

# 启动后端（在后台）
echo ""
echo "启动后端..."
cd backend

if [ -d "backend-env" ]; then
    source backend-env/bin/activate
elif [ -d "../backend-env" ]; then
    source ../backend-env/bin/activate
else
    echo "错误: 找不到虚拟环境，请先运行 ./deploy.sh"
    exit 1
fi

# 在后台启动后端
python3 manage.py runserver 0.0.0.0:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "后端已启动 (PID: $BACKEND_PID)"
echo "查看后端日志: tail -f backend.log"

cd ..

# 等待后端启动
sleep 3

# 启动前端（在前台，这样可以看到输出）
echo ""
echo "启动前端..."
echo "前端将在前台运行，你可以看到所有输出"
echo "按 Ctrl+C 停止前端（后端会继续运行）"
echo ""

VITE_API_BASE="http://110.40.153.38:$BACKEND_PORT/api" PORT=$FRONTEND_PORT npm run dev

