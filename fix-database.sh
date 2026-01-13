#!/bin/bash

# 修复数据库迁移脚本

echo "=========================================="
echo "修复数据库迁移"
echo "=========================================="

# 获取项目根目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "项目根目录: $SCRIPT_DIR"

# 进入backend目录
cd backend

# 激活虚拟环境
if [ -d "backend-env" ]; then
    source backend-env/bin/activate
elif [ -d "../backend-env" ]; then
    source ../backend-env/bin/activate
else
    echo "❌ 未找到虚拟环境"
    exit 1
fi

echo ""
echo "步骤1: 检查数据库状态"
echo "=========================================="
python manage.py showmigrations --list 2>&1 | head -20

echo ""
echo "步骤2: 运行数据库迁移"
echo "=========================================="
python manage.py migrate --noinput

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 数据库迁移成功"
else
    echo ""
    echo "❌ 数据库迁移失败"
    echo "查看详细错误信息..."
    python manage.py migrate
    exit 1
fi

echo ""
echo "步骤3: 验证数据库表"
echo "=========================================="
python << EOF
import django
django.setup()
from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'api_%';")
tables = cursor.fetchall()
print(f"找到 {len(tables)} 个API表:")
for table in tables:
    print(f"  - {table[0]}")
EOF

echo ""
echo "步骤4: 检查是否需要创建超级管理员"
echo "=========================================="
python << EOF
import django
django.setup()
from api.models import User

if User.objects.filter(is_superuser=True).exists():
    print("✅ 超级管理员已存在")
else:
    print("⚠️  未找到超级管理员，运行创建脚本:")
    print("  python create_superadmin.py")
EOF

cd ..

echo ""
echo "=========================================="
echo "数据库修复完成！"
echo "=========================================="
echo ""
echo "如果服务正在运行，建议重启:"
echo "  ./stop.sh"
echo "  ./start.sh 5010 8806"
echo ""

