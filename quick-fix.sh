#!/bin/bash

# 快速修复脚本

echo "=========================================="
echo "快速修复脚本"
echo "=========================================="

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

BACKEND_PORT=5007
FRONTEND_PORT=5008

# 1. 停止所有相关进程
echo ""
echo "1. 停止所有相关进程..."
./stop.sh 2>/dev/null || true
pkill -f "python3 manage.py runserver" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
pkill -f "node.*vite" 2>/dev/null || true
sleep 2

# 2. 检查端口占用
echo ""
echo "2. 检查端口占用..."
for port in $BACKEND_PORT $FRONTEND_PORT; do
    PID=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$PID" ]; then
        echo "端口 $port 被进程 $PID 占用，正在停止..."
        kill -9 $PID 2>/dev/null || true
        sleep 1
    fi
done

# 3. 检查日志文件
echo ""
echo "3. 检查最近的错误日志..."
if [ -f "backend.log" ]; then
    echo "--- 后端日志最后10行 ---"
    tail -10 backend.log
fi
if [ -f "frontend.log" ]; then
    echo "--- 前端日志最后10行 ---"
    tail -10 frontend.log
fi

# 4. 检查依赖
echo ""
echo "4. 检查依赖..."
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
else
    echo "✅ 前端依赖已存在"
fi

# 检查并设置后端虚拟环境
cd backend
VENV_PATH=""
if [ -d "backend-env" ]; then
    VENV_PATH="backend-env"
    echo "✅ 找到虚拟环境: backend/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="../backend-env"
    echo "✅ 找到虚拟环境: backend-env (上级目录)"
else
    echo "创建后端虚拟环境..."
    python3 -m venv backend-env
    VENV_PATH="backend-env"
fi

# 激活虚拟环境
if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    echo "✅ 虚拟环境已激活"
    
    # 检查 Django 是否安装
    if ! python3 -c "import django" 2>/dev/null; then
        echo "Django 未安装，正在安装依赖..."
        pip install -q --upgrade pip
        pip install -q -r requirements.txt
    else
        echo "✅ Django 已安装"
        # 更新依赖以确保最新
        echo "更新依赖..."
        pip install -q --upgrade pip
        pip install -q -r requirements.txt
    fi
    
    # 执行数据库迁移
    echo "执行数据库迁移..."
    python3 manage.py migrate --noinput || echo "警告: 数据库迁移失败"
else
    echo "❌ 无法找到虚拟环境激活脚本"
    exit 1
fi

cd ..

# 5. 启动服务
echo ""
echo "5. 启动服务..."
chmod +x start.sh stop.sh 2>/dev/null || true

# 启动后端
echo "启动后端..."
cd backend

# 确保虚拟环境已激活
if [ -d "backend-env" ]; then
    source backend-env/bin/activate
elif [ -d "../backend-env" ]; then
    source ../backend-env/bin/activate
else
    echo "❌ 无法找到虚拟环境"
    exit 1
fi

# 验证 Django 是否可用
if ! python3 -c "import django" 2>/dev/null; then
    echo "❌ Django 未安装，正在安装..."
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
fi

# 先测试一下能否正常启动
echo "测试 Django 配置..."
python3 manage.py check || {
    echo "❌ Django 配置检查失败"
    echo "尝试重新安装依赖..."
    pip install -q --upgrade pip
    pip install -q -r requirements.txt
    python3 manage.py check || {
        echo "❌ Django 配置检查仍然失败"
        cd ..
        exit 1
    }
}

# 启动后端服务
nohup python3 manage.py runserver 0.0.0.0:$BACKEND_PORT > ../backend.log 2>&1 &
BACKEND_PID=$!
echo "后端已启动 (PID: $BACKEND_PID)"
echo $BACKEND_PID > ../backend.pid

cd ..

# 等待后端启动
sleep 3

# 检查后端是否真的启动了
if ps -p $BACKEND_PID > /dev/null 2>&1; then
    echo "✅ 后端进程正在运行"
else
    echo "❌ 后端进程启动失败，查看日志:"
    tail -20 backend.log
    exit 1
fi

# 启动前端
echo ""
echo "启动前端..."
VITE_API_BASE="http://110.40.153.38:$BACKEND_PORT/api" PORT=$FRONTEND_PORT nohup npm run dev > frontend.log 2>&1 &
FRONTEND_PID=$!
echo "前端已启动 (PID: $FRONTEND_PID)"
echo $FRONTEND_PID > frontend.pid

# 等待前端启动
sleep 5

# 检查前端是否真的启动了
if ps -p $FRONTEND_PID > /dev/null 2>&1; then
    echo "✅ 前端进程正在运行"
else
    echo "❌ 前端进程启动失败，查看日志:"
    tail -20 frontend.log
fi

# 6. 最终检查
echo ""
echo "6. 最终检查..."
sleep 2

echo ""
echo "进程状态:"
ps aux | grep -E "python.*manage.py.*$BACKEND_PORT|node.*vite.*$FRONTEND_PORT" | grep -v grep || echo "未找到进程"

echo ""
echo "端口监听状态:"
for port in $BACKEND_PORT $FRONTEND_PORT; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "✅ 端口 $port 正在监听"
    else
        echo "❌ 端口 $port 未监听"
    fi
done

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo "访问地址："
echo "  前端: http://110.40.153.38:$FRONTEND_PORT"
echo "  后端: http://110.40.153.38:$BACKEND_PORT/api"
echo ""
echo "如果还是无法访问，请查看日志："
echo "  tail -f backend.log"
echo "  tail -f frontend.log"
echo "=========================================="

