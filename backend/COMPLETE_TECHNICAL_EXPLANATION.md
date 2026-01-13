# 登录系统完整技术解释文档

本文档从功能、实现、原理三个维度全面解释登录系统的所有细节。

---

## 第一部分：功能说明

### 1.1 系统功能概述

本登录系统提供以下核心功能：

1. **用户身份验证**：验证用户名/邮箱和密码
2. **账户状态管理**：检查审批状态、激活状态
3. **权限控制**：区分普通用户、管理员、超级管理员
4. **Token管理**：生成、存储、验证身份令牌
5. **密码管理**：密码哈希、验证、修改

### 1.2 支持的登录方式

#### 方式1：普通用户登录
- **输入字段**：用户名或邮箱 + 密码
- **适用对象**：所有注册用户
- **权限范围**：查看教师、评分教师
- **特殊要求**：需要管理员审批（approval_status='approved'）

#### 方式2：管理员登录
- **输入字段**：学校代码 + 管理员账号 + 密码
- **适用对象**：is_staff=True的用户
- **权限范围**：管理自己学校的用户和教师
- **特殊要求**：学校代码必须匹配

#### 方式3：超级管理员登录
- **输入字段**：用户名 + 密码
- **适用对象**：is_superuser=True的用户
- **权限范围**：管理所有学校、用户、教师
- **特殊要求**：无额外要求

---

## 第二部分：实现方式

### 2.1 前端实现

#### 2.1.1 登录组件（Login.vue）

**文件位置**：`src/views/Login.vue`

**核心功能**：
1. 显示登录表单（用户/管理员切换）
2. 收集用户输入
3. 调用登录API
4. 存储Token和用户信息
5. 跳转到首页

**关键代码结构**：
```javascript
export default {
  data() {
    return {
      loading: false,        // 加载状态
      isAdmin: false,        // 登录类型
      form: {                // 表单数据
        identifier: '',      // 用户名/邮箱
        username: '',        // 管理员账号
        school_code: '',     // 学校代码
        password: ''         // 密码
      }
    }
  },
  methods: {
    onSubmit() {
      // 1. 表单验证
      // 2. 调用API
      // 3. 存储Token
      // 4. 跳转页面
    }
  }
}
```

#### 2.1.2 API客户端（api.js）

**文件位置**：`src/api.js`

**核心功能**：
1. 自动添加Token到请求头
2. 封装登录API调用
3. 统一错误处理

**Token自动添加机制**：
```javascript
// 每次请求前自动调用
function authHeaders() {
  const token = localStorage.getItem('authToken');
  return token ? { Authorization: `Token ${token}` } : {};
}

// 所有请求都自动包含Token
async function request(path, options = {}) {
  const headers = {
    ...authHeaders(),  // 自动添加
    ...options.headers
  };
  return fetch(`${API_BASE}${path}`, { headers, ...options });
}
```

### 2.2 后端实现

#### 2.2.1 登录视图（views.py）

**文件位置**：`backend/api/views.py`

**核心类**：
- `LoginUserViewSet`：普通用户登录
- `AdminLoginViewSet`：管理员登录
- `SuperAdminLoginViewSet`：超级管理员登录

**实现步骤**（以普通用户为例）：
```python
class LoginUserViewSet(viewsets.ViewSet):
    def create(self, request):
        # 步骤1：提取输入
        identifier = request.data.get('username') or request.data.get('email')
        password = request.data.get('password')
        
        # 步骤2：查找用户
        user = User.objects.get(username=identifier) or \
               User.objects.get(email=identifier)
        
        # 步骤3：验证密码
        auth_user = authenticate(request, username=user.username, password=password)
        
        # 步骤4：检查账户状态
        if auth_user.approval_status == User.APPROVAL_PENDING:
            return Response({'detail': '账号待审批'}, status=403)
        
        # 步骤5：生成Token
        token, _ = Token.objects.get_or_create(user=auth_user)
        
        # 步骤6：返回Token
        return Response({'token': token.key, 'user_id': auth_user.id})
```

