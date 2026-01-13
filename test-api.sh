#!/bin/bash

# API连接测试脚本

echo "=========================================="
echo "API连接测试"
echo "=========================================="

BACKEND_PORT=5010
DOMAIN="mathew.yunguhs.com"

echo "后端端口: $BACKEND_PORT"
echo "域名: $DOMAIN"
echo ""

# 1. 测试后端健康检查（本地）
echo "1. 测试后端本地连接"
echo "=========================================="
echo "测试: http://localhost:$BACKEND_PORT/healthz"
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:$BACKEND_PORT/healthz 2>/dev/null)
if [ "$HEALTH_STATUS" = "200" ]; then
    echo "✅ 后端本地连接成功 (HTTP $HEALTH_STATUS)"
    curl -s http://localhost:$BACKEND_PORT/healthz | head -1
else
    echo "❌ 后端本地连接失败 (HTTP $HEALTH_STATUS)"
fi

echo ""
echo "2. 测试后端API端点（本地）"
echo "=========================================="
echo "测试: http://localhost:$BACKEND_PORT/api/schools/"
API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:$BACKEND_PORT/api/schools/ 2>/dev/null)
if [ "$API_STATUS" = "401" ] || [ "$API_STATUS" = "200" ]; then
    echo "✅ API端点可访问 (HTTP $API_STATUS - 需要认证是正常的)"
else
    echo "❌ API端点访问失败 (HTTP $API_STATUS)"
fi

echo ""
echo "3. 测试域名API访问"
echo "=========================================="
echo "测试: http://$DOMAIN/api/healthz"
DOMAIN_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://$DOMAIN/api/healthz 2>/dev/null)
if [ "$DOMAIN_HEALTH" = "200" ]; then
    echo "✅ 域名API访问成功 (HTTP $DOMAIN_HEALTH)"
    curl -s http://$DOMAIN/api/healthz | head -1
else
    echo "❌ 域名API访问失败 (HTTP $DOMAIN_HEALTH)"
    echo "   可能原因：nginx未正确配置或后端未运行"
fi

echo ""
echo "4. 测试登录API端点"
echo "=========================================="
echo "测试: http://localhost:$BACKEND_PORT/api/login-user/"
LOGIN_TEST=$(curl -s -X POST http://localhost:$BACKEND_PORT/api/login-user/ \
    -H "Content-Type: application/json" \
    -d '{"username":"test","password":"test"}' \
    -o /dev/null -w "%{http_code}" --connect-timeout 5 2>/dev/null)
if [ "$LOGIN_TEST" = "400" ] || [ "$LOGIN_TEST" = "401" ]; then
    echo "✅ 登录API端点可访问 (HTTP $LOGIN_TEST - 认证失败是正常的)"
else
    echo "⚠️  登录API端点响应异常 (HTTP $LOGIN_TEST)"
fi

echo ""
echo "5. 检查后端日志（最近错误）"
echo "=========================================="
if [ -f "backend.log" ]; then
    echo "后端日志最后5行:"
    tail -n 5 backend.log | grep -i "error\|exception\|traceback" || echo "  无错误信息"
else
    echo "⚠️  未找到 backend.log"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果API无法访问，请检查:"
echo "1. 后端是否运行: ./check.sh"
echo "2. nginx配置是否正确（/api 转发到端口 $BACKEND_PORT）"
echo "3. 查看后端日志: tail -f backend.log"
echo ""

