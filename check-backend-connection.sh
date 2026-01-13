#!/bin/bash

# 检查后端连接脚本

echo "=========================================="
echo "检查后端连接"
echo "=========================================="

# 检查后端进程
echo ""
echo "1. 检查后端进程:"
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程正在运行 (PID: $BACKEND_PID)"
        ps aux | grep $BACKEND_PID | grep -v grep
    else
        echo "❌ 后端进程已停止 (PID: $BACKEND_PID)"
    fi
else
    echo "⚠️  未找到 backend.pid 文件"
fi

# 检查端口监听
echo ""
echo "2. 检查端口5010监听:"
if netstat -tuln 2>/dev/null | grep -q ":5010 "; then
    echo "✅ 端口 5010 正在监听"
    netstat -tuln | grep ":5010 "
elif ss -tuln 2>/dev/null | grep -q ":5010 "; then
    echo "✅ 端口 5010 正在监听"
    ss -tuln | grep ":5010 "
else
    echo "❌ 端口 5010 未在监听"
fi

# 检查本地连接
echo ""
echo "3. 测试本地连接:"
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:5010/api/ > /dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:5010/api/)
    echo "✅ 本地连接成功 (HTTP $HTTP_CODE)"
else
    echo "❌ 本地连接失败"
fi

# 检查后端日志
echo ""
echo "4. 后端日志（最后10行）:"
if [ -f "backend.log" ]; then
    tail -n 10 backend.log
else
    echo "❌ 未找到 backend.log 文件"
fi

# 测试API端点
echo ""
echo "5. 测试API端点:"
echo "测试 /api/healthz:"
curl -s http://localhost:5010/healthz 2>/dev/null || echo "❌ 连接失败"
echo ""
echo "测试 /api/ (根路径):"
curl -s http://localhost:5010/api/ 2>/dev/null | head -c 200 || echo "❌ 连接失败"
echo ""

echo "=========================================="
echo "检查完成"
echo "=========================================="

