#!/bin/bash

# 测试API端点脚本

echo "=========================================="
echo "测试API端点"
echo "=========================================="

BACKEND_URL=${1:-"http://localhost:5009"}

echo "后端地址: $BACKEND_URL"
echo ""

# 测试健康检查
echo "1. 测试 /healthz:"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/healthz" 2>&1
echo ""

# 测试API根路径
echo "2. 测试 /api/ (根路径):"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/api/" 2>&1 | head -10
echo ""

# 测试登录端点（GET会返回405，这是正常的，因为只支持POST）
echo "3. 测试 /api/login-user/ (GET请求，应该返回405):"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/api/login-user/" 2>&1 | head -10
echo ""

# 测试管理员登录端点
echo "4. 测试 /api/admin-login/ (GET请求，应该返回405):"
curl -s -w "\nHTTP状态码: %{http_code}\n" "$BACKEND_URL/api/admin-login/" 2>&1 | head -10
echo ""

# 列出所有可用端点
echo "5. 检查可用端点:"
echo "访问 $BACKEND_URL/api/ 查看所有端点"
curl -s "$BACKEND_URL/api/" 2>&1 | head -20
echo ""

echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "如果返回404，可能的原因："
echo "1. 后端未正确启动"
echo "2. URL路径配置错误"
echo "3. 数据库迁移未完成"
echo ""

