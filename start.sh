#!/bin/bash

# 启动脚本 - Rate My Teacher 应用
# 使用方法: ./start.sh [backend_port] [frontend_port]
# 示例: ./start.sh 5009 5010  (直接IP访问，端口范围5000-5010)
# 示例: ./start.sh 8806 8807  (域名访问，mathew的端口是8806)

# 获取端口参数（如果未提供，使用默认值）
BACKEND_PORT=${1:-5009}
FRONTEND_PORT=${2:-5010}

echo "=========================================="
echo "Rate My Teacher 启动脚本"
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

# 1. 启动后端 (Django)
echo ""
echo "正在启动后端服务..."
cd backend

# 检查虚拟环境
if [ -d "backend-env" ]; then
    source backend-env/bin/activate
    echo "已激活虚拟环境"
elif [ -d "../backend-env" ]; then
    source ../backend-env/bin/activate
    echo "已激活虚拟环境"
fi

# 使用 nohup 在后台启动 Django 服务器
# 重要: 必须使用 0.0.0.0 才能从外部访问
nohup python3 manage.py runserver 0.0.0.0:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "后端已启动 (PID: $BACKEND_PID, 端口: $BACKEND_PORT)"
echo "后端日志: backend.log"

# 回到项目根目录
cd ..

# 2. 启动前端 (Vite)
echo ""
echo "正在启动前端服务..."

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo "警告: 未找到 node_modules，请先运行 npm install"
fi

# 使用 nohup 在后台启动 Vite 服务器
# 注意: Vite 配置已经支持 PORT 环境变量，host 已设置为 0.0.0.0
# 设置前端 API 基础 URL，指向服务器后端
VITE_API_BASE="http://110.40.153.38:$BACKEND_PORT/api" PORT=$FRONTEND_PORT nohup npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!
echo "前端已启动 (PID: $FRONTEND_PID, 端口: $FRONTEND_PORT)"
echo "前端日志: frontend.log"

# 3. 保存进程ID到文件（用于后续停止服务）
echo $BACKEND_PID > backend.pid
echo $FRONTEND_PID > frontend.pid

echo ""
echo "=========================================="
echo "启动完成！"
echo "=========================================="
echo "后端地址: http://0.0.0.0:$BACKEND_PORT"
echo "前端地址: http://0.0.0.0:$FRONTEND_PORT"
echo ""
echo "从服务器外部访问:"
echo "后端: http://110.40.153.38:$BACKEND_PORT"
echo "前端: http://110.40.153.38:$FRONTEND_PORT"
echo ""
echo "查看日志:"
echo "  tail -f backend.log    # 后端日志"
echo "  tail -f frontend.log   # 前端日志"
echo ""
echo "停止服务:"
echo "  ./stop.sh              # 使用停止脚本"
echo "  或: kill $BACKEND_PID $FRONTEND_PID"
echo "=========================================="

