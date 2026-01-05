#!/bin/bash

# 详细排查和修复脚本

echo "=========================================="
echo "详细排查脚本"
echo "=========================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 检查进程
echo ""
echo "1. 检查进程状态..."
echo "--- Python 进程 ---"
ps aux | grep -E "python.*manage.py|gunicorn" | grep -v grep || echo "未找到 Python 进程"
echo ""
echo "--- Node 进程 ---"
ps aux | grep -E "node.*vite|vite" | grep -v grep || echo "未找到 Node 进程"

# 2. 检查端口监听
echo ""
echo "2. 检查端口监听状态..."
for port in 5007 5008; do
    echo "--- 端口 $port ---"
    if command -v ss >/dev/null 2>&1; then
        ss -tlnp | grep ":$port " || echo "端口 $port 未被监听"
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp | grep ":$port " || echo "端口 $port 未被监听"
    else
        lsof -i :$port 2>/dev/null || echo "端口 $port 未被监听"
    fi
done

# 3. 检查日志文件
echo ""
echo "3. 检查日志文件..."
if [ -f "backend.log" ]; then
    echo "--- 后端日志最后20行 ---"
    tail -20 backend.log
    echo ""
    echo "--- 后端日志中的错误 ---"
    grep -i "error\|exception\|traceback\|failed" backend.log | tail -10 || echo "未找到错误信息"
else
    echo "⚠️  backend.log 不存在"
fi

echo ""
if [ -f "frontend.log" ]; then
    echo "--- 前端日志最后20行 ---"
    tail -20 frontend.log
    echo ""
    echo "--- 前端日志中的错误 ---"
    grep -i "error\|failed\|cannot\|eaddrinuse" frontend.log | tail -10 || echo "未找到错误信息"
else
    echo "⚠️  frontend.log 不存在"
fi

# 4. 检查依赖
echo ""
echo "4. 检查依赖..."
if [ -d "node_modules" ]; then
    echo "✅ node_modules 存在"
else
    echo "❌ node_modules 不存在"
fi

if [ -d "backend/backend-env" ] || [ -d "backend-env" ]; then
    echo "✅ Python 虚拟环境存在"
    if [ -d "backend/backend-env" ]; then
        if [ -f "backend/backend-env/bin/python" ]; then
            echo "✅ Python 可执行文件存在"
        else
            echo "❌ Python 可执行文件不存在"
        fi
    fi
else
    echo "❌ Python 虚拟环境不存在"
fi

# 5. 测试本地连接
echo ""
echo "5. 测试本地连接..."
for port in 5007 5008; do
    if timeout 2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null; then
        echo "✅ 端口 $port 可以连接"
        # 尝试 HTTP 请求
        if command -v curl >/dev/null 2>&1; then
            echo "   测试 HTTP 请求..."
            curl -s -o /dev/null -w "   HTTP 状态码: %{http_code}\n" --max-time 2 http://127.0.0.1:$port || echo "   HTTP 请求失败"
        fi
    else
        echo "❌ 端口 $port 无法连接"
    fi
done

# 6. 检查 PID 文件
echo ""
echo "6. 检查 PID 文件..."
if [ -f "backend.pid" ]; then
    BACKEND_PID=$(cat backend.pid)
    echo "backend.pid: $BACKEND_PID"
    if ps -p $BACKEND_PID > /dev/null 2>&1; then
        echo "✅ 进程 $BACKEND_PID 正在运行"
    else
        echo "❌ 进程 $BACKEND_PID 不存在"
    fi
else
    echo "⚠️  backend.pid 不存在"
fi

if [ -f "frontend.pid" ]; then
    FRONTEND_PID=$(cat frontend.pid)
    echo "frontend.pid: $FRONTEND_PID"
    if ps -p $FRONTEND_PID > /dev/null 2>&1; then
        echo "✅ 进程 $FRONTEND_PID 正在运行"
    else
        echo "❌ 进程 $FRONTEND_PID 不存在"
    fi
else
    echo "⚠️  frontend.pid 不存在"
fi

# 7. 建议修复步骤
echo ""
echo "=========================================="
echo "建议的修复步骤："
echo "=========================================="
echo ""
echo "如果服务未运行，请执行："
echo "  1. ./stop.sh                    # 停止所有服务"
echo "  2. 等待 3 秒"
echo "  3. ./deploy.sh 5007 5008        # 重新部署"
echo ""
echo "如果端口被占用，请执行："
echo "  lsof -i :5007                   # 查看占用端口的进程"
echo "  kill -9 <PID>                  # 停止占用进程"
echo ""
echo "如果依赖缺失，请执行："
echo "  npm install                    # 安装前端依赖"
echo "  cd backend"
echo "  python3 -m venv backend-env"
echo "  source backend-env/bin/activate"
echo "  pip install -r requirements.txt"
echo "  cd .."
echo ""
echo "手动测试启动（查看详细错误）："
echo "  # 后端（在前台运行，按 Ctrl+C 停止）"
echo "  cd backend"
echo "  source backend-env/bin/activate"
echo "  python3 manage.py runserver 0.0.0.0:5007"
echo ""
echo "  # 前端（在另一个终端，在前台运行）"
echo "  PORT=5008 VITE_API_BASE='http://110.40.153.38:5007/api' npm run dev"
echo ""
echo "=========================================="

