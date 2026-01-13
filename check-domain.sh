#!/bin/bash

# 域名访问诊断脚本

echo "=========================================="
echo "域名访问诊断"
echo "=========================================="

DOMAIN="mathew.yunguhs.com"
BACKEND_PORT=8806
FRONTEND_PORT=8807

echo "域名: $DOMAIN"
echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo ""

# 1. 检查服务是否运行
echo "1. 检查服务进程状态"
echo "=========================================="
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程运行中 (PID: $BACKEND_PID)"
    else
        echo "❌ 后端进程未运行"
    fi
else
    echo "⚠️  未找到 backend.pid"
fi

if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ 前端进程运行中 (PID: $FRONTEND_PID)"
    else
        echo "❌ 前端进程未运行"
    fi
else
    echo "⚠️  未找到 frontend.pid"
fi

echo ""
echo "2. 检查端口监听状态"
echo "=========================================="

# 检查后端端口
if netstat -tuln 2>/dev/null | grep -q ":$BACKEND_PORT " || ss -tuln 2>/dev/null | grep -q ":$BACKEND_PORT "; then
    LISTEN_INFO=$(netstat -tuln 2>/dev/null | grep ":$BACKEND_PORT " || ss -tuln 2>/dev/null | grep ":$BACKEND_PORT ")
    if echo "$LISTEN_INFO" | grep -q "0.0.0.0"; then
        echo "✅ 后端端口 $BACKEND_PORT 正在监听 (0.0.0.0 - 可外部访问)"
    elif echo "$LISTEN_INFO" | grep -q "127.0.0.1"; then
        echo "❌ 后端端口 $BACKEND_PORT 仅监听 127.0.0.1 (无法外部访问)"
    else
        echo "⚠️  后端端口 $BACKEND_PORT 正在监听"
    fi
    echo "$LISTEN_INFO"
else
    echo "❌ 后端端口 $BACKEND_PORT 未在监听"
fi

# 检查前端端口
if netstat -tuln 2>/dev/null | grep -q ":$FRONTEND_PORT " || ss -tuln 2>/dev/null | grep -q ":$FRONTEND_PORT "; then
    LISTEN_INFO=$(netstat -tuln 2>/dev/null | grep ":$FRONTEND_PORT " || ss -tuln 2>/dev/null | grep ":$FRONTEND_PORT ")
    if echo "$LISTEN_INFO" | grep -q "0.0.0.0"; then
        echo "✅ 前端端口 $FRONTEND_PORT 正在监听 (0.0.0.0 - 可外部访问)"
    elif echo "$LISTEN_INFO" | grep -q "127.0.0.1"; then
        echo "❌ 前端端口 $FRONTEND_PORT 仅监听 127.0.0.1 (无法外部访问)"
    else
        echo "⚠️  前端端口 $FRONTEND_PORT 正在监听"
    fi
    echo "$LISTEN_INFO"
else
    echo "❌ 前端端口 $FRONTEND_PORT 未在监听"
fi

echo ""
echo "3. 检查DNS解析"
echo "=========================================="
if command -v nslookup > /dev/null 2>&1; then
    DNS_RESULT=$(nslookup $DOMAIN 2>/dev/null | grep -A 1 "Name:" | tail -1 | awk '{print $2}')
    if [ ! -z "$DNS_RESULT" ]; then
        echo "✅ DNS解析: $DOMAIN -> $DNS_RESULT"
        if [ "$DNS_RESULT" = "110.40.153.38" ]; then
            echo "✅ DNS解析正确，指向服务器IP"
        else
            echo "⚠️  DNS解析指向: $DNS_RESULT (应该是 110.40.153.38)"
        fi
    else
        echo "❌ 无法解析域名 $DOMAIN"
    fi
elif command -v host > /dev/null 2>&1; then
    DNS_RESULT=$(host $DOMAIN 2>/dev/null | grep "has address" | awk '{print $4}')
    if [ ! -z "$DNS_RESULT" ]; then
        echo "✅ DNS解析: $DOMAIN -> $DNS_RESULT"
        if [ "$DNS_RESULT" = "110.40.153.38" ]; then
            echo "✅ DNS解析正确，指向服务器IP"
        else
            echo "⚠️  DNS解析指向: $DNS_RESULT (应该是 110.40.153.38)"
        fi
    else
        echo "❌ 无法解析域名 $DOMAIN"
    fi
else
    echo "⚠️  未找到 nslookup 或 host 命令"
fi

echo ""
echo "4. 检查本地连接"
echo "=========================================="

# 测试后端
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:$BACKEND_PORT/healthz > /dev/null 2>&1; then
    echo "✅ 后端本地连接成功 (http://localhost:$BACKEND_PORT)"
else
    echo "❌ 后端本地连接失败"
fi

# 测试前端
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:$FRONTEND_PORT > /dev/null 2>&1; then
    echo "✅ 前端本地连接成功 (http://localhost:$FRONTEND_PORT)"
else
    echo "❌ 前端本地连接失败"
fi

echo ""
echo "5. 检查nginx配置（如果可访问）"
echo "=========================================="
if [ -f "/etc/nginx/sites-enabled/$DOMAIN" ] || [ -f "/etc/nginx/conf.d/$DOMAIN.conf" ]; then
    echo "✅ 找到nginx配置文件"
    echo "检查配置..."
    if sudo nginx -t 2>/dev/null; then
        echo "✅ nginx配置语法正确"
    else
        echo "⚠️  nginx配置可能有错误"
    fi
else
    echo "ℹ️  未找到nginx配置文件（可能由管理员配置）"
fi

echo ""
echo "6. 测试外部访问"
echo "=========================================="
echo "测试后端API:"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" --connect-timeout 5 http://110.40.153.38:$BACKEND_PORT/healthz 2>/dev/null || echo "❌ 无法连接"

echo ""
echo "测试前端:"
curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" --connect-timeout 5 http://110.40.153.38:$FRONTEND_PORT 2>/dev/null || echo "❌ 无法连接"

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果服务未运行，请执行:"
echo "  ./start.sh 8806 8807"
echo ""
echo "如果端口未监听，请检查日志:"
echo "  tail -f backend.log"
echo "  tail -f frontend.log"
echo ""

