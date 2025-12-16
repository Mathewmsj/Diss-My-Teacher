from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import School, Department, Teacher, Rating, UserVote, UserInteraction, User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    fieldsets = BaseUserAdmin.fieldsets + (
        ('Additional Info', {'fields': ('school',)}),
    )


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ('school_code', 'school_name')
    search_fields = ('school_code', 'school_name')


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ('department_id', 'department_name')
    search_fields = ('department_name',)


@admin.register(Teacher)
class TeacherAdmin(admin.ModelAdmin):
    list_display = ('teacher_id', 'name', 'department')
    search_fields = ('name',)
    list_filter = ('department',)


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ('rating_id', 'teacher', 'user', 'tier', 'created_at')
    list_filter = ('tier', 'teacher')
    search_fields = ('reason',)


@admin.register(UserVote)
class UserVoteAdmin(admin.ModelAdmin):
    list_display = ('vote_id', 'user', 'vote_date', 'teacher')
    list_filter = ('vote_date',)


@admin.register(UserInteraction)
class UserInteractionAdmin(admin.ModelAdmin):
    list_display = ('interaction_id', 'user', 'rating', 'interaction_type', 'created_at')
    list_filter = ('interaction_type',)