#### 2.2.2 用户模型（models.py）

**文件位置**：`backend/api/models.py`

**模型结构**：
```python
class User(AbstractUser):
    # 继承字段
    username = CharField(...)      # 用户名
    email = EmailField(...)        # 邮箱
    password = CharField(...)      # 密码哈希
    is_active = BooleanField(...)  # 激活状态
    is_staff = BooleanField(...)   # 管理员
    is_superuser = BooleanField(...) # 超级管理员
    
    # 自定义字段
    school = ForeignKey(School)    # 所属学校
    approval_status = CharField(...) # 审批状态
    can_rate = BooleanField(...)   # 是否可以评分
    real_name = CharField(...)     # 真实姓名
```

**继承的方法**：
- `set_password(raw_password)`：设置密码（自动哈希）
- `check_password(raw_password)`：验证密码
- `has_usable_password()`：检查密码是否可用

#### 2.2.3 认证配置（settings.py）

**文件位置**：`backend/backend/settings.py`

**Token认证配置**：
```python
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
}
```

**密码验证器配置**：
```python
AUTH_PASSWORD_VALIDATORS = [
    # 4个验证器按顺序执行
    {'NAME': '...UserAttributeSimilarityValidator'},
    {'NAME': '...MinimumLengthValidator'},
    {'NAME': '...CommonPasswordValidator'},
    {'NAME': '...NumericPasswordValidator'},
]
```

---

## 第三部分：技术原理

### 3.1 密码哈希原理

#### 3.1.1 为什么需要哈希？

**问题场景**：
```
如果密码以明文存储：
用户A密码："password123" → 数据库存储："password123"
用户B密码："password123" → 数据库存储："password123"

数据库泄露后：
攻击者可以直接看到所有密码！
```

**解决方案**：
```
使用哈希函数：
用户A密码："password123" → 哈希 → "abc123def456..."
用户B密码："password123" → 哈希 → "xyz789uvw012..."

数据库泄露后：
攻击者只能看到哈希值，无法还原密码！
```

#### 3.1.2 PBKDF2算法详解

**PBKDF2** = Password-Based Key Derivation Function 2

**算法公式**：
```
DK = PBKDF2(Password, Salt, Iterations, KeyLength)

其中：
- Password: 用户输入的明文密码
- Salt: 随机盐值（每个密码唯一）
- Iterations: 迭代次数（默认260,000）
- KeyLength: 输出长度（32字节）
- DK: 派生密钥（最终的密码哈希）
```

**计算过程**（简化版）：
```
1. 初始化
   input = Password + Salt
   PRF = HMAC-SHA256

2. 第一次哈希
   H1 = PRF(input)

3. 迭代计算（260,000次）
   H2 = PRF(H1 + input)
   H3 = PRF(H2 + input)
   ...
   H260000 = PRF(H259999 + input)

4. 输出
   DK = H260000
```

**实际代码**（Django内部）：
```python
import hashlib

def pbkdf2_hash(password, salt, iterations=260000):
    """
    PBKDF2密码哈希
    """
    # 使用Python标准库
    dk = hashlib.pbkdf2_hmac(
        'sha256',              # 哈希算法
        password.encode('utf-8'),  # 密码（转为字节）
        salt.encode('utf-8'),      # 盐值（转为字节）
        iterations,                # 迭代次数
        32                         # 输出长度（32字节）
    )
    return dk
```

#### 3.1.3 盐值（Salt）的作用

**问题**：如果不用盐值
```
用户A密码："password123"
哈希值："abc123def456..."（固定）

用户B密码："password123"
哈希值："abc123def456..."（相同）

攻击者可以：
1. 预先计算常见密码的哈希值（彩虹表）
2. 对比数据库中的哈希值
3. 快速识别弱密码
```

**解决方案**：使用盐值
```
用户A密码："password123"，盐值："saltA"
哈希值："abc123def456..."（唯一）

用户B密码："password123"，盐值："saltB"
哈希值："xyz789uvw012..."（不同）

即使密码相同，哈希值也不同！
攻击者无法使用彩虹表攻击！
```

