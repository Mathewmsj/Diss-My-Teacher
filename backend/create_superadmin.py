#!/usr/bin/env python
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from api.models import User

# 创建超级管理员（如果不存在）
username = 'Starry'
email = 'starry@example.com'
password = 'msj20070528'

if User.objects.filter(username=username).exists():
    print(f'超级管理员 {username} 已存在')
    user = User.objects.get(username=username)
    user.set_password(password)
    user.is_superuser = True
    user.is_staff = True
    user.is_active = True
    user.is_approved = True
    user.can_rate = True
    user.approval_status = 'approved'
    user.save()
    print(f'已更新超级管理员 {username} 的密码')
else:
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        is_superuser=True,
        is_staff=True,
        is_active=True,
        is_approved=True,
        can_rate=True,
        approval_status='approved'
    )
    print(f'超级管理员创建成功: {username}')
    print(f'密码: {password}')

print('\n登录信息:')
print(f'用户名: {username}')
print(f'密码: {password}')
print('\n请访问: http://localhost:8080/superadmin-login')
