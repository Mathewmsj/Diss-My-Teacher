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
    school = models.ForeignKey(School, on_delete=models.SET_NULL, null=True, blank=True)
    APPROVAL_PENDING = 'pending'
    APPROVAL_APPROVED = 'approved'
    APPROVAL_REJECTED = 'rejected'
    APPROVAL_CHOICES = (
        (APPROVAL_PENDING, 'Pending'),
        (APPROVAL_APPROVED, 'Approved'),
        (APPROVAL_REJECTED, 'Rejected'),
    )

    approval_status = models.CharField(max_length=16, choices=APPROVAL_CHOICES, default=APPROVAL_PENDING)
    is_approved = models.BooleanField(default=False)
    can_rate = models.BooleanField(default=True)
    real_name = models.CharField(max_length=128, unique=True, null=True, blank=True, verbose_name='真实姓名')

    def __str__(self):
        return self.username


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