**盐值生成**：
```python
import os
import base64

# 生成16字节的随机盐值
salt_bytes = os.urandom(16)

# Base64编码为字符串
salt = base64.b64encode(salt_bytes).decode('ascii')
# 示例输出："abc123xyz789..."
```

#### 3.1.4 迭代次数的作用

**目的**：增加计算成本，减缓暴力破解

**效果对比**：
```
1次迭代：
- 计算时间：0.001毫秒
- 尝试1000个密码：1毫秒
- 暴力破解速度：极快

260,000次迭代：
- 计算时间：100-200毫秒
- 尝试1000个密码：100-200秒
- 暴力破解速度：极慢
```

**安全影响**：
- ✅ 正常登录：100-200毫秒（用户无感知）
- ✅ 暴力破解：成本极高（几乎不可行）
- ✅ 即使获得数据库，也无法快速破解密码

### 3.2 密码验证原理

#### 3.2.1 authenticate()函数详解

**函数位置**：`django.contrib.auth`

**完整流程**：

```
步骤1：接收参数
  authenticate(request, username='user123', password='pass123')
    ↓
步骤2：查找用户
  user = User.objects.get(username='user123')
    ↓
步骤3：提取密码哈希
  password_hash = user.password
  # 格式：pbkdf2_sha256$260000$abc123$def456...
    ↓
步骤4：解析哈希字符串
  parts = password_hash.split('$')
  algorithm = parts[0]      # "pbkdf2_sha256"
  iterations = int(parts[1]) # 260000
  salt = parts[2]           # "abc123"
  stored_hash = parts[3]    # "def456..."
    ↓
步骤5：对输入密码进行哈希
  computed_hash = PBKDF2(
      password='pass123',   # 用户输入的密码
      salt='abc123',        # 从数据库提取的盐值
      iterations=260000     # 从数据库提取的迭代次数
  )
  # 输出：computed_hash = "def456..."
    ↓
步骤6：比较哈希值
  if computed_hash == stored_hash:
      return user  # 密码正确
  else:
      return None  # 密码错误
```

**关键点**：
- ✅ 使用数据库中的盐值（不是新生成的）
- ✅ 使用相同的迭代次数
- ✅ 使用恒定时间比较（防止时序攻击）

#### 3.2.2 check_password()方法详解

**方法位置**：`User.check_password()`

**实现原理**（简化版）：
```python
def check_password(self, raw_password):
    """
    验证密码是否正确
    """
    # 1. 获取存储的密码哈希
    password_hash = self.password
    # 格式：pbkdf2_sha256$260000$salt$hash
    
    # 2. 解析哈希字符串
    algorithm, iterations, salt, stored_hash = password_hash.split('$')
    iterations = int(iterations)
    
    # 3. 对输入密码进行哈希
    computed_hash = pbkdf2_hmac(
        'sha256',
        raw_password.encode(),
        salt.encode(),
        iterations
    )
    computed_hash_str = base64.b64encode(computed_hash).decode()
    
    # 4. 恒定时间比较
    return constant_time_compare(computed_hash_str, stored_hash)
```

**恒定时间比较**：
```python
def constant_time_compare(val1, val2):
    """
    恒定时间字符串比较
    防止时序攻击
    """
    if len(val1) != len(val2):
        return False
    
    result = 0
    for x, y in zip(val1, val2):
        result |= ord(x) ^ ord(y)  # 异或运算
    
    return result == 0
```

**为什么需要恒定时间比较？**

**时序攻击**：
```
普通比较（==）：
  "abc" == "abc"  → 立即返回True（快速）
  "abc" == "abd"  → 比较3个字符后返回False（较慢）
  
攻击者可以通过响应时间判断：
- 响应快 → 密码可能正确
- 响应慢 → 密码可能错误
```

