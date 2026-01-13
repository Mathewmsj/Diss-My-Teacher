#!/bin/bash

# 强制清理端口5000的所有进程

echo "=========================================="
echo "强制清理端口 5000"
echo "=========================================="

# 使用多种方法查找并清理
echo "查找占用端口5000的进程..."

# 方法1: 使用lsof
if command -v lsof > /dev/null 2>&1; then
    PIDS=$(lsof -ti:5000 2>/dev/null)
    if [ ! -z "$PIDS" ]; then
        echo "找到进程: $PIDS"
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        echo "✅ 已清理"
    fi
fi

# 方法2: 使用netstat
if command -v netstat > /dev/null 2>&1; then
    PIDS=$(netstat -tulnp 2>/dev/null | grep ":5000 " | awk '{print $7}' | cut -d'/' -f1 | grep -v '-' | sort -u)
    if [ ! -z "$PIDS" ]; then
        echo "找到进程: $PIDS"
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        echo "✅ 已清理"
    fi
fi

# 方法3: 使用ss
if command -v ss > /dev/null 2>&1; then
    PIDS=$(ss -tulnp 2>/dev/null | grep ":5000 " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | sort -u)
    if [ ! -z "$PIDS" ]; then
        echo "找到进程: $PIDS"
        echo "$PIDS" | xargs kill -9 2>/dev/null || true
        echo "✅ 已清理"
    fi
fi

# 方法4: 查找所有python进程监听5000
ps aux | grep "[p]ython.*runserver.*5000" | awk '{print $2}' | xargs kill -9 2>/dev/null || true

sleep 2

# 验证
if command -v lsof > /dev/null 2>&1; then
    if lsof -ti:5000 > /dev/null 2>&1; then
        echo "⚠️  端口5000仍被占用"
        lsof -i:5000
    else
        echo "✅ 端口5000已清理"
    fi
fi

echo ""
echo "=========================================="
echo "清理完成"
echo "=========================================="

