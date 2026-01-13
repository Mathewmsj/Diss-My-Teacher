#!/bin/bash

# 启动脚本 - Rate My Teacher 应用
# 使用方法: ./start.sh [backend_port] [frontend_port]
# 示例: ./start.sh 5010 5011  (直接IP访问，默认端口 - 后端5010，前端5011)
# 示例: ./start.sh 5010 8806  (域名访问：后端5010，前端8806，域名直接访问前端)

# 获取端口参数（如果未提供，使用默认值）
BACKEND_PORT=${1:-5010}
FRONTEND_PORT=${2:-5011}

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

# 1. 启动后端 (Django)
echo ""
echo "正在启动后端服务..."
cd backend

# 确定虚拟环境路径
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "错误: 未找到虚拟环境，请先创建虚拟环境并安装依赖"
    exit 1
fi

echo "虚拟环境路径: $VENV_PATH"

# 检查并安装依赖
if [ ! -f "$VENV_PATH/bin/python" ]; then
    echo "错误: 虚拟环境无效"
    exit 1
fi

# 使用虚拟环境的 python 在后台启动 Django 服务器
# 重要: 必须使用 0.0.0.0 才能从外部访问
# 先检查端口是否被占用
if command -v lsof > /dev/null 2>&1; then
    EXISTING_PID=$(lsof -ti:$BACKEND_PORT 2>/dev/null)
    if [ ! -z "$EXISTING_PID" ]; then
        echo "⚠️  端口 $BACKEND_PORT 被进程 $EXISTING_PID 占用，正在清理..."
        kill -9 $EXISTING_PID 2>/dev/null || true
        sleep 1
    fi
fi

nohup "$VENV_PATH/bin/python" manage.py runserver 0.0.0.0:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "后端已启动 (PID: $BACKEND_PID, 端口: $BACKEND_PORT)"
echo "后端日志: backend.log"

# 等待2秒检查进程是否还在运行
sleep 2
if ! ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo "❌ 后端进程启动后立即退出！"
    echo "查看错误日志:"
    tail -n 20 ../backend.log
    echo ""
    echo "请检查:"
    echo "1. 端口是否被占用: lsof -i:$BACKEND_PORT"
    echo "2. Django是否正确安装"
    echo "3. 数据库迁移是否完成: cd backend && python manage.py migrate"
fi

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
PORT=$FRONTEND_PORT nohup npm run dev > frontend.log 2>&1 &
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
if [ "$FRONTEND_PORT" = "8806" ]; then
    echo "域名访问（推荐）:"
    echo "前端: http://mathew.yunguhs.com 或 https://mathew.yunguhs.com"
    echo "后端 API: http://mathew.yunguhs.com/api 或 https://mathew.yunguhs.com/api"
    echo "  (nginx会将/api转发到后端端口 $BACKEND_PORT)"
    echo ""
    echo "IP访问（备用）:"
    echo "后端: http://110.40.153.38:$BACKEND_PORT"
    echo "前端: http://110.40.153.38:$FRONTEND_PORT"
else
    echo "IP访问:"
    echo "后端: http://110.40.153.38:$BACKEND_PORT"
    echo "前端: http://110.40.153.38:$FRONTEND_PORT"
    echo ""
    echo "提示: 使用域名访问请运行: ./start.sh 5010 8806"
fi
echo ""
echo "查看日志:"
echo "  tail -f backend.log    # 后端日志"
echo "  tail -f frontend.log   # 前端日志"
echo ""
echo "停止服务:"
echo "  ./stop.sh              # 使用停止脚本"
echo "  或: kill $BACKEND_PID $FRONTEND_PID"
echo "=========================================="

