#!/bin/bash

# 本地开发停止脚本

echo "=========================================="
echo "停止 Rate My Teacher 本地服务"
echo "=========================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 停止后端
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "停止后端 (PID: $BACKEND_PID)..."
        kill $BACKEND_PID 2>/dev/null
        sleep 1
        # 如果还在运行，强制杀死
        if ps -p $BACKEND_PID > /dev/null 2>&1; then
            kill -9 $BACKEND_PID 2>/dev/null
        fi
        echo "✅ 后端已停止"
    else
        echo "⚠️  后端进程不存在 (PID: $BACKEND_PID)"
    fi
    rm -f backend.pid
else
    echo "⚠️  未找到 backend.pid 文件"
fi

# 停止前端
if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "停止前端 (PID: $FRONTEND_PID)..."
        kill $FRONTEND_PID 2>/dev/null
        sleep 1
        # 如果还在运行，强制杀死
        if ps -p $FRONTEND_PID > /dev/null 2>&1; then
            kill -9 $FRONTEND_PID 2>/dev/null
        fi
        echo "✅ 前端已停止"
    else
        echo "⚠️  前端进程不存在 (PID: $FRONTEND_PID)"
    fi
    rm -f frontend.pid
else
    echo "⚠️  未找到 frontend.pid 文件"
fi

# 清理端口（可选，使用默认端口时）
echo ""
echo "清理端口..."
for port in 8000 5173; do
    if command -v lsof > /dev/null 2>&1; then
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
    fi
done

echo ""
echo "=========================================="
echo "✅ 所有服务已停止"
echo "=========================================="

