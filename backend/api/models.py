from django.conf import settings
from django.contrib.auth.models import AbstractUser
from django.db import models


class School(models.Model):
    school_code = models.CharField(max_length=32, primary_key=True)
    school_name = models.CharField(max_length=128)
    address = models.CharField(max_length=256, blank=True)
    daily_rating_limit = models.PositiveIntegerField(default=2)  # 保留用于兼容
    # 按等级分别限制
    daily_t1_limit = models.PositiveIntegerField(default=3)  # T1每日限制
    daily_t2_limit = models.PositiveIntegerField(default=2)  # T2每日限制
    daily_t3_limit = models.PositiveIntegerField(default=1)  # T3每日限制
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'{self.school_name} ({self.school_code})'


class Department(models.Model):
    department_id = models.AutoField(primary_key=True)
    department_name = models.CharField(max_length=128, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.department_name


class User(AbstractUser):
    """
    用户模型
    
    继承自 Django 的 AbstractUser，包含以下标准字段：
    - username: 用户名（必填，唯一）
    - email: 邮箱（可选）
    - password: 密码哈希（必填，使用PBKDF2算法加密）
    - is_active: 账户是否激活（用于禁用账户）
    - is_staff: 是否为管理员（用于访问Django admin）
    - is_superuser: 是否为超级管理员（拥有所有权限）
    - date_joined: 注册时间
    - last_login: 最后登录时间
    
    密码存储机制：
    Django 使用 PBKDF2 (Password-Based Key Derivation Function 2) 算法存储密码。
    
    密码哈希格式：
    <algorithm>$<iterations>$<salt>$<hash>
    例如：pbkdf2_sha256$260000$abc123$def456...
    
    安全特性：
    1. 单向哈希：无法从哈希值反推原始密码
    2. 盐值（Salt）：每个密码都有唯一的随机盐值，防止彩虹表攻击
    3. 迭代次数：默认260,000次迭代，增加暴力破解的计算成本
    4. 算法：PBKDF2 with SHA-256，是NIST推荐的标准算法
    
    密码验证流程（authenticate函数）：
    1. 从数据库获取用户的password字段（包含算法、迭代次数、盐值、哈希）
    2. 解析password字符串，提取算法、迭代次数、盐值
    3. 使用相同的算法和盐值对用户输入的密码进行哈希
    4. 比较计算出的哈希值与存储的哈希值
    5. 如果匹配，返回User对象；如果不匹配，返回None
    """
    
    # ========== 自定义字段 ==========
    
    # 学校外键：用户所属的学校
    # on_delete=models.SET_NULL: 如果学校被删除，用户的school字段设为NULL（不删除用户）
    # null=True, blank=True: 允许用户没有关联学校
    school = models.ForeignKey(School, on_delete=models.SET_NULL, null=True, blank=True)
    
    # ========== 审批状态常量 ==========
    # 用于控制新用户注册后的审批流程
    APPROVAL_PENDING = 'pending'      # 待审批：新注册用户默认状态
    APPROVAL_APPROVED = 'approved'    # 已批准：管理员审批通过后可以登录
    APPROVAL_REJECTED = 'rejected'    # 已拒绝：管理员拒绝后无法登录
    
    # 审批状态选项（用于Django admin下拉选择）
    APPROVAL_CHOICES = (
        (APPROVAL_PENDING, 'Pending'),
        (APPROVAL_APPROVED, 'Approved'),
        (APPROVAL_REJECTED, 'Rejected'),
    )

    # ========== 账户状态字段 ==========
    
    # 审批状态：控制用户是否可以登录
    # 登录验证时会检查此字段：
    # - APPROVAL_PENDING: 返回403 Forbidden，提示"账号待审批，登录受限"
    # - APPROVAL_REJECTED: 返回403 Forbidden，提示"账号已被拒绝，无法登录"
    # - APPROVAL_APPROVED: 允许继续验证密码
    approval_status = models.CharField(
        max_length=16, 
        choices=APPROVAL_CHOICES, 
        default=APPROVAL_PENDING
    )
    
    # 是否已批准（布尔字段，用于快速查询）
    # 与approval_status字段同步，approval_status='approved'时is_approved=True
    is_approved = models.BooleanField(default=False)
    
    # 是否可以评分：控制用户是否可以给教师评分
    # 管理员可以设置此字段来限制用户的评分权限
    can_rate = models.BooleanField(default=True)
    
    # 真实姓名：用户的真实姓名（可选，唯一）
    # 用于管理员识别用户，不用于登录
    real_name = models.CharField(
        max_length=128, 
        unique=True, 
        null=True, 
        blank=True, 
        verbose_name='真实姓名'
    )

    def __str__(self):
        return self.username
    
    # ========== 继承自AbstractUser的重要方法 ==========
    #
    # 以下方法由Django的AbstractUser提供，用于密码管理：
    #
    # 1. set_password(raw_password)
    #    功能：设置用户密码（自动哈希）
    #    流程：
    #    - 生成随机盐值（salt）
    #    - 使用PBKDF2算法对密码进行哈希（默认260,000次迭代）
    #    - 格式化为字符串：pbkdf2_sha256$260000$<salt>$<hash>
    #    - 存储到password字段
    #    使用场景：用户注册、修改密码
    #
    # 2. check_password(raw_password)
    #    功能：验证密码是否正确
    #    流程：
    #    - 从password字段提取算法、迭代次数、盐值
    #    - 使用相同的参数对输入的密码进行哈希
    #    - 比较哈希值是否匹配
    #    返回值：True（匹配）或False（不匹配）
    #    使用场景：修改密码时验证旧密码
    #
    # 3. has_usable_password()
    #    功能：检查用户是否有可用的密码
    #    返回：True（有密码）或False（密码为空或使用不可用的哈希算法）
    #
    # 4. is_authenticated（属性）
    #    功能：检查用户是否已认证
    #    对于真实用户，始终返回True
    #
    # 5. is_anonymous（属性）
    #    功能：检查用户是否为匿名用户
    #    对于真实用户，始终返回False


class Teacher(models.Model):
    teacher_id = models.AutoField(primary_key=True)
    name = models.CharField(max_length=128)
    department = models.ForeignKey(Department, on_delete=models.PROTECT, related_name='teachers')
    school = models.ForeignKey(School, on_delete=models.CASCADE, related_name='teachers', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Rating(models.Model):
    TIER_CHOICES = (
        ('T1', 'T1'),
        ('T2', 'T2'),
        ('T3', 'T3'),
    )

    rating_id = models.AutoField(primary_key=True)
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name='ratings')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='ratings')
    tier = models.CharField(max_length=2, choices=TIER_CHOICES)
    reason = models.TextField(max_length=200)
    likes = models.PositiveIntegerField(default=0)
    dislikes = models.PositiveIntegerField(default=0)
    is_featured = models.BooleanField(default=False, verbose_name='神评', help_text='管理员设置的优质评分，将自动置顶')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'teacher', 'created_at']),
        ]

    def __str__(self):
        return f'{self.teacher} - {self.tier}'


