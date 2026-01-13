#!/bin/bash

# 检查并修复防火墙配置

echo "=========================================="
echo "检查防火墙配置"
echo "=========================================="

BACKEND_PORT=8806
FRONTEND_PORT=5010

echo "后端端口: $BACKEND_PORT"
echo "前端端口: $FRONTEND_PORT"
echo ""

# 检查防火墙状态
if command -v firewall-cmd > /dev/null 2>&1; then
    if systemctl is-active --quiet firewalld; then
        echo "⚠️  firewalld 防火墙正在运行"
        echo ""
        echo "检查端口是否开放:"
        firewall-cmd --list-ports 2>/dev/null
        
        echo ""
        echo "如果需要开放端口，请运行（需要root权限）:"
        echo "  sudo firewall-cmd --add-port=$BACKEND_PORT/tcp --permanent"
        echo "  sudo firewall-cmd --add-port=$FRONTEND_PORT/tcp --permanent"
        echo "  sudo firewall-cmd --reload"
    else
        echo "✅ firewalld 防火墙未运行"
    fi
elif command -v ufw > /dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        echo "⚠️  ufw 防火墙正在运行"
        echo ""
        ufw status | head -10
        echo ""
        echo "如果需要开放端口，请运行（需要root权限）:"
        echo "  sudo ufw allow $BACKEND_PORT/tcp"
        echo "  sudo ufw allow $FRONTEND_PORT/tcp"
    else
        echo "✅ ufw 防火墙未运行"
    fi
else
    echo "ℹ️  未检测到常见防火墙工具"
fi

echo ""
echo "=========================================="
echo "检查云服务器安全组"
echo "=========================================="
echo "如果使用云服务器（如阿里云、腾讯云等），可能需要在控制台配置安全组规则："
echo "  - 开放端口 $BACKEND_PORT (TCP)"
echo "  - 开放端口 $FRONTEND_PORT (TCP)"
echo ""

