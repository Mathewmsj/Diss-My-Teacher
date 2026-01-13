import os
from pathlib import Path

import dj_database_url

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'change-me-in-prod'
DEBUG = True
ALLOWED_HOSTS = ['*']

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'api',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'backend.wsgi.application'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# 如果提供了 DATABASE_URL（例如 Render 上的 Postgres），优先使用它
db_url = os.getenv('DATABASE_URL')
if db_url:
    DATABASES['default'] = dj_database_url.parse(
        db_url,
        conn_max_age=600,
        ssl_require=True,
    )

# ========== 密码验证器配置 ==========
# 
# 功能说明：
# Django 在用户注册或修改密码时会自动运行这些验证器，
# 确保密码符合安全要求。这些验证器按顺序执行，如果任何一个失败，
# 密码设置操作将被拒绝。
#
# 验证器列表（按执行顺序）：
# 1. UserAttributeSimilarityValidator - 检查密码与用户属性（用户名、邮箱等）的相似度
# 2. MinimumLengthValidator - 检查密码最小长度（默认8位）
# 3. CommonPasswordValidator - 检查密码是否为常见弱密码
# 4. NumericPasswordValidator - 检查密码是否全为数字
#
# 注意：这些验证器只在用户注册和修改密码时生效，
#       登录时的密码验证使用 Django 的 authenticate() 函数。
AUTH_PASSWORD_VALIDATORS = [
    # 验证器1：用户属性相似度验证
    # 检查密码是否与用户名、邮箱等用户属性过于相似
    # 防止用户使用容易猜测的密码（如用户名+123）
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    
    # 验证器2：最小长度验证
    # 默认要求密码至少8个字符
    # 可以通过 OPTIONS 自定义最小长度，例如：{'OPTIONS': {'min_length': 6}}
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    
    # 验证器3：常见密码验证
    # 检查密码是否在常见弱密码列表中（如 "password", "12345678" 等）
    # Django 维护了一个包含约20000个常见密码的列表
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    
    # 验证器4：纯数字密码验证
    # 检查密码是否完全由数字组成（如 "12345678"）
    # 纯数字密码安全性较低，容易被暴力破解
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = 'Asia/Shanghai'
USE_I18N = True
USE_TZ = True

STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

AUTH_USER_MODEL = 'api.User'

# ========== Django REST Framework 配置 ==========
REST_FRAMEWORK = {
    # 身份验证类列表（按优先级顺序）
    # 当请求到达时，DRF 会依次尝试这些认证方式，直到找到有效的认证
    'DEFAULT_AUTHENTICATION_CLASSES': [
        # 1. SessionAuthentication - 基于会话的认证（用于Django admin等）
        #    使用Django的session框架，适合同域部署
        'rest_framework.authentication.SessionAuthentication',
        
        # 2. BasicAuthentication - HTTP基本认证
        #    使用用户名和密码的Base64编码，安全性较低，主要用于测试
        'rest_framework.authentication.BasicAuthentication',
        
        # 3. TokenAuthentication - 基于Token的认证（本项目主要使用）
        #    工作原理：
        #    - 客户端在请求头中携带：Authorization: Token <token_string>
        #    - DRF从请求头中提取Token
        #    - 在authtoken_token表中查找对应的Token
        #    - 如果找到，设置request.user为Token关联的用户
        #    - 如果未找到，返回401 Unauthorized
        #
        #    Token查找流程：
        #    1. 提取Authorization头中的Token值
        #    2. 执行SQL查询：SELECT * FROM authtoken_token WHERE key = '<token>'
        #    3. 如果找到，通过外键获取关联的User对象
        #    4. 设置request.user = token.user
        #
        #    安全特性：
        #    - Token是40字符的随机字符串，具有高熵值
        #    - Token存储在服务器端数据库，客户端无法篡改
        #    - 建议使用HTTPS传输，防止Token被截获
        'rest_framework.authentication.TokenAuthentication',
    ],
    
    # 默认权限类
    # 如果视图没有指定permission_classes，将使用此默认权限
    'DEFAULT_PERMISSION_CLASSES': [
        # IsAuthenticated - 要求用户必须已认证
        # 未认证的请求将返回401 Unauthorized
        'rest_framework.permissions.IsAuthenticated',
    ],
}

CORS_ALLOW_ALL_ORIGINS = True

# 日志配置 - 不记录敏感信息（用户名、邮箱等）
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': False,
        },
        'django.request': {
            'handlers': ['console'],
            'level': 'ERROR',  # 只记录错误，不记录请求详情（避免泄露用户名等）
            'propagate': False,
        },
    },
}

