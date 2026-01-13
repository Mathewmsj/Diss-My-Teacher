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
    # 优先使用环境变量，否则根据请求头自动检测
    frontend_url = os.getenv('FRONTEND_URL')
    
    if not frontend_url:
        # 自动检测：从请求头获取协议和主机
        scheme = _request.scheme  # http 或 https
        host = _request.get_host()  # 域名或IP:端口
        
        # 如果是域名访问，直接使用当前域名
        if 'yunguhs.com' in host or not host.startswith('110.40.153.38'):
            frontend_url = f"{scheme}://{host}"
        else:
            # IP访问时，使用默认端口5010
            if ':5009' in host or ':8806' in host:
                # 如果是后端端口，改为前端端口
                host = host.replace(':5009', ':5010').replace(':8806', ':8807')
            elif ':' not in host:
                # 如果没有端口，添加前端端口
                host = f"{host}:5010"
            frontend_url = f"{scheme}://{host}"
    
    return HttpResponseRedirect(frontend_url)


urlpatterns = [
    path('admin/', admin.site.urls),  # /admin 显示 Django 后台
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
    path('', root),  # 根路径重定向到前端（放在最后，避免覆盖其他路径）
]

