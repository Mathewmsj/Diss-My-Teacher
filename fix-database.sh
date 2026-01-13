#!/bin/bash

# 修复数据库问题脚本

echo "=========================================="
echo "修复数据库问题"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "项目根目录: $SCRIPT_DIR"
echo ""

# 1. 停止服务
echo "1. 停止服务..."
./stop.sh 2>/dev/null || true
sleep 2

# 2. 进入backend目录
cd backend

# 3. 激活虚拟环境
if [ -d "backend-env" ]; then
    VENV_PATH="$(pwd)/backend-env"
elif [ -d "../backend-env" ]; then
    VENV_PATH="$(cd .. && pwd)/backend-env"
else
    echo "❌ 未找到虚拟环境"
    exit 1
fi

source "$VENV_PATH/bin/activate"

echo ""
echo "2. 检查数据库文件"
echo "=========================================="
if [ -f "db.sqlite3" ]; then
    echo "✅ 找到数据库文件: db.sqlite3"
    ls -lh db.sqlite3
else
    echo "ℹ️  数据库文件不存在，将创建新的数据库"
fi

echo ""
echo "3. 运行数据库迁移"
echo "=========================================="
python manage.py migrate

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 数据库迁移失败"
    echo "尝试修复迁移..."
    
    # 尝试回滚并重新迁移
    echo ""
    echo "检查迁移状态..."
    python manage.py showmigrations
    
    echo ""
    echo "如果迁移有问题，可以尝试："
    echo "  python manage.py migrate --fake-initial"
    exit 1
fi

echo ""
echo "4. 验证数据库表"
echo "=========================================="
python << EOF
import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = [row[0] for row in cursor.fetchall()]

print(f"数据库表数量: {len(tables)}")
if 'api_user' in tables:
    print("✅ api_user 表存在")
else:
    print("❌ api_user 表不存在")
    print("现有表:", ', '.join(tables))
EOF

echo ""
echo "5. 创建超级管理员（如果需要）"
echo "=========================================="
read -p "是否创建/更新超级管理员? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    python create_superadmin.py
fi

cd ..

echo ""
echo "=========================================="
echo "✅ 数据库修复完成！"
echo "=========================================="
echo ""
echo "现在可以重新启动服务:"
echo "  ./start.sh 5010 8806"
echo ""

