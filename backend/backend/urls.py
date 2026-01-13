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
    
    # 检查是否访问的是后端端口（8806或5009）
    is_backend_port = ':8806' in host or ':5009' in host
    
    # 如果是域名访问后端端口，重定向到前端
    if 'yunguhs.com' in host and is_backend_port:
        # 域名访问后端端口，重定向到前端端口
        frontend_host = host.replace(':8806', ':8807').replace(':5009', ':5010')
        frontend_url = f"{scheme}://{frontend_host}"
        return HttpResponseRedirect(frontend_url)
    elif 'yunguhs.com' in host and not is_backend_port:
        # 域名访问但没有端口（nginx已处理），返回HTML页面自动跳转
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta http-equiv="refresh" content="0; url={scheme}://{host}:8807">
            <title>Redirecting...</title>
        </head>
        <body>
            <p>正在跳转到前端页面...</p>
            <script>window.location.href = '{scheme}://{host}:8807';</script>
        </body>
        </html>
        """
        from django.http import HttpResponse
        return HttpResponse(html_content, content_type='text/html')
    
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

