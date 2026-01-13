from django.contrib.auth import get_user_model, authenticate
from rest_framework import viewsets, permissions, status, mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import GenericViewSet

from .models import School, Department, Teacher, Rating, UserVote, UserInteraction
from .serializers import (
    SchoolSerializer,
    DepartmentSerializer,
    TeacherSerializer,
    RatingSerializer,
    UserVoteSerializer,
    UserInteractionSerializer,
    UserSerializer,
    SignupSerializer,
    SuperAdminRatingSerializer,
    SuperAdminUserSerializer,
)
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from rest_framework.authtoken.models import Token


User = get_user_model()


class SchoolViewSet(viewsets.ModelViewSet):
    queryset = School.objects.all()
    serializer_class = SchoolSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.IsAuthenticated()]
        return [permissions.IsAdminUser()]

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def set_daily_limit(self, request, pk=None):
        school = self.get_object()
        # 支持旧版本的 daily_rating_limit（兼容）
        daily_limit = request.data.get('daily_rating_limit')
        if daily_limit is not None:
            try:
                daily_limit = int(daily_limit)
                if daily_limit <= 0:
                    raise ValueError
                school.daily_rating_limit = daily_limit
            except Exception:
                return Response({'detail': 'daily_rating_limit 必须为正整数'}, status=status.HTTP_400_BAD_REQUEST)
        
        # 按等级设置限制
        t1_limit = request.data.get('daily_t1_limit')
        t2_limit = request.data.get('daily_t2_limit')
        t3_limit = request.data.get('daily_t3_limit')
        
        update_fields = []
        if t1_limit is not None:
            try:
                t1_limit = int(t1_limit)
                if t1_limit < 0:
                    raise ValueError
                school.daily_t1_limit = t1_limit
                update_fields.append('daily_t1_limit')
            except Exception:
                return Response({'detail': 'daily_t1_limit 必须为非负整数'}, status=status.HTTP_400_BAD_REQUEST)
        
        if t2_limit is not None:
            try:
                t2_limit = int(t2_limit)
                if t2_limit < 0:
                    raise ValueError
                school.daily_t2_limit = t2_limit
                update_fields.append('daily_t2_limit')
            except Exception:
                return Response({'detail': 'daily_t2_limit 必须为非负整数'}, status=status.HTTP_400_BAD_REQUEST)
        
        if t3_limit is not None:
            try:
                t3_limit = int(t3_limit)
                if t3_limit < 0:
                    raise ValueError
                school.daily_t3_limit = t3_limit
                update_fields.append('daily_t3_limit')
            except Exception:
                return Response({'detail': 'daily_t3_limit 必须为非负整数'}, status=status.HTTP_400_BAD_REQUEST)
        
        if daily_limit is not None:
            update_fields.append('daily_rating_limit')
        
        if update_fields:
            school.save(update_fields=update_fields)
            return Response({
                'detail': '更新成功',
                'daily_t1_limit': school.daily_t1_limit,
                'daily_t2_limit': school.daily_t2_limit,
                'daily_t3_limit': school.daily_t3_limit,
                'daily_rating_limit': school.daily_rating_limit
            })
        else:
            return Response({'detail': '请至少提供一个限制参数'}, status=status.HTTP_400_BAD_REQUEST)


class DepartmentViewSet(viewsets.ModelViewSet):
    queryset = Department.objects.all()
    serializer_class = DepartmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.IsAuthenticated()]
        return [permissions.IsAdminUser()]


