#!/bin/bash

# 诊断脚本 - 检查服务状态和访问问题
echo "=========================================="
echo "服务诊断脚本"
echo "=========================================="
echo ""

# 读取端口信息
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    echo "后端进程ID: $BACKEND_PID"
else
    echo "❌ 未找到 backend.pid 文件"
    BACKEND_PID=""
fi

if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    echo "前端进程ID: $FRONTEND_PID"
else
    echo "❌ 未找到 frontend.pid 文件"
    FRONTEND_PID=""
fi

echo ""
echo "=========================================="
echo "1. 检查进程状态"
echo "=========================================="

# 检查后端进程
if [ ! -z "$BACKEND_PID" ]; then
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 后端进程 (PID: $BACKEND_PID) 正在运行"
        ps aux | grep $BACKEND_PID | grep -v grep
    else
        echo "❌ 后端进程 (PID: $BACKEND_PID) 已停止"
    fi
else
    echo "⚠️  未找到后端进程ID"
fi

echo ""

# 检查前端进程
if [ ! -z "$FRONTEND_PID" ]; then
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ 前端进程 (PID: $FRONTEND_PID) 正在运行"
        ps aux | grep $FRONTEND_PID | grep -v grep
    else
        echo "❌ 前端进程 (PID: $FRONTEND_PID) 已停止"
    fi
else
    echo "⚠️  未找到前端进程ID"
fi

echo ""
echo "=========================================="
echo "2. 检查端口监听"
echo "=========================================="

# 检查5009端口（后端）
if netstat -tuln 2>/dev/null | grep -q ":5009 "; then
    echo "✅ 端口 5009 (后端) 正在监听"
    netstat -tuln | grep ":5009 "
elif ss -tuln 2>/dev/null | grep -q ":5009 "; then
    echo "✅ 端口 5009 (后端) 正在监听"
    ss -tuln | grep ":5009 "
else
    echo "❌ 端口 5009 (后端) 未在监听"
fi

# 检查5000端口（旧端口，可能还有残留）
if netstat -tuln 2>/dev/null | grep -q ":5000 "; then
    echo "⚠️  端口 5000 (旧后端) 仍在监听，可能需要清理"
    netstat -tuln | grep ":5000 "
elif ss -tuln 2>/dev/null | grep -q ":5000 "; then
    echo "⚠️  端口 5000 (旧后端) 仍在监听，可能需要清理"
    ss -tuln | grep ":5000 "
fi

# 检查5010端口（前端）
if netstat -tuln 2>/dev/null | grep -q ":5010 "; then
    echo "✅ 端口 5010 (前端) 正在监听"
    netstat -tuln | grep ":5010 "
elif ss -tuln 2>/dev/null | grep -q ":5010 "; then
    echo "✅ 端口 5010 (前端) 正在监听"
    ss -tuln | grep ":5010 "
else
    echo "❌ 端口 5010 (前端) 未在监听"
fi

echo ""
echo "=========================================="
echo "3. 检查最近日志"
echo "=========================================="

if [ -f "backend.log" ]; then
    echo "--- 后端日志（最后10行）---"
    tail -n 10 backend.log
    echo ""
else
    echo "❌ 未找到 backend.log 文件"
    echo ""
fi

if [ -f "frontend.log" ]; then
    echo "--- 前端日志（最后10行）---"
    tail -n 10 frontend.log
    echo ""
else
    echo "❌ 未找到 frontend.log 文件"
    echo ""
fi

echo "=========================================="
echo "4. 检查防火墙状态"
echo "=========================================="

# 检查防火墙状态
if command -v firewall-cmd > /dev/null 2>&1; then
    if systemctl is-active --quiet firewalld; then
        echo "⚠️  firewalld 防火墙正在运行"
        echo "检查端口是否开放:"
        firewall-cmd --list-ports 2>/dev/null || echo "无法检查防火墙端口"
    else
        echo "✅ firewalld 防火墙未运行"
    fi
elif command -v ufw > /dev/null 2>&1; then
    if ufw status | grep -q "Status: active"; then
        echo "⚠️  ufw 防火墙正在运行"
        ufw status | head -5
    else
        echo "✅ ufw 防火墙未运行"
    fi
else
    echo "ℹ️  未检测到常见防火墙工具"
fi

echo ""
echo "=========================================="
echo "5. 本地连接测试"
echo "=========================================="

# 测试本地连接
if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:5000 > /dev/null 2>&1; then
    echo "✅ 后端本地连接成功 (http://localhost:5000)"
else
    echo "❌ 后端本地连接失败 (http://localhost:5000)"
fi

if curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost:5010 > /dev/null 2>&1; then
    echo "✅ 前端本地连接成功 (http://localhost:5010)"
else
    echo "❌ 前端本地连接失败 (http://localhost:5010)"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果进程已停止，尝试重新启动:"
echo "  ./start.sh"
echo ""
echo "如果端口未监听，检查日志:"
echo "  tail -f backend.log"
echo "  tail -f frontend.log"
echo ""
echo "如果需要开放防火墙端口:"
echo "  sudo firewall-cmd --add-port=5000/tcp --permanent"
echo "  sudo firewall-cmd --add-port=5010/tcp --permanent"
echo "  sudo firewall-cmd --reload"
echo ""

