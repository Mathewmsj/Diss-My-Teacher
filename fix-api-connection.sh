#!/bin/bash

# 修复前端API连接问题

echo "=========================================="
echo "修复前端API连接"
echo "=========================================="

BACKEND_PORT=5010
DOMAIN="mathew.yunguhs.com"

echo "后端端口: $BACKEND_PORT"
echo "域名: $DOMAIN"
echo ""

# 测试后端连接
echo "1. 测试后端连接"
echo "=========================================="

# 测试本地连接
LOCAL_TEST=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:$BACKEND_PORT/healthz 2>/dev/null)
if [ "$LOCAL_TEST" = "200" ]; then
    echo "✅ 后端本地连接正常 (端口 $BACKEND_PORT)"
else
    echo "❌ 后端本地连接失败 (端口 $BACKEND_PORT)"
    echo "   请检查后端是否运行: ./check.sh"
    exit 1
fi

# 测试域名API
DOMAIN_TEST=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$DOMAIN/api/healthz 2>/dev/null)
if [ "$DOMAIN_TEST" = "200" ]; then
    echo "✅ 域名API连接正常"
    USE_DOMAIN=true
else
    echo "❌ 域名API连接失败 (HTTP $DOMAIN_TEST)"
    echo "   nginx可能未正确配置 /api 路径转发"
    USE_DOMAIN=false
fi

echo ""
echo "2. 检查前端API配置"
echo "=========================================="

# 检查前端API配置
if grep -q "yunguhs.com" src/api.js; then
    echo "✅ 前端已配置域名支持"
else
    echo "⚠️  前端可能未配置域名支持"
fi

echo ""
echo "3. 解决方案"
echo "=========================================="

if [ "$USE_DOMAIN" = "false" ]; then
    echo "由于nginx配置问题，建议使用IP直接访问后端："
    echo ""
    echo "方案1：修改前端API配置（临时方案）"
    echo "----------------------------------------"
    echo "编辑 src/api.js，将域名访问时的API地址改为："
    echo "  return 'http://110.40.153.38:$BACKEND_PORT/api';"
    echo ""
    echo "方案2：联系管理员修复nginx配置"
    echo "----------------------------------------"
    echo "nginx需要配置："
    echo "  location /api {"
    echo "      proxy_pass http://127.0.0.1:$BACKEND_PORT;"
    echo "  }"
    echo ""
    echo "方案3：使用IP访问前端（临时）"
    echo "----------------------------------------"
    echo "直接访问: http://110.40.153.38:8806"
    echo "前端会自动使用IP访问后端"
else
    echo "✅ 域名API连接正常，问题可能在浏览器端"
    echo "   请检查浏览器控制台（F12）的错误信息"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="

