#!/bin/bash

# 诊断脚本 - 检查服务状态和常见问题

echo "=========================================="
echo "服务诊断脚本"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 检查进程是否运行
echo ""
echo "1. 检查进程状态..."
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程正在运行 (PID: $BACKEND_PID)"
    else
        echo "❌ 后端进程未运行 (PID文件存在但进程不存在)"
    fi
else
    echo "⚠️  未找到 backend.pid 文件"
fi

if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ 前端进程正在运行 (PID: $FRONTEND_PID)"
    else
        echo "❌ 前端进程未运行 (PID文件存在但进程不存在)"
    fi
else
    echo "⚠️  未找到 frontend.pid 文件"
fi

# 2. 检查端口占用情况
echo ""
echo "2. 检查端口占用情况..."
for port in 5000 5001 5002 5003 5004 5005 5006 5007 5008 5009 5010; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
        echo "端口 $port: 被进程 $PID ($PROCESS) 占用"
    fi
done

# 3. 检查日志文件
echo ""
echo "3. 检查日志文件（最后10行）..."
if [ -f "backend.log" ]; then
    echo "--- 后端日志 (backend.log) ---"
    tail -10 backend.log
else
    echo "⚠️  未找到 backend.log 文件"
fi

echo ""
if [ -f "frontend.log" ]; then
    echo "--- 前端日志 (frontend.log) ---"
    tail -10 frontend.log
else
    echo "⚠️  未找到 frontend.log 文件"
fi

# 4. 检查依赖
echo ""
echo "4. 检查依赖..."
if [ -d "node_modules" ]; then
    echo "✅ node_modules 存在"
else
    echo "❌ node_modules 不存在，需要运行: npm install"
fi

if [ -d "backend/backend-env" ] || [ -d "backend-env" ]; then
    echo "✅ Python 虚拟环境存在"
else
    echo "⚠️  Python 虚拟环境不存在"
fi

# 5. 检查网络连接
echo ""
echo "5. 测试本地端口连接..."
for port in 5000 5001; do
    if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
        echo "✅ 端口 $port 可以连接"
    else
        echo "❌ 端口 $port 无法连接"
    fi
done

# 6. 检查防火墙（如果可能）
echo ""
echo "6. 检查常见问题..."
echo "提示: 如果端口无法连接，请检查："
echo "  - 服务是否正在运行"
echo "  - 端口是否在 5000-5010 范围内（防火墙允许的范围）"
echo "  - 应用是否监听 0.0.0.0（而不是 127.0.0.1）"

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "常用命令："
echo "  查看完整后端日志: tail -f backend.log"
echo "  查看完整前端日志: tail -f frontend.log"
echo "  重启服务: ./stop.sh && ./start.sh"
echo "  检查进程: ps aux | grep -E 'python|node'"
echo "=========================================="

