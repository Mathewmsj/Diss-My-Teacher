#!/bin/bash

# 登录问题诊断脚本

echo "=========================================="
echo "登录问题诊断"
echo "=========================================="

BACKEND_PORT=5010
DOMAIN="mathew.yunguhs.com"

echo "后端端口: $BACKEND_PORT"
echo "域名: $DOMAIN"
echo ""

# 1. 检查数据库表
echo "1. 检查数据库表"
echo "=========================================="
cd backend
source backend-env/bin/activate

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
required_tables = ['api_user', 'api_school', 'api_teacher', 'api_rating']
for table in required_tables:
    if table in tables:
        print(f"✅ {table} 表存在")
        # 检查表中有多少数据
        cursor.execute(f"SELECT COUNT(*) FROM {table};")
        count = cursor.fetchone()[0]
        print(f"   数据行数: {count}")
    else:
        print(f"❌ {table} 表不存在")
EOF

echo ""
echo "2. 检查用户数据"
echo "=========================================="
python << EOF
import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from api.models import User

try:
    user_count = User.objects.count()
    print(f"用户总数: {user_count}")
    
    if user_count > 0:
        print("\n前5个用户:")
        for user in User.objects.all()[:5]:
            print(f"  - {user.username} (ID: {user.id}, is_active: {user.is_active}, is_superuser: {user.is_superuser})")
    else:
        print("⚠️  数据库中没有用户，需要创建用户或从Render迁移数据")
except Exception as e:
    print(f"❌ 检查用户时出错: {e}")
EOF

echo ""
echo "3. 测试登录API端点"
echo "=========================================="
cd ..

# 测试登录端点
echo "测试: POST http://localhost:$BACKEND_PORT/api/login-user/"
RESPONSE=$(curl -s -X POST http://localhost:$BACKEND_PORT/api/login-user/ \
    -H "Content-Type: application/json" \
    -d '{"username":"test","password":"test"}' \
    -w "\nHTTP_STATUS:%{http_code}" 2>&1)

HTTP_STATUS=$(echo "$RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_STATUS")

echo "HTTP状态码: $HTTP_STATUS"
echo "响应内容:"
echo "$BODY" | head -5

if [ "$HTTP_STATUS" = "500" ]; then
    echo ""
    echo "❌ 服务器内部错误，检查后端日志"
elif [ "$HTTP_STATUS" = "400" ]; then
    echo ""
    echo "✅ API端点可访问（认证失败是正常的，说明API工作正常）"
elif [ "$HTTP_STATUS" = "401" ]; then
    echo ""
    echo "✅ API端点可访问（需要认证）"
fi

echo ""
echo "4. 测试域名API访问"
echo "=========================================="
echo "测试: POST http://$DOMAIN/api/login-user/"
DOMAIN_RESPONSE=$(curl -s -X POST http://$DOMAIN/api/login-user/ \
    -H "Content-Type: application/json" \
    -d '{"username":"test","password":"test"}' \
    -w "\nHTTP_STATUS:%{http_code}" 2>&1)

DOMAIN_STATUS=$(echo "$DOMAIN_RESPONSE" | grep "HTTP_STATUS" | cut -d: -f2)
DOMAIN_BODY=$(echo "$DOMAIN_RESPONSE" | grep -v "HTTP_STATUS")

echo "HTTP状态码: $DOMAIN_STATUS"
if [ "$DOMAIN_STATUS" = "200" ] || [ "$DOMAIN_STATUS" = "400" ] || [ "$DOMAIN_STATUS" = "401" ]; then
    echo "✅ 域名API访问正常"
else
    echo "❌ 域名API访问异常"
    echo "响应内容:"
    echo "$DOMAIN_BODY" | head -5
fi

echo ""
echo "5. 检查后端日志（最近错误）"
echo "=========================================="
if [ -f "backend.log" ]; then
    echo "后端日志最后10行（包含错误）:"
    tail -n 50 backend.log | grep -A 5 -B 5 -i "error\|exception\|traceback\|500" | tail -20 || echo "  无错误信息"
else
    echo "⚠️  未找到 backend.log"
fi

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果数据库表不存在，运行:"
echo "  ./fix-database.sh"
echo ""
echo "如果没有用户数据，需要:"
echo "  1. 从Render迁移数据: cd backend && ./migrate-simple.sh"
echo "  2. 或创建新用户: cd backend && python create_superadmin.py"
echo ""

