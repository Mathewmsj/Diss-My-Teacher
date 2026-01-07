#!/bin/bash

# 清理端口占用脚本

echo "=========================================="
echo "清理端口占用"
echo "=========================================="

# 检查并清理5000端口
if lsof -ti:5000 > /dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":5000 "; then
    echo "发现端口 5000 被占用"
    echo "占用端口的进程:"
    lsof -i:5000 2>/dev/null || netstat -tulnp 2>/dev/null | grep ":5000 "
    echo ""
    read -p "是否终止占用端口 5000 的进程? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lsof -ti:5000 | xargs kill -9 2>/dev/null || true
        echo "✅ 已清理端口 5000"
    fi
else
    echo "✅ 端口 5000 未被占用"
fi

# 检查并清理5010端口
if lsof -ti:5010 > /dev/null 2>&1 || netstat -tuln 2>/dev/null | grep -q ":5010 "; then
    echo ""
    echo "发现端口 5010 被占用"
    echo "占用端口的进程:"
    lsof -i:5010 2>/dev/null || netstat -tulnp 2>/dev/null | grep ":5010 "
    echo ""
    read -p "是否终止占用端口 5010 的进程? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        lsof -ti:5010 | xargs kill -9 2>/dev/null || true
        echo "✅ 已清理端口 5010"
    fi
else
    echo "✅ 端口 5010 未被占用"
fi

echo ""
echo "=========================================="
echo "清理完成"
echo "=========================================="

