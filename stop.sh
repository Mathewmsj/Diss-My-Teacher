#!/bin/bash

# 停止脚本 - Rate My Teacher 应用

echo "=========================================="
echo "停止 Rate My Teacher 应用"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 停止后端
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        kill $BACKEND_PID
        echo "后端服务已停止 (PID: $BACKEND_PID)"
    else
        echo "后端服务未运行"
    fi
    rm -f backend.pid
else
    echo "未找到 backend.pid 文件"
fi

# 停止前端
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        kill $FRONTEND_PID
        echo "前端服务已停止 (PID: $FRONTEND_PID)"
    else
        echo "前端服务未运行"
    fi
    rm -f frontend.pid
else
    echo "未找到 frontend.pid 文件"
fi

# 也尝试通过端口杀死进程（备用方案）
echo ""
echo "检查是否有残留进程..."

# 检查常见端口
for port in 5001 5002 5003 5004 5005 5006 5007 5008 5009 5010 8080 8081 8806 8807; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        echo "发现端口 $port 被进程 $PID 占用，正在停止..."
        kill $PID 2>/dev/null
    fi
done

echo ""
echo "=========================================="
echo "停止完成！"
echo "=========================================="

