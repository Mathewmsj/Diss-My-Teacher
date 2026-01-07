from django.contrib import admin
import os
from django.http import JsonResponse, HttpResponseRedirect
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token


def healthz(_request):
    # 简单健康检查，返回 200
    return JsonResponse({"status": "ok"})


def root(_request):
    # 根路径重定向到前端域名
    # 优先使用环境变量，否则根据请求的 Host 自动判断
    frontend_url = os.getenv('FRONTEND_URL')
    
    if not frontend_url:
        # 根据请求的 Host 自动判断前端地址
        host = _request.get_host()
        if 'mathew.yunguhs.com' in host:
            # 使用当前协议（http 或 https）
            scheme = 'https' if _request.is_secure() else 'http'
            frontend_url = f'{scheme}://mathew.yunguhs.com'
        elif 'yunguhs.com' in host:
            # 其他 yunguhs.com 子域名
            scheme = 'https' if _request.is_secure() else 'http'
            frontend_url = f'{scheme}://{host}'
        else:
            # 默认使用 Render 地址
            frontend_url = 'https://diss-my-teachers.onrender.com'
    
    return HttpResponseRedirect(frontend_url)


urlpatterns = [
    path('admin/', admin.site.urls),  # /admin 显示 Django 后台
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
    path('', root),  # 根路径重定向到前端（放在最后，避免覆盖其他路径）
]

