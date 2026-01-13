#!/bin/bash

# 检查nginx配置脚本

echo "=========================================="
echo "检查nginx配置"
echo "=========================================="

DOMAIN="mathew.yunguhs.com"
BACKEND_PORT=5010

echo "域名: $DOMAIN"
echo "后端端口: $BACKEND_PORT"
echo ""

# 检查nginx配置文件
echo "1. 查找nginx配置文件"
echo "=========================================="

NGINX_CONFIGS=(
    "/etc/nginx/sites-enabled/$DOMAIN"
    "/etc/nginx/sites-enabled/${DOMAIN%.*}"
    "/etc/nginx/conf.d/$DOMAIN.conf"
    "/etc/nginx/conf.d/${DOMAIN%.*}.conf"
    "/etc/nginx/nginx.conf"
)

FOUND_CONFIG=""
for config in "${NGINX_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ 找到配置文件: $config"
        FOUND_CONFIG="$config"
        break
    fi
done

if [ -z "$FOUND_CONFIG" ]; then
    echo "⚠️  未找到nginx配置文件（可能由管理员配置）"
    echo ""
    echo "nginx配置应该包含以下内容:"
    echo ""
    echo "server {"
    echo "    listen 80;"
    echo "    server_name $DOMAIN;"
    echo ""
    echo "    # 前端"
    echo "    location / {"
    echo "        proxy_pass http://127.0.0.1:8806;"
    echo "        proxy_set_header Host \$host;"
    echo "        proxy_set_header X-Real-IP \$remote_addr;"
    echo "    }"
    echo ""
    echo "    # 后端API"
    echo "    location /api {"
    echo "        proxy_pass http://127.0.0.1:$BACKEND_PORT;"
    echo "        proxy_set_header Host \$host;"
    echo "        proxy_set_header X-Real-IP \$remote_addr;"
    echo "    }"
    echo "}"
else
    echo ""
    echo "2. 检查配置文件内容"
    echo "=========================================="
    echo "配置文件内容:"
    echo ""
    sudo cat "$FOUND_CONFIG" 2>/dev/null || cat "$FOUND_CONFIG" 2>/dev/null || echo "无法读取配置文件（需要权限）"
fi

echo ""
echo "3. 测试nginx配置"
echo "=========================================="
if command -v nginx > /dev/null 2>&1; then
    if sudo nginx -t 2>/dev/null; then
        echo "✅ nginx配置语法正确"
    else
        echo "❌ nginx配置有错误"
        sudo nginx -t
    fi
else
    echo "⚠️  未找到nginx命令"
fi

echo ""
echo "4. 检查nginx服务状态"
echo "=========================================="
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "✅ nginx服务正在运行"
elif service nginx status > /dev/null 2>&1; then
    echo "✅ nginx服务正在运行"
else
    echo "⚠️  nginx服务状态未知"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果nginx配置有问题，需要联系管理员修复。"
echo "临时解决方案：直接使用IP访问后端"
echo "  前端: http://110.40.153.38:8806"
echo "  后端: http://110.40.153.38:$BACKEND_PORT"
echo ""