**恒定时间比较**：
```
无论密码是否正确，比较时间都相同
攻击者无法通过响应时间判断密码是否正确
```

### 3.3 Token认证原理

#### 3.3.1 Token生成原理

**生成时机**：用户登录成功后

**生成代码**：
```python
token, created = Token.objects.get_or_create(user=user)
```

**生成过程**（Django内部）：
```python
import secrets

def generate_token():
    """
    生成40字符的随机Token
    """
    # 生成20字节的随机数据
    random_bytes = secrets.token_bytes(20)
    
    # 转换为十六进制字符串（40字符）
    token_key = random_bytes.hex()
    # 示例：9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
    
    return token_key
```

**安全性分析**：
```
Token长度：40字符（十六进制）
可能的值：16^40 ≈ 1.46 × 10^48
暴力破解概率：几乎为零

即使每秒尝试10亿次：
需要时间：1.46 × 10^39 秒 ≈ 4.6 × 10^31 年
（宇宙年龄的10^21倍）
```

#### 3.3.2 Token验证原理

**验证时机**：每次API请求

**验证流程**：

```
请求到达
    ↓
DRF TokenAuthentication中间件
    ↓
步骤1：提取Token
  Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b
    ↓
步骤2：解析请求头
  auth_header = request.META.get('HTTP_AUTHORIZATION', '')
  # 值："Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
  
  if auth_header.startswith('Token '):
      token_key = auth_header[6:]  # 去掉"Token "前缀
      # token_key = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
    ↓
步骤3：查询数据库
  try:
      token = Token.objects.select_related('user').get(key=token_key)
  except Token.DoesNotExist:
      raise AuthenticationFailed('Invalid token')
    ↓
步骤4：设置用户对象
  request.user = token.user
    ↓
步骤5：继续处理请求
  视图函数可以访问request.user
```

**数据库查询**（SQL）：
```sql
-- Django ORM生成的SQL
SELECT 
    authtoken_token.key,
    authtoken_token.user_id,
    authtoken_token.created,
    api_user.id,
    api_user.username,
    api_user.email,
    api_user.is_active,
    api_user.is_staff,
    api_user.is_superuser,
    ...
FROM authtoken_token
INNER JOIN api_user ON authtoken_token.user_id = api_user.id
WHERE authtoken_token.key = '9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b'
LIMIT 1;
```

**性能优化**：
```python
# 使用select_related预加载用户对象
token = Token.objects.select_related('user').get(key=token_key)
# 只执行一次数据库查询（JOIN），而不是两次
```

### 3.4 账户状态检查原理

#### 3.4.1 审批状态检查

**字段**：`approval_status`

**状态值**：
- `'pending'`：待审批（新用户默认）
- `'approved'`：已批准（可以登录）
- `'rejected'`：已拒绝（不能登录）

**检查逻辑**：
```python
# 在LoginUserViewSet.create()中
if auth_user.approval_status == User.APPROVAL_PENDING:
    # 待审批用户不能登录
    return Response(
        {'detail': '账号待审批，登录受限'}, 
        status=status.HTTP_403_FORBIDDEN
    )

if auth_user.approval_status == User.APPROVAL_REJECTED:
    # 被拒绝用户不能登录
    return Response(
        {'detail': '账号已被拒绝，无法登录'}, 
        status=status.HTTP_403_FORBIDDEN
    )

# 只有approval_status='approved'的用户才能继续
```

**工作流程**：
```
用户注册
    ↓
approval_status = 'pending'
is_active = True
    ↓
用户尝试登录
    ↓
密码验证通过
    ↓
检查approval_status
    ↓
如果是'pending' → 返回403，提示"账号待审批"
如果是'rejected' → 返回403，提示"账号已被拒绝"
如果是'approved' → 继续，生成Token
```

#### 3.4.2 激活状态检查

**字段**：`is_active`（继承自AbstractUser）

**用途**：管理员可以禁用用户账户

**检查逻辑**：
```python
if not auth_user.is_active:
    return Response(
        {'detail': '账号已停用'}, 
        status=status.HTTP_403_FORBIDDEN
    )
```