class TeacherViewSet(viewsets.ModelViewSet):
    queryset = Teacher.objects.select_related('department').all()
    serializer_class = TeacherSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        if self.request.method in permissions.SAFE_METHODS:
            return [permissions.IsAuthenticated()]
        return [permissions.IsAdminUser()]

    def perform_create(self, serializer):
        # 默认绑定管理员所在学校
        school = serializer.validated_data.get('school') or getattr(self.request.user, 'school', None)
        serializer.save(school=school)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def create_one(self, request):
        """
        单个新增老师，传 name, department_name，可选 school_code。
        如果未传 school_code，则默认当前管理员所在学校。
        """
        name = (request.data.get('name') or '').strip()
        dept_name = (request.data.get('department_name') or '').strip()
        school_code = (request.data.get('school_code') or '').strip()

        if not name or not dept_name:
            return Response({'detail': 'name 和 department_name 必填'}, status=status.HTTP_400_BAD_REQUEST)

        school = None
        if school_code:
            school, _ = School.objects.get_or_create(school_code=school_code, defaults={'school_name': school_code})
        else:
            school = getattr(request.user, 'school', None)

        dept, _ = Department.objects.get_or_create(department_name=dept_name)
        teacher, created = Teacher.objects.get_or_create(name=name, department=dept, school=school)
        ser = self.get_serializer(teacher)
        return Response(ser.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.is_superuser or not getattr(user, 'school', None):
            return qs
        return qs.filter(school=user.school)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def bulk_import(self, request):
        """
        通过简易 CSV 导入老师，字段：name,department,school_code
        若部门不存在则自动创建；若 school_code 未给出则用当前管理员所在学校。
        """
        file = request.FILES.get('file')
        if not file:
            return Response({'detail': '请上传文件'}, status=status.HTTP_400_BAD_REQUEST)
        import csv, io
        decoded = file.read().decode('utf-8')
        reader = csv.DictReader(io.StringIO(decoded))
        created = 0
        for row in reader:
            name = row.get('name', '').strip()
            dept_name = row.get('department', '').strip()
            school_code = row.get('school_code', '').strip() or getattr(request.user.school, 'school_code', None)
            if not name or not dept_name or not school_code:
                continue
            school, _ = School.objects.get_or_create(school_code=school_code, defaults={'school_name': school_code})
            dept, _ = Department.objects.get_or_create(department_name=dept_name)
            Teacher.objects.get_or_create(
                name=name,
                school=school,
                department=dept,
            )
            created += 1
        return Response({'detail': '导入完成', 'created': created})


class RatingViewSet(viewsets.ModelViewSet):
    queryset = Rating.objects.select_related('teacher', 'user').all()
    serializer_class = RatingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        """
        仅允许评分的创建者或管理员删除评分。
        """
        instance = self.get_object()
        user = request.user
        if (instance.user_id != user.id) and (not user.is_staff and not user.is_superuser):
            return Response({'detail': '无权删除此评分'}, status=status.HTTP_403_FORBIDDEN)
        self.perform_destroy(instance)
        return Response(status=status.HTTP_204_NO_CONTENT)

    def perform_create(self, serializer):
        from django.db import transaction
        
        user = self.request.user
        if not user.is_approved:
            raise ValidationError('账号未通过审核，无法评分')
        if not user.can_rate:
            raise ValidationError('账号已被禁用评分权限')

        teacher = serializer.validated_data['teacher']
        if user.school and teacher.school and user.school != teacher.school:
            raise ValidationError('不可为其他学校的老师评分')

        # 按等级每日限流
        today = timezone.localdate()
        tier = serializer.validated_data['tier']
        
        # 获取学校限制（如果没有学校，使用默认值）
        if user.school:
            if tier == 'T1':
                tier_limit = user.school.daily_t1_limit
            elif tier == 'T2':
                tier_limit = user.school.daily_t2_limit
            elif tier == 'T3':
                tier_limit = user.school.daily_t3_limit
            else:
                tier_limit = 0
        else:
            # 默认值：T1=3, T2=2, T3=1
            tier_limit = {'T1': 3, 'T2': 2, 'T3': 1}.get(tier, 0)
        
        # 检查该等级的今日使用次数
        today_tier_count = UserVote.objects.filter(
            user=user, 
            vote_date=today, 
            tier=tier
        ).count()
        
        if today_tier_count >= tier_limit:
            raise ValidationError(f'今日{tier}等级评分次数已达上限（{tier_limit}次）')

        # 检查用户今天是否已经对同一个老师评论过
        today_start = timezone.now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = today_start + timezone.timedelta(days=1)
        existing_rating = Rating.objects.filter(
            user=user,
            teacher=teacher,
            created_at__gte=today_start,
            created_at__lt=today_end
        ).first()
        
        if existing_rating:
            raise ValidationError('您今天已经对该老师进行过评分，请明天再试')

        # 使用事务确保原子性
        with transaction.atomic():
            try:
                serializer.save(user=user)
                UserVote.objects.create(user=user, vote_date=today, teacher=teacher, tier=tier)
            except Exception as e:
                # 如果是唯一性约束错误，提供更友好的错误信息
                if 'unique' in str(e).lower() or 'duplicate' in str(e).lower():
                    raise ValidationError('您今天已经对该老师进行过评分，请明天再试')
                raise

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def mine(self, request):
        """
        当前登录用户的所有评分，用于“我的评分”页面。
        """
        qs = Rating.objects.filter(user=request.user).select_related('teacher')
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def like(self, request, pk=None):
        rating = self.get_object()
        user = request.user
        interaction = UserInteraction.objects.filter(user=user, rating=rating).first()

        if interaction and interaction.interaction_type == UserInteraction.LIKE:
            # 取消点赞
            rating.likes = max(0, rating.likes - 1)
            interaction.delete()
        else:
            # 从点踩切换到点赞
            if interaction and interaction.interaction_type == UserInteraction.DISLIKE:
                rating.dislikes = max(0, rating.dislikes - 1)
                interaction.interaction_type = UserInteraction.LIKE
                interaction.save(update_fields=['interaction_type'])
            else:
                UserInteraction.objects.create(user=user, rating=rating, interaction_type=UserInteraction.LIKE)
            rating.likes = (rating.likes or 0) + 1

        rating.save(update_fields=['likes', 'dislikes'])
        serializer = self.get_serializer(rating)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def dislike(self, request, pk=None):
        rating = self.get_object()
        user = request.user
        interaction = UserInteraction.objects.filter(user=user, rating=rating).first()

        if interaction and interaction.interaction_type == UserInteraction.DISLIKE:
            # 取消点踩
            rating.dislikes = max(0, rating.dislikes - 1)
            interaction.delete()
        else:
            # 从点赞切换到点踩
            if interaction and interaction.interaction_type == UserInteraction.LIKE:
                rating.likes = max(0, rating.likes - 1)
                interaction.interaction_type = UserInteraction.DISLIKE
                interaction.save(update_fields=['interaction_type'])
            else:
                UserInteraction.objects.create(user=user, rating=rating, interaction_type=UserInteraction.DISLIKE)
            rating.dislikes = (rating.dislikes or 0) + 1

        rating.save(update_fields=['likes', 'dislikes'])
        serializer = self.get_serializer(rating)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def toggle_featured(self, request, pk=None):
        """管理员设置/取消神评"""
        rating = self.get_object()
        rating.is_featured = not rating.is_featured
        rating.save(update_fields=['is_featured'])
        status_text = '已设为神评' if rating.is_featured else '已取消神评'
        serializer = self.get_serializer(rating)
        return Response({
            'detail': status_text,
            'rating': serializer.data
        })


class UserVoteViewSet(viewsets.ModelViewSet):
    queryset = UserVote.objects.select_related('user', 'teacher').all()
    serializer_class = UserVoteSerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def quota(self, request):
        """
        返回当前用户今日额度：按等级分别返回 limit/used/remaining。
        """
        user = request.user
        today = timezone.localdate()
        
        # 获取学校限制（如果没有学校，使用默认值）
        if user.school:
            t1_limit = user.school.daily_t1_limit
            t2_limit = user.school.daily_t2_limit
            t3_limit = user.school.daily_t3_limit
        else:
            t1_limit = 3
            t2_limit = 2
            t3_limit = 1
        
        # 统计各等级今日使用次数
        t1_used = UserVote.objects.filter(user=user, vote_date=today, tier='T1').count()
        t2_used = UserVote.objects.filter(user=user, vote_date=today, tier='T2').count()
        t3_used = UserVote.objects.filter(user=user, vote_date=today, tier='T3').count()
        
        return Response({
            'T1': {
                'limit': t1_limit,
                'used': t1_used,
                'remaining': max(t1_limit - t1_used, 0)
            },
            'T2': {
                'limit': t2_limit,
                'used': t2_used,
                'remaining': max(t2_limit - t2_used, 0)
            },
            'T3': {
                'limit': t3_limit,
                'used': t3_used,
                'remaining': max(t3_limit - t3_used, 0)
            },
            # 兼容旧版本
            'limit': t1_limit + t2_limit + t3_limit,
            'used': t1_used + t2_used + t3_used,
            'remaining': max(t1_limit - t1_used, 0) + max(t2_limit - t2_used, 0) + max(t3_limit - t3_used, 0)
        })


class UserInteractionViewSet(viewsets.ModelViewSet):
    queryset = UserInteraction.objects.select_related('user', 'rating').all()
    serializer_class = UserInteractionSerializer
    permission_classes = [permissions.IsAuthenticated]


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.select_related('school').all()
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        # me / change_password 接口：登录即可；其余需要管理员
        if getattr(self, 'action', None) in ['me', 'change_password']:
            return [permissions.IsAuthenticated()]
        return [permissions.IsAdminUser()]

    def get_queryset(self):
        qs = super().get_queryset()
        user = self.request.user
        if user.is_superuser or not user.school:
            return qs
        return qs.filter(school=user.school)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAuthenticated])
    def me(self, request):
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['post'], permission_classes=[permissions.IsAuthenticated])
    def change_password(self, request):
        """
        修改当前登录用户密码
        
        功能说明：
        允许已登录用户修改自己的密码。需要提供旧密码和新密码。
        
        安全流程：
        1. 验证旧密码（防止未授权修改）
        2. 验证新密码长度
        3. 使用Django的set_password方法对新密码进行哈希
        4. 保存到数据库
        
        请求格式：
        POST /api/users/change_password/
        {
            "old_password": "oldpass123",  // 必填：当前密码
            "new_password": "newpass456"    // 必填：新密码（至少6位）
        }
        
        响应格式（成功）：
        {
            "detail": "密码修改成功"
        }
        
        响应格式（失败）：
        - 400 Bad Request: {"detail": "old_password 和 new_password 必填"}
        - 400 Bad Request: {"detail": "原密码不正确"}
        - 400 Bad Request: {"detail": "新密码长度至少 6 位"}
        """
        # ========== 步骤1：获取当前用户 ==========
        
        # request.user 由DRF的TokenAuthentication中间件设置
        # 如果请求头中包含有效的Token，request.user就是对应的User对象
        # 如果Token无效或不存在，request.user是AnonymousUser
        user = request.user
        
        # ========== 步骤2：提取密码数据 ==========
        
        # 从请求体中获取旧密码和新密码
        old_password = request.data.get('old_password') or ''
        new_password = request.data.get('new_password') or ''

        # ========== 步骤3：验证必填字段 ==========
        
        # 检查是否提供了旧密码和新密码
        if not old_password or not new_password:
            return Response(
                {'detail': 'old_password 和 new_password 必填'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # ========== 步骤4：验证旧密码 ==========
        
        # 使用Django的check_password方法验证旧密码
        # 
        # check_password工作原理：
        # 1. 从user.password字段获取存储的密码哈希
        # 2. 解析哈希字符串，提取：
        #    - 算法名称（如"pbkdf2_sha256"）
        #    - 迭代次数（如260000）
        #    - 盐值（随机字符串）
        #    - 哈希值（最终的密码哈希）
        # 3. 使用相同的算法、迭代次数和盐值对输入的旧密码进行哈希
        # 4. 比较计算出的哈希值与存储的哈希值
        # 5. 如果匹配，返回True；如果不匹配，返回False
        #
        # 安全特性：
        # - 不会暴露密码哈希值
        # - 使用恒定时间比较，防止时序攻击
        # - 支持多种哈希算法（自动检测）
        if not user.check_password(old_password):
            return Response(
                {'detail': '原密码不正确'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # ========== 步骤5：验证新密码长度 ==========
        
        # 检查新密码长度（至少6位）
        # 注意：这里只检查长度，Django的密码验证器（AUTH_PASSWORD_VALIDATORS）
        # 会在set_password时自动运行，检查密码复杂度等
        if len(new_password) < 6:
            return Response(
                {'detail': '新密码长度至少 6 位'}, 
                status=status.HTTP_400_BAD_REQUEST
            )

        # ========== 步骤6：设置新密码 ==========
        
        # 使用Django的set_password方法设置新密码
        # 
        # set_password工作原理：
        # 1. 生成随机盐值（salt）
        #    - 使用os.urandom()生成加密安全的随机字节
        #    - Base64编码为字符串
        # 2. 选择哈希算法
        #    - 默认使用PBKDF2 with SHA-256
        #    - 可以通过PASSWORD_HASHERS设置自定义算法
        # 3. 执行密码哈希
        #    - 使用PBKDF2算法
        #    - 默认迭代260,000次（可通过PASSWORD_HASHERS配置修改）
        #    - 输入：密码 + 盐值
        #    - 输出：32字节的哈希值
        # 4. 格式化存储
        #    - 格式：<algorithm>$<iterations>$<salt>$<hash>
        #    - 示例：pbkdf2_sha256$260000$abc123$def456...
        # 5. 存储到user.password字段
        #
        # PBKDF2算法说明：
        # - PBKDF2 (Password-Based Key Derivation Function 2) 是NIST推荐的标准算法
        # - 通过多次迭代增加计算成本，减缓暴力破解速度
        # - 260,000次迭代意味着每次密码验证需要约100-200毫秒
        # - 即使攻击者获得数据库，也无法快速破解密码
        user.set_password(new_password)
        
        # ========== 步骤7：保存到数据库 ==========
        
        # 只更新password字段，提高效率
        # update_fields=['password'] 确保只更新密码字段，不会触发其他字段的更新
        user.save(update_fields=['password'])
        
        # ========== 步骤8：返回成功响应 ==========
        
        return Response({'detail': '密码修改成功'})

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def pending(self, request):
        qs = self.get_queryset().filter(
            approval_status=User.APPROVAL_PENDING,
            is_staff=False,
            is_superuser=False,
        )
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def approved(self, request):
        qs = self.get_queryset().filter(
            approval_status=User.APPROVAL_APPROVED,
            is_staff=False,
            is_superuser=False,
        )
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], permission_classes=[permissions.IsAdminUser])
    def rejected(self, request):
        qs = self.get_queryset().filter(
            approval_status=User.APPROVAL_REJECTED,
            is_staff=False,
            is_superuser=False,
        )
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        user = self.get_object()
        admin_school = getattr(request.user, 'school', None)
        if admin_school and user.school and admin_school != user.school and not request.user.is_superuser:
            return Response({'detail': '无权审批其他学校用户'}, status=status.HTTP_403_FORBIDDEN)
        user.is_approved = True
        user.can_rate = True
        user.approval_status = User.APPROVAL_APPROVED
        user.save(update_fields=['is_approved', 'can_rate', 'approval_status'])
        return Response({'detail': '用户已通过审批'})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def toggle_rate(self, request, pk=None):
        user = self.get_object()
        admin_school = getattr(request.user, 'school', None)
        if admin_school and user.school and admin_school != user.school and not request.user.is_superuser:
            return Response({'detail': '无权操作其他学校用户'}, status=status.HTTP_403_FORBIDDEN)
        can_rate = request.data.get('can_rate')
        if can_rate is None:
            return Response({'detail': '缺少 can_rate 参数'}, status=status.HTTP_400_BAD_REQUEST)
        user.can_rate = bool(can_rate) if isinstance(can_rate, bool) else str(can_rate).lower() in ['1', 'true', 'yes']
        user.save(update_fields=['can_rate'])
        return Response({'detail': '评分权限已更新', 'can_rate': user.can_rate})

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        """
        拒绝审批：可选地禁用评分并标记未通过。
        """
        user = self.get_object()
        admin_school = getattr(request.user, 'school', None)
        if admin_school and user.school and admin_school != user.school and not request.user.is_superuser:
            return Response({'detail': '无权操作其他学校用户'}, status=status.HTTP_403_FORBIDDEN)
        user.is_approved = False
        user.can_rate = False
        user.approval_status = User.APPROVAL_REJECTED
        user.save(update_fields=['is_approved', 'can_rate', 'approval_status'])
        return Response({'detail': '用户已被拒绝，评分权限已关闭'})

    @action(detail=True, methods=['delete'], permission_classes=[permissions.IsAdminUser])
    def delete_user(self, request, pk=None):
        user = self.get_object()
        admin_school = getattr(request.user, 'school', None)
        # 禁止删除自己
        if request.user.id == user.id:
            return Response({'detail': '不能删除当前登录账号'}, status=status.HTTP_400_BAD_REQUEST)
        if admin_school and user.school and admin_school != user.school and not request.user.is_superuser:
            return Response({'detail': '无权删除其他学校用户'}, status=status.HTTP_403_FORBIDDEN)
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class SignupViewSet(mixins.CreateModelMixin, GenericViewSet):
    queryset = User.objects.all()
    serializer_class = SignupSerializer
    permission_classes = [permissions.AllowAny]


class LoginUserViewSet(viewsets.ViewSet):
    """
    普通用户登录视图集
    
    功能说明：
    处理普通用户的登录请求，支持使用用户名或邮箱登录。
    登录成功后返回身份验证令牌（Token），用于后续 API 请求的身份验证。
    
    权限设置：
    permission_classes = [permissions.AllowAny]
    - 允许未认证用户访问（因为登录本身就需要未认证状态）
    - 登录成功后，后续请求需要使用返回的 Token 进行身份验证
    
    认证流程：
    1. 接收登录请求（用户名/邮箱 + 密码）
    2. 查找用户（先按用户名，再按邮箱）
    3. 验证密码（使用 Django 的 authenticate 函数）
    4. 检查账户状态（审批状态、激活状态）
    5. 生成或获取 Token
    6. 返回 Token 和用户信息
    """
    permission_classes = [permissions.AllowAny]

    def create(self, request):
        """
        用户登录接口
        
        功能说明：
        处理 POST 请求，验证用户身份并返回 Token。
        支持使用用户名或邮箱登录，提高了用户体验的灵活性。
        
        请求格式：
        POST /api/login-user/
        {
            "username": "user123",  // 可选：用户名
            "email": "user@example.com",  // 可选：邮箱
            "password": "password123"  // 必填：密码
        }
        
        注意：username 和 email 字段可以只提供一个，后端会尝试两种方式查找用户。
        
        响应格式（成功）：
        {
            "detail": "登录成功",
            "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",  // 40字符的Token
            "user_id": 123
        }
        
        响应格式（失败）：
        - 400 Bad Request: {"detail": "用户不存在"} 或 {"detail": "认证失败"}
        - 403 Forbidden: {"detail": "账号待审批，登录受限"} 等
        
        @param request: Django REST Framework 的请求对象
        @return: Response 对象，包含登录结果
        """
        # ========== 步骤1：提取和清理用户输入 ==========
        
        # 从请求数据中获取标识符（可以是用户名或邮箱）
        # request.data 是 DRF 解析后的请求体数据（JSON格式）
        # 使用 or 运算符，优先使用 username，如果没有则使用 email
        # strip() 去除首尾空白字符，防止用户误输入空格
        identifier = (request.data.get('username') or request.data.get('email') or '').strip()
        
        # 从请求数据中获取密码
        # 如果没有提供密码，默认为空字符串
        password = request.data.get('password', '')
        
        # ========== 步骤2：查找用户 ==========
        
        user = None  # 初始化用户变量
        
        # 如果提供了标识符，尝试查找用户
        if identifier:
            # 策略1：先尝试按用户名查找
            # 这是最常见的登录方式，优先尝试可以提高查找效率
            try:
                # User.objects.get() 是 Django ORM 的查询方法
                # 如果找到用户，返回 User 对象；如果找不到，抛出 User.DoesNotExist 异常
                user = User.objects.get(username=identifier)
            except User.DoesNotExist:
                # 如果按用户名找不到，尝试按邮箱查找
                # 这允许用户使用邮箱登录，提高了灵活性
                try:
                    user = User.objects.get(email=identifier)
                except User.DoesNotExist:
                    # 如果两种方式都找不到，user 保持为 None
                    pass
        
        # ========== 步骤3：验证用户是否存在 ==========
        
        # 如果找不到用户，返回错误响应
        if not user:
            # 返回 400 Bad Request 状态码，表示客户端请求错误
            # 不明确说明是用户名还是邮箱不存在，避免泄露用户信息（安全考虑）
            return Response(
                {'detail': '用户不存在'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ========== 步骤4：验证密码 ==========
        
        # 使用 Django 的 authenticate 函数验证密码
        # authenticate 是 Django 提供的标准身份验证函数
        # 
        # 工作原理：
        # 1. 从数据库中获取用户的密码哈希
        # 2. 使用 PBKDF2 算法对输入的密码进行哈希（使用相同的盐值）
        # 3. 比较计算出的哈希值与存储的哈希值
        # 4. 如果匹配，返回 User 对象；如果不匹配，返回 None
        #
        # 安全特性：
        # - 密码使用 PBKDF2 算法哈希，默认 260,000 次迭代
        # - 每个密码都有唯一的盐值，防止彩虹表攻击
        # - 密码哈希是单向的，无法反向获取原始密码
        auth_user = authenticate(
            request,                    # 请求对象（用于获取请求上下文）
            username=user.username,     # 必须使用数据库中的用户名（不是用户输入的标识符）
            password=password           # 用户输入的明文密码
        )
        
        # 如果密码验证失败，返回错误响应
        if not auth_user:
            # 返回 400 Bad Request，不明确说明是密码错误还是用户名错误
            # 这样可以防止攻击者通过错误信息判断用户名是否存在
            return Response(
                {'detail': '认证失败'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ========== 步骤5：检查账户审批状态 ==========
        
        # 检查账户是否处于待审批状态
        # approval_status 是自定义字段，用于控制新用户注册后的审批流程
        # getattr 用于安全获取属性，如果属性不存在则返回默认值
        if getattr(auth_user, 'approval_status', User.APPROVAL_PENDING) == User.APPROVAL_PENDING:
            # 返回 403 Forbidden，表示服务器理解请求但拒绝执行
            # 待审批的用户不能登录，需要管理员审批后才能使用
            return Response(
                {'detail': '账号待审批，登录受限'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # 检查账户是否被拒绝
        if getattr(auth_user, 'approval_status', User.APPROVAL_PENDING) == User.APPROVAL_REJECTED:
            # 被拒绝的账户不能登录
            return Response(
                {'detail': '账号已被拒绝，无法登录'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # ========== 步骤6：检查账户激活状态 ==========
        
        # 检查账户是否被停用
        # is_active 是 Django User 模型的标准字段
        # 如果账户被停用，即使密码正确也不能登录
        if not getattr(auth_user, 'is_active', True):
            return Response(
                {'detail': '账号已停用'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # ========== 步骤7：生成或获取 Token ==========
        
        # 使用 get_or_create 方法获取或创建 Token
        # 这是 Django ORM 的便捷方法，如果 Token 已存在则返回，不存在则创建
        #
        # 返回值：
        # - token: Token 对象
        # - created: 布尔值，True 表示新创建，False 表示已存在
        #
        # Token 特性：
        # - 每个用户只有一个 Token（OneToOne 关系）
        # - Token key 是 40 字符的随机十六进制字符串
        # - Token 持久存在，直到显式删除或用户被删除
        # - 如果用户多次登录，返回相同的 Token（不重新生成）
        token, _ = Token.objects.get_or_create(user=auth_user)
        
        # ========== 步骤8：返回成功响应 ==========
        
        # 返回登录成功的响应，包含 Token 和用户ID
        # 前端会将 Token 存储到 localStorage，用于后续请求的身份验证
        return Response({
            'detail': '登录成功',           # 成功消息
            'token': token.key,            # 身份验证令牌（40字符）
            'user_id': auth_user.id        # 用户ID，用于前端识别用户
        })


class AdminLoginViewSet(viewsets.ViewSet):
    """
    管理员登录视图集
    
    功能说明：
    处理管理员的登录请求，需要提供学校代码、管理员账号和密码。
    只有 is_staff=True 的用户才能使用此接口登录。
    
    权限设置：
    permission_classes = [permissions.AllowAny]
    - 允许未认证用户访问（登录接口本身需要未认证状态）
    
    认证流程：
    1. 接收登录请求（学校代码 + 用户名 + 密码）
    2. 验证用户名和密码
    3. 检查用户是否为管理员（is_staff=True）
    4. 验证学校代码是否匹配
    5. 生成或获取 Token
    6. 返回 Token、用户ID和学校代码
    
    安全特性：
    - 需要额外的学校代码验证，提高安全性
    - 管理员只能管理自己学校的用户和教师
    - 防止管理员跨学校操作
    """
    permission_classes = [permissions.AllowAny]

    def create(self, request):
        """
        管理员登录接口
        
        功能说明：
        处理管理员的登录请求，验证学校代码、用户名和密码。
        只有管理员（is_staff=True）且学校代码匹配的用户才能登录成功。
        
        请求格式：
        POST /api/admin-login/
        {
            "school_code": "SCHOOL001",  // 必填：学校代码
            "username": "admin",         // 必填：管理员用户名
            "password": "password123"    // 必填：管理员密码
        }
        
        响应格式（成功）：
        {
            "detail": "登录成功",
            "user_id": 123,
            "school_code": "SCHOOL001",
            "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
        }
        
        响应格式（失败）：
        - 400 Bad Request: {"detail": "认证失败"} 或 {"detail": "学校代码不匹配"}
        
        @param request: Django REST Framework 的请求对象
        @return: Response 对象，包含登录结果
        """
        # ========== 步骤1：提取和清理用户输入 ==========
        
        # 从请求数据中获取学校代码
        # 学校代码用于验证管理员所属学校，防止跨学校操作
        school_code = request.data.get('school_code', '').strip()
        
        # 从请求数据中获取管理员用户名
        username = request.data.get('username', '').strip()
        
        # 从请求数据中获取密码
        password = request.data.get('password', '')
        
        # ========== 步骤2：验证用户名和密码 ==========
        
        # 使用 Django 的 authenticate 函数验证用户名和密码
        # 这与普通用户登录使用相同的密码验证机制（PBKDF2 哈希）
        user = authenticate(request, username=username, password=password)
        
        # ========== 步骤3：检查用户是否存在且为管理员 ==========
        
        # 验证用户是否存在且具有管理员权限
        # is_staff 是 Django User 模型的标准字段，表示是否为管理员
        if not user or not user.is_staff:
            # 如果用户不存在或不是管理员，返回认证失败
            # 不明确说明是密码错误还是权限不足，避免泄露信息
            return Response(
                {'detail': '认证失败'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ========== 步骤4：验证学校代码 ==========
        
        # 检查用户关联的学校代码是否与提供的学校代码匹配
        # 这确保管理员只能登录到自己管理的学校
        # user.school 是外键关系，可能为 None（如果用户没有关联学校）
        if user.school and user.school.school_code != school_code:
            # 如果学校代码不匹配，返回错误
            # 这防止管理员使用错误的学校代码登录
            return Response(
                {'detail': '学校代码不匹配'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ========== 步骤5：生成或获取 Token ==========
        
        # 发放 Token（与普通用户登录使用相同的机制）
        # get_or_create 确保每个用户只有一个 Token
        token, _ = Token.objects.get_or_create(user=user)
        
        # ========== 步骤6：返回成功响应 ==========
        
        # 返回登录成功的响应
        # 包含 Token、用户ID和学校代码，供前端使用
        return Response({
            'detail': '登录成功',           # 成功消息
            'user_id': user.id,            # 用户ID
            'school_code': school_code,    # 学校代码（用于前端权限控制）
            'token': token.key,            # 身份验证令牌
        })


class SuperAdminLoginViewSet(viewsets.ViewSet):
    """
    超级管理员登录视图集
    
    功能说明：
    处理超级管理员的登录请求，只需要用户名和密码。
    只有 is_superuser=True 的用户才能使用此接口登录。
    
    权限设置：
    permission_classes = [permissions.AllowAny]
    - 允许未认证用户访问（登录接口本身需要未认证状态）
    
    认证流程：
    1. 接收登录请求（用户名 + 密码）
    2. 验证用户名和密码
    3. 检查用户是否为超级管理员（is_superuser=True）
    4. 检查账户是否激活（is_active=True）
    5. 生成或获取 Token
    6. 返回 Token、用户ID和用户名
    
    安全特性：
    - 超级管理员拥有系统最高权限，可以管理所有学校、用户和教师
    - 登录验证更严格，需要 is_superuser=True
    - 建议超级管理员使用强密码并启用双因素认证
    """
    permission_classes = [permissions.AllowAny]

    def create(self, request):
        """
        超级管理员登录接口
        
        功能说明：
        处理超级管理员的登录请求，验证用户名和密码。
        只有超级管理员（is_superuser=True）才能登录成功。
        
        请求格式：
        POST /api/superadmin-login/
        {
            "username": "superadmin",  // 必填：超级管理员用户名
            "password": "password123"   // 必填：超级管理员密码
        }
        
        响应格式（成功）：
        {
            "detail": "超级管理员登录成功",
            "user_id": 1,
            "username": "superadmin",
            "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b"
        }
        
        响应格式（失败）：
        - 400 Bad Request: {"detail": "认证失败：需要超级管理员权限"}
        - 403 Forbidden: {"detail": "账号已停用"}
        
        @param request: Django REST Framework 的请求对象
        @return: Response 对象，包含登录结果
        """
        # ========== 步骤1：提取和清理用户输入 ==========
        
        # 从请求数据中获取超级管理员用户名
        username = request.data.get('username', '').strip()
        
        # 从请求数据中获取密码
        password = request.data.get('password', '')
        
        # ========== 步骤2：验证用户名和密码 ==========
        
        # 使用 Django 的 authenticate 函数验证用户名和密码
        # 这与普通用户和管理员登录使用相同的密码验证机制
        user = authenticate(request, username=username, password=password)
        
        # ========== 步骤3：检查用户是否存在且为超级管理员 ==========
        
        # 验证用户是否存在且具有超级管理员权限
        # is_superuser 是 Django User 模型的标准字段，表示是否为超级管理员
        # 超级管理员拥有系统最高权限，可以管理所有内容
        if not user or not user.is_superuser:
            # 如果用户不存在或不是超级管理员，返回认证失败
            # 明确说明需要超级管理员权限，因为这是专用接口
            return Response(
                {'detail': '认证失败：需要超级管理员权限'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # ========== 步骤4：检查账户激活状态 ==========
        
        # 检查账户是否被停用
        # 即使密码正确且是超级管理员，如果账户被停用也不能登录
        if not user.is_active:
            return Response(
                {'detail': '账号已停用'}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # ========== 步骤5：生成或获取 Token ==========
        
        # 发放 Token（与其他登录方式使用相同的机制）
        # get_or_create 确保每个用户只有一个 Token
        token, _ = Token.objects.get_or_create(user=user)
        
        # ========== 步骤6：返回成功响应 ==========
        
        # 返回登录成功的响应
        # 包含 Token、用户ID和用户名，供前端使用
        return Response({
            'detail': '超级管理员登录成功',  # 成功消息
            'user_id': user.id,            # 用户ID
            'username': user.username,      # 用户名（用于前端显示）
            'token': token.key,            # 身份验证令牌
        })


class SuperAdminViewSet(viewsets.ViewSet):
    """超级管理员专用视图集：可以管理所有内容"""
    permission_classes = [permissions.IsAuthenticated]

    def get_permissions(self):
        # 只有超级管理员可以访问
        return [permissions.IsAuthenticated()]

    def check_superuser(self, request):
        if not request.user.is_superuser:
            return Response({'detail': '需要超级管理员权限'}, status=status.HTTP_403_FORBIDDEN)
        return None

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """系统统计信息"""
        check = self.check_superuser(request)
        if check:
            return check
        
        from django.db.models import Count, Q
        from django.utils import timezone
        
        today = timezone.localdate()
        stats = {
            'schools': School.objects.count(),
            'teachers': Teacher.objects.count(),
            'users': User.objects.count(),
            'admins': User.objects.filter(is_staff=True).count(),
            'ratings': Rating.objects.count(),
            'ratings_today': Rating.objects.filter(created_at__date=today).count(),
            'pending_users': User.objects.filter(approval_status=User.APPROVAL_PENDING).count(),
            'approved_users': User.objects.filter(approval_status=User.APPROVAL_APPROVED).count(),
            'rejected_users': User.objects.filter(approval_status=User.APPROVAL_REJECTED).count(),
            'total_likes': UserInteraction.objects.filter(interaction_type=UserInteraction.LIKE).count(),
            'total_dislikes': UserInteraction.objects.filter(interaction_type=UserInteraction.DISLIKE).count(),
        }
        return Response(stats)

    @action(detail=False, methods=['get'])
    def all_ratings(self, request):
        """获取所有评分（包含完整用户信息）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        ratings = Rating.objects.select_related('user', 'teacher', 'teacher__school').all()
        serializer = SuperAdminRatingSerializer(ratings, many=True, context={'request': request})
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def create_school(self, request):
        """创建新学校"""
        check = self.check_superuser(request)
        if check:
            return check
        
        school_code = request.data.get('school_code', '').strip()
        school_name = request.data.get('school_name', '').strip()
        daily_limit = request.data.get('daily_rating_limit', 2)
        
        if not school_code or not school_name:
            return Response({'detail': 'school_code 和 school_name 必填'}, status=status.HTTP_400_BAD_REQUEST)
        
        if School.objects.filter(school_code=school_code).exists():
            return Response({'detail': '学校代码已存在'}, status=status.HTTP_400_BAD_REQUEST)
        
        school = School.objects.create(
            school_code=school_code,
            school_name=school_name,
            address=request.data.get('address', ''),
            daily_rating_limit=int(daily_limit),
            daily_t1_limit=int(request.data.get('daily_t1_limit', 3)),
            daily_t2_limit=int(request.data.get('daily_t2_limit', 2)),
            daily_t3_limit=int(request.data.get('daily_t3_limit', 1))
        )
        serializer = SchoolSerializer(school)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def create_admin(self, request):
        """创建新的管理员账号"""
        check = self.check_superuser(request)
        if check:
            return check
        
        username = request.data.get('username', '').strip()
        email = request.data.get('email', '').strip()
        password = request.data.get('password', '').strip()
        school_code = request.data.get('school_code', '').strip()
        
        if not username or not email or not password:
            return Response({'detail': 'username, email, password 必填'}, status=status.HTTP_400_BAD_REQUEST)
        
        if User.objects.filter(username=username).exists():
            return Response({'detail': '用户名已存在'}, status=status.HTTP_400_BAD_REQUEST)
        
        if User.objects.filter(email=email).exists():
            return Response({'detail': '邮箱已存在'}, status=status.HTTP_400_BAD_REQUEST)
        
        school = None
        if school_code:
            try:
                school = School.objects.get(school_code=school_code)
            except School.DoesNotExist:
                return Response({'detail': '学校代码不存在'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            school=school,
            is_staff=True,
            is_superuser=False,
            is_approved=True,
            can_rate=True,
            approval_status=User.APPROVAL_APPROVED,
            is_active=True
        )
        serializer = UserSerializer(user)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def all_users(self, request):
        """获取所有用户（包含完整信息，包括真实姓名）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        users = User.objects.select_related('school').all()
        serializer = SuperAdminUserSerializer(users, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def all_schools(self, request):
        """获取所有学校"""
        check = self.check_superuser(request)
        if check:
            return check
        
        schools = School.objects.all()
        serializer = SchoolSerializer(schools, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def update_user(self, request, pk=None):
        """更新用户信息（超级管理员可以修改任何用户）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'detail': '用户不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        # 允许修改的字段
        if 'username' in request.data:
            if User.objects.filter(username=request.data['username']).exclude(pk=pk).exists():
                return Response({'detail': '用户名已存在'}, status=status.HTTP_400_BAD_REQUEST)
            user.username = request.data['username']
        
        if 'email' in request.data:
            if User.objects.filter(email=request.data['email']).exclude(pk=pk).exists():
                return Response({'detail': '邮箱已存在'}, status=status.HTTP_400_BAD_REQUEST)
            user.email = request.data['email']
        
        if 'school_code' in request.data:
            school_code = request.data['school_code']
            if school_code:
                try:
                    user.school = School.objects.get(school_code=school_code)
                except School.DoesNotExist:
                    return Response({'detail': '学校代码不存在'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                user.school = None
        
        if 'is_staff' in request.data:
            user.is_staff = bool(request.data['is_staff'])
        
        if 'is_superuser' in request.data:
            # 防止删除最后一个超级管理员
            if not request.data['is_superuser'] and user.is_superuser:
                if User.objects.filter(is_superuser=True).count() <= 1:
                    return Response({'detail': '不能删除最后一个超级管理员'}, status=status.HTTP_400_BAD_REQUEST)
            user.is_superuser = bool(request.data['is_superuser'])
        
        if 'is_active' in request.data:
            user.is_active = bool(request.data['is_active'])
        
        if 'is_approved' in request.data:
            user.is_approved = bool(request.data['is_approved'])
        
        if 'can_rate' in request.data:
            user.can_rate = bool(request.data['can_rate'])
        
        if 'approval_status' in request.data:
            user.approval_status = request.data['approval_status']
        
        if 'real_name' in request.data:
            real_name = request.data['real_name'].strip() if request.data['real_name'] else ''
            if real_name:
                # 检查真实姓名唯一性（排除当前用户）
                if User.objects.filter(real_name=real_name).exclude(pk=pk).exists():
                    return Response({'detail': '真实姓名已被使用'}, status=status.HTTP_400_BAD_REQUEST)
                user.real_name = real_name
            else:
                user.real_name = None
        
        if 'password' in request.data and request.data['password']:
            user.set_password(request.data['password'])
        
        user.save()
        serializer = SuperAdminUserSerializer(user)
        return Response(serializer.data)

    @action(detail=True, methods=['delete'])
    def delete_user(self, request, pk=None):
        """删除用户（超级管理员可以删除任何用户，包括自己之外的其他超级管理员）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'detail': '用户不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        # 防止删除自己
        if user.id == request.user.id:
            return Response({'detail': '不能删除当前登录账号'}, status=status.HTTP_400_BAD_REQUEST)
        
        # 防止删除最后一个超级管理员
        if user.is_superuser and User.objects.filter(is_superuser=True).count() <= 1:
            return Response({'detail': '不能删除最后一个超级管理员'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'])
    def update_school(self, request, pk=None):
        """更新学校信息"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            school = School.objects.get(school_code=pk)
        except School.DoesNotExist:
            return Response({'detail': '学校不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        if 'school_name' in request.data:
            school.school_name = request.data['school_name']
        if 'address' in request.data:
            school.address = request.data['address']
        if 'daily_rating_limit' in request.data:
            school.daily_rating_limit = int(request.data['daily_rating_limit'])
        if 'daily_t1_limit' in request.data:
            school.daily_t1_limit = int(request.data['daily_t1_limit'])
        if 'daily_t2_limit' in request.data:
            school.daily_t2_limit = int(request.data['daily_t2_limit'])
        if 'daily_t3_limit' in request.data:
            school.daily_t3_limit = int(request.data['daily_t3_limit'])
        
        school.save()
        serializer = SchoolSerializer(school)
        return Response(serializer.data)

    @action(detail=True, methods=['delete'])
    def delete_school(self, request, pk=None):
        """删除学校"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            school = School.objects.get(school_code=pk)
        except School.DoesNotExist:
            return Response({'detail': '学校不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        school.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['delete'])
    def delete_rating(self, request, pk=None):
        """删除评分（超级管理员可以删除任何评分）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            rating = Rating.objects.get(rating_id=pk)
        except Rating.DoesNotExist:
            return Response({'detail': '评分不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        rating.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=['post'])
    def reset_user_password(self, request, pk=None):
        """重置用户密码"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            user = User.objects.get(pk=pk)
        except User.DoesNotExist:
            return Response({'detail': '用户不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        new_password = request.data.get('password', '').strip()
        if not new_password:
            return Response({'detail': '新密码不能为空'}, status=status.HTTP_400_BAD_REQUEST)
        
        if len(new_password) < 6:
            return Response({'detail': '密码长度至少6位'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.set_password(new_password)
        user.save(update_fields=['password'])
        return Response({'detail': '密码重置成功'})

    @action(detail=True, methods=['post'])
    def update_school_code(self, request, pk=None):
        """更新学校代码（全局生效，更新所有相关记录）"""
        check = self.check_superuser(request)
        if check:
            return check
        
        try:
            school = School.objects.get(school_code=pk)
        except School.DoesNotExist:
            return Response({'detail': '学校不存在'}, status=status.HTTP_404_NOT_FOUND)
        
        new_code = request.data.get('new_school_code', '').strip()
        if not new_code:
            return Response({'detail': '新学校代码不能为空'}, status=status.HTTP_400_BAD_REQUEST)
        
        if School.objects.filter(school_code=new_code).exists():
            return Response({'detail': '新学校代码已存在'}, status=status.HTTP_400_BAD_REQUEST)
        
        old_code = school.school_code
        
        # 由于 school_code 是主键，需要使用数据库事务来更新
        from django.db import transaction
        
        with transaction.atomic():
            # 1. 创建新学校记录（使用新代码，复制所有数据）
            new_school = School.objects.create(
                school_code=new_code,
                school_name=school.school_name,
                address=school.address,
                daily_rating_limit=school.daily_rating_limit,
                created_at=school.created_at
            )
            
            # 2. 更新所有相关记录的外键引用
            # 更新用户
            User.objects.filter(school=school).update(school=new_school)
            
            # 更新老师
            Teacher.objects.filter(school=school).update(school=new_school)
            
            # 3. 删除旧学校记录
            school.delete()
        
        return Response({
            'detail': '学校代码更新成功，所有相关记录已同步更新',
            'old_code': old_code,
            'new_code': new_code
        })

