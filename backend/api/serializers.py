from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import School, Department, Teacher, Rating, UserVote, UserInteraction


class SchoolSerializer(serializers.ModelSerializer):
    class Meta:
        model = School
        fields = '__all__'


class DepartmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = '__all__'


class TeacherSerializer(serializers.ModelSerializer):
    department_name = serializers.CharField(source='department.department_name', read_only=True)
    school_code = serializers.CharField(source='school.school_code', read_only=True)

    class Meta:
        model = Teacher
        fields = ['teacher_id', 'name', 'department', 'department_name', 'school', 'school_code', 'created_at']




class RatingSerializer(serializers.ModelSerializer):
    """评分序列化器 - 不包含任何用户名等敏感信息，只返回匿名ID"""
    teacher_name = serializers.CharField(source='teacher.name', read_only=True)
    masked_user_id = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Rating
        fields = [
            'rating_id', 'teacher', 'teacher_name', 'masked_user_id',
            'tier', 'reason', 'likes', 'dislikes', 'is_featured', 'created_at', 'updated_at'
        ]
        read_only_fields = ['likes', 'dislikes', 'is_featured', 'created_at', 'updated_at']

    def get_masked_user_id(self, obj):
        """返回匿名用户ID，不暴露真实用户信息"""
        return f'anon-{obj.user_id}'


class UserVoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserVote
        fields = '__all__'


class UserInteractionSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserInteraction
        fields = '__all__'


class UserSerializer(serializers.ModelSerializer):
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    school_code = serializers.CharField(source='school.school_code', read_only=True)
    
    class Meta:
        model = get_user_model()
        fields = ['id', 'username', 'email', 'school', 'school_name', 'school_code', 
                  'is_approved', 'can_rate', 'approval_status', 'is_staff', 'is_superuser', 
                  'is_active', 'date_joined', 'last_login']


class SuperAdminUserSerializer(serializers.ModelSerializer):
    """超级管理员专用：显示用户的真实姓名"""
    school_name = serializers.CharField(source='school.school_name', read_only=True)
    school_code = serializers.CharField(source='school.school_code', read_only=True)
    
    class Meta:
        model = get_user_model()
        fields = ['id', 'username', 'email', 'real_name', 'school', 'school_name', 'school_code', 
                  'is_approved', 'can_rate', 'approval_status', 'is_staff', 'is_superuser', 
                  'is_active', 'date_joined', 'last_login']


