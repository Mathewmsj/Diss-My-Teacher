#!/bin/bash

# 修复并启动脚本

echo "=========================================="
echo "修复并启动服务"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. 停止所有服务
echo ""
echo "1. 停止现有服务..."
./stop.sh 2>/dev/null || true

# 2. 彻底清理端口5000
echo ""
echo "2. 清理端口5000..."
# 使用多种方法清理
if command -v lsof > /dev/null 2>&1; then
    lsof -ti:5000 | xargs kill -9 2>/dev/null || true
fi
if command -v fuser > /dev/null 2>&1; then
    fuser -k 5000/tcp 2>/dev/null || true
fi
# 使用netstat查找并清理
if command -v netstat > /dev/null 2>&1; then
    netstat -tulnp 2>/dev/null | grep ":5000 " | awk '{print $7}' | cut -d'/' -f1 | xargs kill -9 2>/dev/null || true
fi
# 使用ss查找并清理
if command -v ss > /dev/null 2>&1; then
    ss -tulnp 2>/dev/null | grep ":5000 " | awk '{print $6}' | cut -d',' -f2 | cut -d'=' -f2 | xargs kill -9 2>/dev/null || true
fi

sleep 3

# 3. 运行数据库迁移
echo ""
echo "3. 运行数据库迁移..."
cd backend
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "❌ 未找到虚拟环境"
    exit 1
fi

source "$VENV_PATH/bin/activate"
echo "运行数据库迁移..."
python manage.py migrate --noinput

if [ $? -ne 0 ]; then
    echo "⚠️  数据库迁移有警告，但继续启动..."
fi

cd ..

# 4. 再次确认端口清理
echo ""
echo "4. 再次确认端口5000未被占用..."
if command -v lsof > /dev/null 2>&1; then
    if lsof -ti:5000 > /dev/null 2>&1; then
        echo "⚠️  端口5000仍被占用，强制清理..."
        lsof -ti:5000 | xargs kill -9 2>/dev/null || true
        sleep 2
    else
        echo "✅ 端口5000未被占用"
    fi
fi

# 5. 启动服务
echo ""
echo "5. 启动服务..."
./start.sh

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "检查状态: ./check.sh"
echo ""