**与approval_status的区别**：
```
approval_status = 'pending' + is_active = True
  → 不能登录（需要审批）

approval_status = 'approved' + is_active = False
  → 不能登录（账户被禁用）

approval_status = 'approved' + is_active = True
  → 可以登录
```

#### 3.4.3 权限检查

**管理员权限（is_staff）**：
```python
# 在AdminLoginViewSet.create()中
if not user.is_staff:
    return Response(
        {'detail': '认证失败'}, 
        status=status.HTTP_400_BAD_REQUEST
    )
```

**超级管理员权限（is_superuser）**：
```python
# 在SuperAdminLoginViewSet.create()中
if not user.is_superuser:
    return Response(
        {'detail': '认证失败：需要超级管理员权限'}, 
        status=status.HTTP_400_BAD_REQUEST
    )
```

---

## 第四部分：完整代码流程

### 4.1 普通用户登录完整流程

```
【前端：用户操作】
1. 用户在登录页面输入用户名/邮箱和密码
2. 点击"登录"按钮

【前端：表单验证】
3. Element Plus表单验证
   - 检查identifier是否填写
   - 检查password是否填写
   - 如果验证失败，显示错误信息，停止

【前端：发送请求】
4. 调用api.loginUser(identifier, password)
5. 构建请求：
   POST https://diss-my-teacher.onrender.com/api/login-user/
   Headers: {
     'Content-Type': 'application/json'
   }
   Body: {
     "username": "user123",
     "email": "user123",
     "password": "password123"
   }

【网络传输】
6. 请求通过HTTPS传输到服务器
7. 服务器接收请求

【后端：路由匹配】
8. Django URL路由匹配
   /api/login-user/ → LoginUserViewSet.create()

【后端：提取输入】
9. 从request.data提取数据
   identifier = "user123"
   password = "password123"

【后端：查找用户】
10. 执行数据库查询
    try:
        user = User.objects.get(username="user123")
    except User.DoesNotExist:
        user = User.objects.get(email="user123")
    
    SQL: SELECT * FROM api_user WHERE username = 'user123'

【后端：验证密码】
11. 调用authenticate()函数
    auth_user = authenticate(
        request,
        username=user.username,
        password="password123"
    )
    
    11.1 从数据库获取password字段
         password_hash = "pbkdf2_sha256$260000$abc123$def456..."
    
    11.2 解析哈希字符串
         algorithm = "pbkdf2_sha256"
         iterations = 260000
         salt = "abc123"
         stored_hash = "def456..."
    
    11.3 对输入密码进行哈希
         computed_hash = PBKDF2(
             password="password123",
             salt="abc123",
             iterations=260000
         )
         # 输出："def456..."
    
    11.4 比较哈希值
         if computed_hash == stored_hash:
             return user
         else:
             return None

【后端：检查账户状态】
12. 检查approval_status
    if auth_user.approval_status == 'pending':
        return 403 "账号待审批"
    
13. 检查is_active
    if not auth_user.is_active:
        return 403 "账号已停用"

【后端：生成Token】
14. 获取或创建Token
    token, created = Token.objects.get_or_create(user=auth_user)
    
    如果Token已存在：
        token = 现有Token对象
    如果Token不存在：
        生成新Token：token.key = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
        保存到数据库

【后端：返回响应】
15. 构建响应
    {
        "detail": "登录成功",
        "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
        "user_id": 123
    }

【网络传输】
16. 响应通过HTTPS返回前端

【前端：处理响应】
17. 接收响应数据
    res = {
        token: "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
        user_id: 123
    }

【前端：存储Token】
18. 存储到localStorage
    localStorage.setItem('authToken', res.token)
    localStorage.setItem('isAdmin', '0')  // 普通用户
    localStorage.removeItem('isSuperAdmin')
    localStorage.removeItem('adminSchoolCode')

【前端：显示消息】
19. 显示成功消息
    ElMessage.success('登录成功')

【前端：页面跳转】
20. 跳转到首页
    this.$router.push('/')
```

