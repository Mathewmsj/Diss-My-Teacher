#!/bin/bash

# 创建测试用户脚本

echo "=========================================="
echo "创建测试用户"
echo "=========================================="

cd backend
source backend-env/bin/activate

echo ""
echo "1. 创建超级管理员"
echo "=========================================="
python create_superadmin.py

echo ""
echo "2. 创建测试普通用户"
echo "=========================================="
python << EOF
import django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from api.models import User, School

# 创建测试学校（如果不存在）
school, created = School.objects.get_or_create(
    school_code='TEST001',
    defaults={
        'school_name': '测试学校',
        'address': '测试地址'
    }
)
if created:
    print(f"✅ 创建学校: {school.school_name} ({school.school_code})")
else:
    print(f"✅ 学校已存在: {school.school_name} ({school.school_code})")

# 创建测试普通用户
if not User.objects.filter(username='testuser').exists():
    user = User.objects.create_user(
        username='testuser',
        email='test@example.com',
        password='test123456',
        is_active=True,
        is_approved=True,
        can_rate=True,
        approval_status='approved',
        school=school
    )
    print(f"✅ 创建测试用户: {user.username} (密码: test123456)")
else:
    print("⚠️  测试用户已存在")
    user = User.objects.get(username='testuser')
    user.set_password('test123456')
    user.is_active = True
    user.is_approved = True
    user.can_rate = True
    user.approval_status = 'approved'
    user.save()
    print(f"✅ 更新测试用户: {user.username} (密码: test123456)")

print("\n测试账号信息:")
print(f"  用户名: testuser")
print(f"  密码: test123456")
print(f"  邮箱: test@example.com")
EOF

cd ..

echo ""
echo "=========================================="
echo "✅ 用户创建完成！"
echo "=========================================="
echo ""
echo "现在可以使用以下账号登录:"
echo "  超级管理员:"
echo "    用户名: Starry"
echo "    密码: msj20070528"
echo ""
echo "  测试用户:"
echo "    用户名: testuser"
echo "    密码: test123456"
echo ""

