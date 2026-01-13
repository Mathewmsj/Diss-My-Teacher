from django.contrib import admin
import os
from django.http import JsonResponse, HttpResponseRedirect
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token


def healthz(_request):
    # 简单健康检查，返回 200
    return JsonResponse({"status": "ok"})


def root(_request):
    # 根路径：返回简单的JSON响应，不重定向
    # 因为nginx已经将域名请求转发到前端，后端不需要重定向
    return JsonResponse({
        "message": "Rate My Teacher API",
        "status": "running",
        "api_docs": "/api/",
        "admin": "/admin/"
    })


urlpatterns = [
    path('admin/', admin.site.urls),  # /admin 显示 Django 后台
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
    path('', root),  # 根路径重定向到前端（放在最后，避免覆盖其他路径）
]