### 4.2 后续请求的Token验证流程

```
【前端：发送API请求】
1. 用户操作触发API请求
   例如：获取教师列表
   api.getTeachers()

【前端：自动添加Token】
2. request()函数自动调用authHeaders()
   const token = localStorage.getItem('authToken')
   // token = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
   
3. 构建请求头
   Headers: {
     'Content-Type': 'application/json',
     'Authorization': 'Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b'
   }

【网络传输】
4. 请求发送到服务器

【后端：DRF中间件】
5. TokenAuthentication中间件拦截请求
   
   5.1 提取Authorization头
       auth_header = "Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
   
   5.2 解析Token
       token_key = "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
   
   5.3 查询数据库
       token = Token.objects.select_related('user').get(key=token_key)
       
       SQL: 
       SELECT token.*, user.*
       FROM authtoken_token token
       INNER JOIN api_user user ON token.user_id = user.id
       WHERE token.key = '9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b'
   
   5.4 设置用户对象
       request.user = token.user

【后端：权限检查】
6. 检查视图的permission_classes
   例如：permission_classes = [IsAuthenticated]
   
   如果request.user是AnonymousUser：
       return 401 Unauthorized
   如果request.user是真实用户：
       继续处理请求

【后端：处理请求】
7. 视图函数执行
   def list(self, request):
       # request.user 已经是认证的用户对象
       teachers = Teacher.objects.all()
       return Response(serializer.data)

【后端：返回响应】
8. 返回数据
   {
       "teachers": [...]
   }

【前端：接收数据】
9. 处理响应数据
   更新页面显示
```

---

## 第五部分：安全机制详解

### 5.1 密码安全机制

#### 5.1.1 存储安全

**机制**：
```
明文密码 → PBKDF2哈希 → 存储到数据库

示例：
输入："password123"
输出："pbkdf2_sha256$260000$abc123$def456..."
存储：user.password = "pbkdf2_sha256$260000$abc123$def456..."
```

**安全特性**：
- ✅ 单向函数：无法从哈希值反推密码
- ✅ 盐值保护：每个密码有唯一盐值
- ✅ 迭代保护：260,000次迭代增加成本
- ✅ 算法标准：PBKDF2是NIST推荐算法

#### 5.1.2 传输安全

**机制**：
- ✅ HTTPS加密传输（生产环境）
- ✅ 密码在传输过程中加密
- ✅ 防止中间人攻击

**HTTPS工作原理**：
```
1. 客户端发送请求
2. 服务器返回SSL证书
3. 客户端验证证书
4. 建立加密连接（TLS）
5. 所有数据加密传输
```

#### 5.1.3 验证安全

**机制**：
- ✅ 恒定时间比较（防止时序攻击）
- ✅ 不明确错误信息（防止用户枚举）
- ✅ 密码验证器（确保复杂度）

### 5.2 Token安全机制

#### 5.2.1 生成安全

**机制**：
```python
# 使用加密安全的随机数生成器
token_key = secrets.token_hex(20)
# 生成40字符的随机十六进制字符串
```

**安全性**：
- ✅ 高熵值：16^40 种可能
- ✅ 随机性：使用加密安全的随机数
- ✅ 唯一性：每个用户一个Token

#### 5.2.2 存储安全

**前端存储**：
- ⚠️ localStorage（存在XSS风险）
- ✅ 建议：使用HttpOnly Cookie

**后端存储**：
- ✅ 数据库存储（服务器端）
- ✅ 客户端无法篡改
- ✅ 可以随时撤销

#### 5.2.3 传输安全

**机制**：
- ✅ HTTPS传输（生产环境）
- ✅ HTTP请求头传输（不在URL中）
- ✅ 防止CSRF攻击

### 5.3 账户安全机制

#### 5.3.1 审批机制

**目的**：防止恶意用户注册