class UserVote(models.Model):
    """Record user votes per day for rate limiting."""
    TIER_CHOICES = (
        ('T1', 'T1'),
        ('T2', 'T2'),
        ('T3', 'T3'),
    )
    vote_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='votes')
    vote_date = models.DateField()
    teacher = models.ForeignKey(Teacher, on_delete=models.CASCADE, related_name='votes')
    tier = models.CharField(max_length=2, choices=TIER_CHOICES, default='T1')  # 记录评分的等级

    class Meta:
        unique_together = ('user', 'vote_date', 'teacher')
        indexes = [
            models.Index(fields=['user', 'vote_date']),
            models.Index(fields=['user', 'vote_date', 'tier']),
        ]

    def __str__(self):
        return f'{self.user} {self.vote_date} {self.teacher} {self.tier}'


class UserInteraction(models.Model):
    LIKE = 'like'
    DISLIKE = 'dislike'
    INTERACTION_CHOICES = (
        (LIKE, 'Like'),
        (DISLIKE, 'Dislike'),
    )

    interaction_id = models.AutoField(primary_key=True)
    rating = models.ForeignKey(Rating, on_delete=models.CASCADE, related_name='interactions')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='interactions')
    interaction_type = models.CharField(max_length=10, choices=INTERACTION_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'rating')
        indexes = [
            models.Index(fields=['user', 'rating']),
        ]

    def __str__(self):
        return f'{self.user} {self.interaction_type} {self.rating}'

