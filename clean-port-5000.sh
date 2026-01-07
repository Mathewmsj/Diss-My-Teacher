#!/bin/bash

# 清理端口5000占用的脚本

echo "=========================================="
echo "清理端口 5000 占用"
echo "=========================================="

# 查找占用5000端口的进程
if command -v lsof > /dev/null 2>&1; then
    PIDS=$(lsof -ti:5000 2>/dev/null)
    if [ ! -z "$PIDS" ]; then
        echo "找到占用端口 5000 的进程:"
        lsof -i:5000
        echo ""
        echo "终止这些进程..."
        echo "$PIDS" | xargs kill -9 2>/dev/null
        echo "✅ 已清理端口 5000"
    else
        echo "✅ 端口 5000 未被占用"
    fi
elif command -v fuser > /dev/null 2>&1; then
    if fuser 5000/tcp > /dev/null 2>&1; then
        echo "终止占用端口 5000 的进程..."
        fuser -k 5000/tcp 2>/dev/null
        echo "✅ 已清理端口 5000"
    else
        echo "✅ 端口 5000 未被占用"
    fi
else
    echo "⚠️  未找到 lsof 或 fuser 命令，无法自动清理"
    echo "请手动查找并终止占用端口 5000 的进程"
fi

sleep 1

echo ""
echo "=========================================="
echo "清理完成"
echo "=========================================="
echo ""
echo "现在可以重新启动服务:"
echo "  ./start.sh"
echo ""