**流程**：
```
注册 → 待审批 → 管理员审批 → 已批准 → 可以登录
```

#### 5.3.2 账户禁用

**机制**：
- 管理员可以设置`is_active=False`
- 被禁用用户无法登录
- 即使密码正确也无法登录

#### 5.3.3 权限隔离

**机制**：
- 普通用户：只能查看和评分
- 管理员：只能管理自己学校
- 超级管理员：可以管理所有内容

---

## 第六部分：关键技术细节

### 6.1 Django authenticate() 函数源码解析

**位置**：`django/contrib/auth/__init__.py`

**完整实现**（简化版）：
```python
def authenticate(request=None, **credentials):
    """
    Django身份验证函数
    """
    # 1. 获取所有认证后端
    backend = get_backends()[0]  # 默认使用ModelBackend
    
    # 2. 调用后端的authenticate方法
    user = backend.authenticate(request, **credentials)
    
    return user
```

**ModelBackend.authenticate()**（简化版）：
```python
class ModelBackend:
    def authenticate(self, request, username=None, password=None, **kwargs):
        # 1. 查找用户
        try:
            user = User.objects.get(username=username)
        except User.DoesNotExist:
            return None
        
        # 2. 检查密码
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None
    
    def user_can_authenticate(self, user):
        """检查用户是否可以认证"""
        return user.is_active
```

### 6.2 PBKDF2算法数学原理

**PBKDF2公式**：
```
DK = PBKDF2(PRF, Password, Salt, c, dkLen)

其中：
- PRF: 伪随机函数（HMAC-SHA256）
- Password: 密码
- Salt: 盐值
- c: 迭代次数（260,000）
- dkLen: 输出长度（32字节）
- DK: 派生密钥
```

**计算步骤**：
```
1. 计算需要的块数
   l = ceil(dkLen / hLen)
   # hLen = 32（SHA-256输出长度）
   # dkLen = 32
   # l = ceil(32/32) = 1

2. 对每个块i（从1到l）：
   U1 = PRF(Password, Salt || INT(i))
   U2 = PRF(Password, U1)
   U3 = PRF(Password, U2)
   ...
   Uc = PRF(Password, U(c-1))
   
   Ti = U1 XOR U2 XOR ... XOR Uc

3. 组合
   DK = T1 || T2 || ... || Tl
```

### 6.3 Token数据库查询优化

**优化前**（两次查询）：
```python
token = Token.objects.get(key=token_key)  # 查询1
user = token.user                          # 查询2（外键查询）
```

**优化后**（一次查询）：
```python
token = Token.objects.select_related('user').get(key=token_key)
user = token.user  # 已预加载，无需额外查询
```

**SQL对比**：
```sql
-- 优化前：两次查询
SELECT * FROM authtoken_token WHERE key = '...';  -- 查询1
SELECT * FROM api_user WHERE id = 123;            -- 查询2

-- 优化后：一次查询（JOIN）
SELECT token.*, user.*
FROM authtoken_token token
INNER JOIN api_user user ON token.user_id = user.id
WHERE token.key = '...';
```

---

## 第七部分：总结

### 7.1 系统特点

1. **安全性**：PBKDF2密码哈希、Token认证、多层安全检查
2. **灵活性**：支持多种登录方式、权限分级
3. **可扩展性**：前后端分离、RESTful API
4. **用户体验**：支持用户名/邮箱登录、自动Token管理

### 7.2 核心技术

- **密码哈希**：PBKDF2 with SHA-256, 260,000次迭代
- **身份认证**：Token-Based Authentication
- **权限控制**：基于角色的访问控制（RBAC）
- **账户管理**：审批机制 + 激活状态控制

### 7.3 安全特性

- ✅ 密码单向哈希（无法还原）
- ✅ 唯一盐值（防止彩虹表攻击）
- ✅ 多次迭代（减缓暴力破解）
- ✅ Token随机生成（高熵值）
- ✅ HTTPS传输（防止截获）
- ✅ 账户状态检查（多层防护）

---

**文档结束**