class SuperAdminRatingSerializer(serializers.ModelSerializer):
    """超级管理员专用：显示完整的评分信息，包括用户详情"""
    user_name = serializers.CharField(source='user.username', read_only=True)
    user_email = serializers.CharField(source='user.email', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    user_real_name = serializers.CharField(source='user.real_name', read_only=True)
    teacher_name = serializers.CharField(source='teacher.name', read_only=True)
    teacher_id = serializers.IntegerField(source='teacher.teacher_id', read_only=True)
    school_name = serializers.CharField(source='teacher.school.school_name', read_only=True)
    school_code = serializers.CharField(source='teacher.school.school_code', read_only=True)
    
    # 点赞/点踩用户列表
    liked_users = serializers.SerializerMethodField()
    disliked_users = serializers.SerializerMethodField()
    
    class Meta:
        model = Rating
        fields = [
            'rating_id', 'teacher', 'teacher_id', 'teacher_name', 
            'user', 'user_id', 'user_name', 'user_email', 'user_real_name',
            'school_name', 'school_code',
            'tier', 'reason', 'likes', 'dislikes', 'is_featured',
            'liked_users', 'disliked_users',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['likes', 'dislikes', 'created_at', 'updated_at', 'user']
    
    def get_liked_users(self, obj):
        """获取所有点赞的用户"""
        interactions = UserInteraction.objects.filter(
            rating=obj, 
            interaction_type=UserInteraction.LIKE
        ).select_related('user')
        return [
            {
                'id': i.user.id,
                'username': i.user.username,
                'email': i.user.email,
                'created_at': i.created_at
            }
            for i in interactions
        ]
    
    def get_disliked_users(self, obj):
        """获取所有点踩的用户"""
        interactions = UserInteraction.objects.filter(
            rating=obj, 
            interaction_type=UserInteraction.DISLIKE
        ).select_related('user')
        return [
            {
                'id': i.user.id,
                'username': i.user.username,
                'email': i.user.email,
                'created_at': i.created_at
            }
            for i in interactions
        ]


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    school_code = serializers.CharField(write_only=True, required=True, allow_blank=False)
    real_name = serializers.CharField(required=True, max_length=128, allow_blank=False)

    class Meta:
        model = get_user_model()
        fields = ['username', 'email', 'password', 'school_code', 'real_name']

    def validate_username(self, value):
        if get_user_model().objects.filter(username=value).exists():
            raise serializers.ValidationError('用户名已存在')
        return value

    def validate_email(self, value):
        if get_user_model().objects.filter(email=value).exists():
            raise serializers.ValidationError('邮箱已存在')
        return value

    def validate_real_name(self, value):
        if not value or not value.strip():
            raise serializers.ValidationError('真实姓名不能为空')
        if get_user_model().objects.filter(real_name=value.strip()).exists():
            raise serializers.ValidationError('真实姓名已被使用，请使用其他姓名')
        return value.strip()

    def create(self, validated_data):
        """
        创建新用户
        
        功能说明：
        处理用户注册请求，创建新用户账户。密码会自动进行哈希处理。
        
        流程：
        1. 提取和验证学校代码
        2. 提取密码和真实姓名
        3. 查找学校（必须已存在）
        4. 创建用户对象
        5. 设置密码（自动哈希）
        6. 保存到数据库
        
        账户初始状态：
        - approval_status: 'pending'（待审批）
        - is_approved: False
        - is_active: True（账户激活，但需要审批才能登录）
        - can_rate: True（可以评分）
        """
        # ========== 步骤1：提取和验证学校代码 ==========
        
        # 从验证后的数据中提取学校代码
        # pop()方法会从字典中删除该键，防止被传递到用户创建
        school_code = validated_data.pop('school_code', '').strip()
        
        # 验证学校代码是否提供
        if not school_code:
            raise serializers.ValidationError({'school_code': '学校代码必填'})
        
        # ========== 步骤2：提取密码和真实姓名 ==========
        
        # 提取密码（明文）
        # 密码必须以明文形式提取，因为需要对其进行哈希处理
        # pop()确保密码不会被传递到用户创建的其他字段
        password = validated_data.pop('password')
        
        # 提取真实姓名
        real_name = validated_data.pop('real_name', '').strip()
        if not real_name:
            raise serializers.ValidationError({'real_name': '真实姓名不能为空'})
        
        # ========== 步骤3：查找学校（必须已存在） ==========
        
        # 学校代码必须已存在，不允许自动创建新学校
        # 这确保只有管理员创建学校，防止用户随意创建学校
        try:
            school = School.objects.get(school_code=school_code)
        except School.DoesNotExist:
            raise serializers.ValidationError({
                'school_code': f'学校代码 "{school_code}" 不存在，请联系管理员'
            })
        
        # ========== 步骤4：创建用户对象 ==========
        
        # 使用验证后的数据创建用户对象
        # 此时validated_data中不包含password、school_code、real_name（已被pop）
        # 包含：username, email等字段
        user = get_user_model().objects.create(
            **validated_data,  # 展开剩余字段（username, email等）
            real_name=real_name,  # 真实姓名
            school=school,  # 关联的学校对象
            
            # ========== 账户初始状态设置 ==========
            
            # 审批状态：新用户默认为待审批
            # 待审批的用户无法登录，需要管理员审批后才能使用
            is_approved=False,
            
            # 审批状态字符串：与is_approved字段对应
            approval_status=getattr(get_user_model(), 'APPROVAL_PENDING', 'pending'),
            
            # 是否可以评分：新用户默认可以评分
            # 管理员可以修改此字段来限制用户的评分权限
            can_rate=True,
            
            # 账户激活状态：新用户默认激活
            # 即使is_active=True，如果approval_status='pending'，用户仍无法登录
            # 管理员可以设置is_active=False来禁用账户
            is_active=True,
        )
        
        # ========== 步骤5：设置密码（自动哈希） ==========
        
        # 使用Django的set_password方法设置密码
        # 
        # set_password方法会自动执行以下操作：
        # 1. 生成随机盐值（salt）
        #    - 使用os.urandom()生成加密安全的随机字节
        #    - Base64编码为字符串（例如："abc123xyz"）
        #
        # 2. 选择哈希算法
        #    - 默认使用PBKDF2 with SHA-256
        #    - 可以通过settings.PASSWORD_HASHERS自定义
        #
        # 3. 执行密码哈希
        #    - 算法：PBKDF2 (Password-Based Key Derivation Function 2)
        #    - 迭代次数：260,000次（默认值）
        #    - 输入：明文密码 + 盐值
        #    - 输出：32字节的二进制哈希值
        #
        # 4. 格式化存储
        #    - 格式：<algorithm>$<iterations>$<salt>$<hash>
        #    - 示例：pbkdf2_sha256$260000$abc123xyz$def456uvw789ghi012jkl345mno678pqr901stu234vwx567yz
        #    - 存储到user.password字段
        #
        # 安全特性：
        # - 密码永远不会以明文形式存储到数据库
        # - 每个密码都有唯一的盐值，防止彩虹表攻击
        # - 260,000次迭代增加计算成本，减缓暴力破解速度
        # - 即使数据库被泄露，攻击者也无法直接获取用户密码
        #
        # 性能说明：
        # - 每次密码哈希需要约100-200毫秒（260,000次迭代）
        # - 这增加了暴力破解的成本，但不会显著影响用户体验
        user.set_password(password)
        
        # ========== 步骤6：保存用户到数据库 ==========
        
        # 保存用户对象到数据库
        # 此时user.password字段包含哈希后的密码字符串
        # 其他字段（username, email, real_name等）也会被保存
        user.save()
        
        # ========== 步骤7：返回用户对象 ==========
        
        # 返回创建的用户对象
        # 注意：返回的user对象中，password字段是哈希值，不是明文密码
        # 序列化器会自动排除password字段，不会在API响应中返回
        return user

