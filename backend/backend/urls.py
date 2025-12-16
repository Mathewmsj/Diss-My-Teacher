from django.contrib import admin
from django.http import JsonResponse
from django.urls import path, include
from rest_framework.authtoken.views import obtain_auth_token


def healthz(_request):
    # 简单健康检查，返回 200
    return JsonResponse({"status": "ok"})


def root(_request):
    # 根路径返回说明，避免 404
    return JsonResponse({
        "message": "Diss My Teacher API",
        "docs": "/api/",
        "health": "/healthz"
    })


urlpatterns = [
    path('', root),
    path('admin/', admin.site.urls),
    path('api/token-auth/', obtain_auth_token),
    path('api/', include('api.urls')),
    path('healthz', healthz),  # Render 健康检查使用
]

