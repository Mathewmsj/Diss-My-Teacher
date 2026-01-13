from django.contrib import admin
import os
from django.http import JsonResponse, HttpResponseRedirect
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token


def healthz(_request):
    # 简单健康检查，返回 200
    return JsonResponse({"status": "ok"})


def root(_request):
    # 根路径：如果访问的是后端，重定向到前端
    # 检测请求来源，如果是域名访问后端端口，重定向到前端
    host = _request.get_host()
    scheme = _request.scheme
    
    # 如果是域名访问（yunguhs.com），重定向到前端
    if 'yunguhs.com' in host:
        # 域名访问，重定向到前端（移除端口或改为8807）
        frontend_host = host.replace(':8806', ':8807').replace(':5009', ':5010')
        if ':8807' not in frontend_host and ':5010' not in frontend_host:
            # 如果没有端口，说明nginx已经处理了，直接重定向到根路径
            # 但为了避免循环，检查是否已经有端口
            frontend_url = f"{scheme}://{host}"
        else:
            frontend_url = f"{scheme}://{frontend_host}"
        
        # 使用302临时重定向，避免缓存问题
        return HttpResponseRedirect(frontend_url)
    
    # IP访问或其他情况，返回JSON
    return JsonResponse({
        "message": "Rate My Teacher API",
        "status": "running",
        "api_docs": "/api/",
        "admin": "/admin/",
        "frontend": f"{scheme}://{host.replace(':8806', ':8807').replace(':5009', ':5010')}" if ':' in host else f"{scheme}://{host}:5010"
    })


urlpatterns = [
    path('admin/', admin.site.urls),  # /admin 显示 Django 后台
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
    path('', root),  # 根路径重定向到前端（放在最后，避免覆盖其他路径）
]

