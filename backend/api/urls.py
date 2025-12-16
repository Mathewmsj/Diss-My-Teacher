from rest_framework.routers import DefaultRouter
from django.urls import path, include

from .views import (
    SchoolViewSet,
    DepartmentViewSet,
    TeacherViewSet,
    RatingViewSet,
    UserVoteViewSet,
    UserInteractionViewSet,
    UserViewSet,
    AdminLoginViewSet,
    SignupViewSet,
    LoginUserViewSet,
    SuperAdminLoginViewSet,
    SuperAdminViewSet,
)

router = DefaultRouter()
router.register(r'schools', SchoolViewSet)
router.register(r'departments', DepartmentViewSet)
router.register(r'teachers', TeacherViewSet)
router.register(r'ratings', RatingViewSet)
router.register(r'user-votes', UserVoteViewSet)
router.register(r'interactions', UserInteractionViewSet)
router.register(r'users', UserViewSet)
router.register(r'admin-login', AdminLoginViewSet, basename='admin-login')
router.register(r'signup', SignupViewSet, basename='signup')
router.register(r'login-user', LoginUserViewSet, basename='login-user')
router.register(r'superadmin-login', SuperAdminLoginViewSet, basename='superadmin-login')
router.register(r'superadmin', SuperAdminViewSet, basename='superadmin')

urlpatterns = [
    path('', include(router.urls)),
]

