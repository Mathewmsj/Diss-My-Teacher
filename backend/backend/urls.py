from django.contrib import admin
import os
from django.http import JsonResponse, HttpResponseRedirect
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token


def healthz(_request):
    # 简单健康检查，返回 200
    return JsonResponse({"status": "ok"})


def root(_request):
    # 根路径：返回API信息
    # nginx配置：域名根路径(/) -> 前端8807，/api -> 后端5010
    # 如果直接访问后端根路径，返回API信息
    return JsonResponse({
        "message": "Rate My Teacher API",
        "status": "running",
        "api_docs": "/api/",
        "admin": "/admin/",
        "note": "访问前端请使用: http://mathew.yunguhs.com"
    })


urlpatterns = [
    path('admin/', admin.site.urls),  # /admin 显示 Django 后台
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
    path('', root),  # 根路径重定向到前端（放在最后，避免覆盖其他路径）
]

