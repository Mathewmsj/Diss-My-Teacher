#!/bin/bash

# 重启脚本 - 清理旧进程并重新启动

echo "=========================================="
echo "重启 Rate My Teacher 应用"
echo "=========================================="

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 停止所有相关进程
echo ""
echo "1. 停止现有服务..."
./stop.sh 2>/dev/null || true

# 清理所有可能的端口占用
echo ""
echo "2. 清理端口占用..."
for port in 5000 5009 5010 8806 8807; do
    if command -v lsof > /dev/null 2>&1; then
        PIDS=$(lsof -ti:$port 2>/dev/null)
        if [ ! -z "$PIDS" ]; then
            echo "清理端口 $port 的进程: $PIDS"
            echo "$PIDS" | xargs kill -9 2>/dev/null || true
        fi
    elif command -v fuser > /dev/null 2>&1; then
        fuser -k $port/tcp 2>/dev/null || true
    fi
done
sleep 2

# 清理进程ID文件
rm -f backend.pid frontend.pid

sleep 2

# 检查前端依赖
echo ""
echo "3. 检查前端依赖..."
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
fi

# 启动服务
echo ""
echo "4. 启动服务..."
./start.sh

echo ""
echo "=========================================="
echo "重启完成！"
echo "=========================================="
echo ""
echo "检查状态: ./check.sh"
echo ""

