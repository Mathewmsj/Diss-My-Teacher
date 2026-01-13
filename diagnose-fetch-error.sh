#!/bin/bash

# 诊断 "fail to fetch" 错误

echo "=========================================="
echo "诊断 'fail to fetch' 错误"
echo "=========================================="

# 1. 检查后端进程
echo ""
echo "1. 检查后端进程:"
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程正在运行 (PID: $BACKEND_PID)"
    else
        echo "❌ 后端进程已停止 (PID: $BACKEND_PID)"
    fi
else
    echo "⚠️  未找到 backend.pid 文件"
fi

# 2. 检查端口5009
echo ""
echo "2. 检查端口5009:"
if netstat -tuln 2>/dev/null | grep -q ":5009 "; then
    echo "✅ 端口 5009 正在监听"
    netstat -tuln | grep ":5009 "
elif ss -tuln 2>/dev/null | grep -q ":5009 "; then
    echo "✅ 端口 5009 正在监听"
    ss -tuln | grep ":5009 "
else
    echo "❌ 端口 5009 未在监听"
fi

# 3. 测试本地连接
echo ""
echo "3. 测试本地连接 (localhost:5009):"
if curl -s -o /dev/null -w "HTTP %{http_code}\n" --connect-timeout 3 http://localhost:5009/healthz 2>/dev/null; then
    echo "✅ 本地连接成功"
else
    echo "❌ 本地连接失败"
fi

# 4. 测试IP连接
echo ""
echo "4. 测试IP连接 (110.40.153.38:5009):"
if curl -s -o /dev/null -w "HTTP %{http_code}\n" --connect-timeout 3 http://110.40.153.38:5009/healthz 2>/dev/null; then
    echo "✅ IP连接成功"
else
    echo "❌ IP连接失败"
fi

# 5. 测试API端点
echo ""
echo "5. 测试API端点:"
echo "测试 /healthz:"
curl -s -w "\nHTTP状态码: %{http_code}\n" http://110.40.153.38:5009/healthz 2>&1 | head -5
echo ""

# 6. 检查后端日志
echo ""
echo "6. 后端日志（最后15行）:"
if [ -f "backend.log" ]; then
    tail -n 15 backend.log
else
    echo "❌ 未找到 backend.log 文件"
fi

# 7. 检查防火墙
echo ""
echo "7. 检查防火墙:"
if command -v firewall-cmd > /dev/null 2>&1; then
    if systemctl is-active --quiet firewalld; then
        echo "⚠️  firewalld 正在运行"
        echo "检查端口5009是否开放:"
        firewall-cmd --list-ports 2>/dev/null | grep 5009 || echo "端口5009未在防火墙规则中"
    else
        echo "✅ firewalld 未运行"
    fi
else
    echo "ℹ️  未检测到 firewalld"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果端口5009未监听，请检查:"
echo "1. 后端是否正在运行: ./check.sh"
echo "2. 查看后端日志: tail -f backend.log"
echo ""
echo "如果本地连接失败，请检查:"
echo "1. 后端是否正确启动"
echo "2. 端口是否被占用"
echo ""
echo "如果IP连接失败但本地连接成功，可能是防火墙问题"
echo ""

