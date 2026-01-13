#!/bin/bash

# 测试后端API端点

echo "=========================================="
echo "测试后端API端点"
echo "=========================================="

BACKEND_URL="http://110.40.153.38:5009"

echo "后端地址: $BACKEND_URL"
echo ""

# 测试健康检查
echo "1. 测试健康检查 /healthz:"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/healthz" 2>&1
echo ""

# 测试API根路径
echo "2. 测试API根路径 /api/:"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/api/" 2>&1 | head -20
echo ""

# 测试登录端点（GET应该返回405 Method Not Allowed，而不是404）
echo "3. 测试 /api/login-user/ (GET请求):"
RESPONSE=$(curl -s -w "\nHTTP状态码: %{http_code}" "$BACKEND_URL/api/login-user/" 2>&1)
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | tail -1 | grep -o '[0-9]\{3\}')
if [ "$HTTP_CODE" = "404" ]; then
    echo "❌ 404错误：端点未找到"
elif [ "$HTTP_CODE" = "405" ]; then
    echo "✅ 405错误：端点存在但方法不允许（这是正常的，因为只支持POST）"
else
    echo "HTTP状态码: $HTTP_CODE"
fi
echo ""

# 测试管理员登录端点
echo "4. 测试 /api/admin-login/ (GET请求):"
RESPONSE=$(curl -s -w "\nHTTP状态码: %{http_code}" "$BACKEND_URL/api/admin-login/" 2>&1)
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | tail -1 | grep -o '[0-9]\{3\}')
if [ "$HTTP_CODE" = "404" ]; then
    echo "❌ 404错误：端点未找到"
elif [ "$HTTP_CODE" = "405" ]; then
    echo "✅ 405错误：端点存在但方法不允许（这是正常的，因为只支持POST）"
else
    echo "HTTP状态码: $HTTP_CODE"
fi
echo ""

# 测试POST请求（不带数据，应该返回400而不是404）
echo "5. 测试 /api/login-user/ (POST请求，无数据):"
RESPONSE=$(curl -s -X POST -w "\nHTTP状态码: %{http_code}" -H "Content-Type: application/json" "$BACKEND_URL/api/login-user/" 2>&1)
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | tail -1 | grep -o '[0-9]\{3\}')
if [ "$HTTP_CODE" = "404" ]; then
    echo "❌ 404错误：端点未找到"
elif [ "$HTTP_CODE" = "400" ]; then
    echo "✅ 400错误：端点存在但请求数据无效（这是正常的）"
else
    echo "HTTP状态码: $HTTP_CODE"
fi
echo ""

echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "如果返回404，可能的原因："
echo "1. 后端URL配置有问题"
echo "2. API路由未正确注册"
echo "3. 后端服务未正确启动"
echo ""

