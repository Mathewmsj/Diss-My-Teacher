from django.contrib.auth import get_user_model
from rest_framework import serializers

from .models import School, Department, Teacher, Rating, UserVote, UserInteraction, Comment, CommentInteraction


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
    user_name = serializers.CharField(source='user.username', read_only=True)
    teacher_name = serializers.CharField(source='teacher.name', read_only=True)
    masked_user_id = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Rating
        fields = [
            'rating_id', 'teacher', 'teacher_name', 'user', 'user_name', 'masked_user_id',
            'tier', 'reason', 'likes', 'dislikes', 'is_featured', 'created_at', 'updated_at'
        ]
        read_only_fields = ['likes', 'dislikes', 'is_featured', 'created_at', 'updated_at', 'user']

    def get_masked_user_id(self, obj):
        return f'anon-{obj.user_id}'

    def to_representation(self, instance):
        data = super().to_representation(instance)
        request = self.context.get('request')
        # 对非管理员隐藏真实用户信息，保留匿名标识
        if request and not request.user.is_staff:
            data.pop('user', None)
            data.pop('user_name', None)
        return data


class CommentSerializer(serializers.ModelSerializer):
    """评论序列化器"""
    user_name = serializers.CharField(source='user.username', read_only=True)
    reply_count = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Comment
        fields = [
            'comment_id', 'rating', 'user', 'user_name',
            'content', 'parent', 'likes', 'dislikes', 'reply_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['likes', 'dislikes', 'created_at', 'updated_at', 'user']

    def get_reply_count(self, obj):
        return obj.replies.count()

    def to_representation(self, instance):
        data = super().to_representation(instance)
        # 始终显示用户名，只隐藏user ID
        data.pop('user', None)
        return data


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
        school_code = validated_data.pop('school_code', '').strip()
        if not school_code:
            raise serializers.ValidationError({'school_code': '学校代码必填'})
        password = validated_data.pop('password')
        real_name = validated_data.pop('real_name', '').strip()
        if not real_name:
            raise serializers.ValidationError({'real_name': '真实姓名不能为空'})
        # 学校代码必须已存在，不允许自动创建
        try:
            school = School.objects.get(school_code=school_code)
        except School.DoesNotExist:
            raise serializers.ValidationError({'school_code': f'学校代码 "{school_code}" 不存在，请联系管理员'})
        user = get_user_model().objects.create(
            **validated_data,
            real_name=real_name,
            school=school,
            is_approved=False,
            can_rate=True,
            approval_status=getattr(get_user_model(), 'APPROVAL_PENDING', 'pending'),
            is_active=True,
        )
        user.set_password(password)
        user.save()
        return user

