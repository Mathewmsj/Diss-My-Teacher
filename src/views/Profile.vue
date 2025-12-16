<template>
  <div class="profile">
    <!-- 头部：通用 -->
    <el-card shadow="hover" class="profile-header">
      <template #header>
        <div class="header-row">
          <div>
            <h2>{{ user?.username || '未登录' }}</h2>
            <p class="subtitle">{{ user?.email }}</p>
          </div>
          <div class="actions">
            <el-button type="default" @click="goHome">返回首页</el-button>
            <el-button type="primary" link @click="openChangePwd">修改密码</el-button>
            <el-button type="text" @click="logout">退出登录</el-button>
          </div>
        </div>
      </template>

      <!-- 学生视图：显示额度和个人评分统计 -->
      <el-descriptions v-if="!isAdmin" :column="2" border>
        <el-descriptions-item label="今日额度" :span="2">
          <div v-if="quotaTier" style="display: flex; gap: 20px;">
            <span>T1: {{ quotaTier.T1.used }}/{{ quotaTier.T1.limit }}（剩余 {{ quotaTier.T1.remaining }}）</span>
            <span>T2: {{ quotaTier.T2.used }}/{{ quotaTier.T2.limit }}（剩余 {{ quotaTier.T2.remaining }}）</span>
            <span>T3: {{ quotaTier.T3.used }}/{{ quotaTier.T3.limit }}（剩余 {{ quotaTier.T3.remaining }}）</span>
          </div>
          <span v-else>{{ quotaUsed }} / {{ quotaLimit }}（剩余 {{ quotaRemaining }}）</span>
        </el-descriptions-item>
        <el-descriptions-item label="总评分数">{{ userRatings.length }}</el-descriptions-item>
        <el-descriptions-item label="点赞数">{{ likeCount }}</el-descriptions-item>
        <el-descriptions-item label="点踩数">{{ dislikeCount }}</el-descriptions-item>
      </el-descriptions>

      <!-- 管理员视图：显示学校与用户概况 -->
      <el-descriptions v-else :column="2" border>
        <el-descriptions-item label="角色">管理员</el-descriptions-item>
        <el-descriptions-item label="所属学校">
          {{ adminStats.schoolName || '未设置' }}
        </el-descriptions-item>
        <el-descriptions-item label="学校代码">
          {{ adminStats.schoolCode || '-' }}
        </el-descriptions-item>
        <el-descriptions-item label="每日评分上限">
          {{ adminStats.dailyLimit || '未配置' }}
        </el-descriptions-item>
        <el-descriptions-item label="老师数量">
          {{ adminStats.teacherCount }}
        </el-descriptions-item>
        <el-descriptions-item label="待审批学生">
          {{ adminStats.pendingUserCount }}
        </el-descriptions-item>
        <el-descriptions-item label="已通过学生">
          {{ adminStats.approvedUserCount }}
        </el-descriptions-item>
        <el-descriptions-item label="已拒绝学生">
          {{ adminStats.rejectedUserCount }}
        </el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 学生：我的评分列表 -->
    <el-card v-if="!isAdmin" shadow="hover" class="profile-section">
      <template #header>我的评分</template>
      <el-empty v-if="userRatings.length === 0" description="暂无评分" />
      <div v-else class="ratings-list">
        <el-card
          v-for="rating in userRatings"
          :key="rating.id"
          shadow="never"
          class="rating-card"
        >
          <div class="rating-row">
            <div class="hex-badge small" :class="rating.tier.toLowerCase()">
              <span>{{ rating.tier }}</span>
            </div>
            <div class="rating-meta">
              <div class="teacher-name">{{ getTeacherName(rating.teacherId) }}</div>
              <div class="date">{{ formatDate(rating.createdAt) }}</div>
            </div>
            <div class="votes">
              👍 {{ rating.likes || 0 }} / 👎 {{ rating.dislikes || 0 }}
            </div>
          </div>
          <div class="reason">
            <el-tag
              v-if="rating.invalid"
              type="danger"
              size="small"
              effect="plain"
              class="invalid-tag"
            >
              已失效（踩多于赞）
            </el-tag>
            <span>{{ rating.reason }}</span>
          </div>
          <div class="rating-actions">
            <el-popconfirm
              title="确定删除这条评分吗？"
              confirm-button-text="删除"
              cancel-button-text="取消"
              icon="el-icon-warning"
              @confirm="deleteRating(rating)"
            >
              <template #reference>
                <el-button type="danger" size="small" plain>删除</el-button>
              </template>
            </el-popconfirm>
          </div>
        </el-card>
      </div>
    </el-card>

    <!-- 管理员：简单提示卡片 -->
    <el-card v-else shadow="hover" class="profile-section">
      <template #header>管理员个人中心</template>
      <p>这里汇总了您所在学校的基本情况，详细管理请前往「管理员」面板。</p>
    </el-card>

    <!-- 修改密码弹窗 -->
    <el-dialog
      v-model="changePwdVisible"
      title="修改密码"
      width="400px"
      :close-on-click-modal="false"
    >
      <el-form :model="changePwdForm" label-width="90px">
        <el-form-item label="原密码">
          <el-input v-model="changePwdForm.oldPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="changePwdForm.newPassword" type="password" show-password />
        </el-form-item>
        <el-form-item label="确认新密码">
          <el-input v-model="changePwdForm.confirmPassword" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="changePwdVisible = false">取 消</el-button>
        <el-button type="primary" :loading="changePwdLoading" @click="submitChangePwd">
          确 认
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { api } from '../api'
import { ElMessage } from 'element-plus'

export default {
  name: 'Profile',
  data() {
    return {
      user: null,
      ratings: [],
      teachers: [],
      quotaLimit: 0,
      quotaUsed: 0,
      quotaRemaining: 0,
      quotaTier: null,  // 按等级分组的额度信息
      isAdmin: false,
      adminStats: {
        schoolName: '',
        schoolCode: '',
        dailyLimit: 0,
        teacherCount: 0,
        pendingUserCount: 0,
        approvedUserCount: 0,
        rejectedUserCount: 0
      },
      changePwdVisible: false,
      changePwdLoading: false,
      changePwdForm: {
        oldPassword: '',
        newPassword: '',
        confirmPassword: ''
      }
    }
  },
  computed: {
    userRatings() {
      // 已经从后端拿的是「我的评分」，这里直接全部展示即可
      return this.ratings
    },
    likeCount() {
      return this.userRatings.reduce((sum, r) => sum + (r.likes || 0), 0)
    },
    dislikeCount() {
      return this.userRatings.reduce((sum, r) => sum + (r.dislikes || 0), 0)
    }
  },
  mounted() {
    this.isAdmin = localStorage.getItem('isAdmin') === '1'
    this.loadData()
  },
  methods: {
    async loadData() {
      try {
        // 通用：当前用户 & 老师列表
        const [user, teachers] = await Promise.all([
          api.me(),
          api.getTeachers()
        ])
        this.user = user
        this.teachers = teachers.map(t => ({ ...t, id: t.teacher_id || t.id }))

        if (!this.isAdmin) {
          // 学生端：我的评分 + 今日额度
          const [ratings, quota] = await Promise.all([
            api.getMyRatings(),
            api.getQuota()
          ])
          this.ratings = ratings.map(r => ({
            ...r,
            id: r.rating_id || r.id,
            teacherId: r.teacher_id || r.teacher,
            createdAt: r.created_at || r.createdAt,
            invalid: (r.dislikes || 0) > (r.likes || 0)
          }))
          // 新版本：按等级分组
          if (quota.T1 && quota.T2 && quota.T3) {
            this.quotaTier = {
              T1: quota.T1,
              T2: quota.T2,
              T3: quota.T3
            }
          }
          // 兼容旧版本
          this.quotaLimit = quota.limit || 0
          this.quotaUsed = quota.used || 0
          this.quotaRemaining = quota.remaining || 0
        } else {
          // 管理员端：学校与用户/老师统计
          const [schools, allTeachers, pending, approved, rejected] = await Promise.all([
            api.getSchools(),
            api.getTeachers(),
            api.getPendingUsers(),
            api.getApprovedUsers(),
            api.getRejectedUsers()
          ])
          const storedSchoolCode = localStorage.getItem('adminSchoolCode') || ''
          const schoolObj =
            schools.find(s => (s.id === user.school || s.school_id === user.school)) ||
            schools.find(s => s.school_code === storedSchoolCode) ||
            schools[0] ||
            null
          const schoolId = schoolObj ? (schoolObj.id || schoolObj.school_id) : null

          this.adminStats.schoolName = schoolObj ? (schoolObj.school_name || '') : ''
          this.adminStats.schoolCode = schoolObj ? (schoolObj.school_code || '') : storedSchoolCode
          this.adminStats.dailyLimit = schoolObj ? (schoolObj.daily_rating_limit || 0) : 0
          this.adminStats.teacherCount = allTeachers.filter(t => {
            const tSchoolId = t.school || t.school_id
            const tSchoolCode = t.school_code
            return (schoolId && tSchoolId === schoolId) || (tSchoolCode && tSchoolCode === this.adminStats.schoolCode)
          }).length
          this.adminStats.pendingUserCount = pending.length
          this.adminStats.approvedUserCount = approved.length
          this.adminStats.rejectedUserCount = rejected.length
        }
      } catch (err) {
        ElMessage.error(err.message || '数据加载失败')
      }
    },
    logout() {
      localStorage.removeItem('authToken')
      this.$router.push('/login')
    },
    goHome() {
      this.$router.push('/')
    },
    getTeacherName(id) {
      const t = this.teachers.find(x => (x.id === id || x.teacher_id === id))
      return t ? t.name : '未知老师'
    },
    formatDate(dateString) {
      return new Date(dateString).toLocaleString()
    },
    openChangePwd() {
      this.changePwdVisible = true
      this.changePwdForm.oldPassword = ''
      this.changePwdForm.newPassword = ''
      this.changePwdForm.confirmPassword = ''
    },
    async submitChangePwd() {
      if (!this.changePwdForm.oldPassword || !this.changePwdForm.newPassword) {
        ElMessage.warning('请输入完整密码信息')
        return
      }
      if (this.changePwdForm.newPassword !== this.changePwdForm.confirmPassword) {
        ElMessage.warning('两次输入的新密码不一致')
        return
      }
      if (this.changePwdForm.newPassword.length < 6) {
        ElMessage.warning('新密码长度至少 6 位')
        return
      }
      this.changePwdLoading = true
      try {
        await api.changePassword(this.changePwdForm.oldPassword, this.changePwdForm.newPassword)
        ElMessage.success('密码修改成功，请妥善保管新密码')
        this.changePwdVisible = false
      } catch (err) {
        ElMessage.error(err.message || '密码修改失败')
      } finally {
        this.changePwdLoading = false
      }
    },
    async deleteRating(rating) {
      try {
        await api.deleteRating(rating.id)
        this.ratings = this.ratings.filter(r => r.id !== rating.id)
        ElMessage.success('已删除该评分')
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    }
  }
}
</script>

<style scoped>
.profile {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.profile-header .subtitle {
  color: var(--text-secondary);
}

.actions {
  display: flex;
  gap: 10px;
}

.invalid-tag {
  margin-right: 8px;
}

.rating-actions {
  margin-top: 8px;
  text-align: right;
}

.profile-section .rating-card {
  margin-bottom: 12px;
  border: 1px solid var(--border-color);
}

.ratings-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.rating-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.hex-badge.small {
  width: 44px;
  height: 36px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

.hex-badge.small::before,
.hex-badge.small::after {
  content: '';
  position: absolute;
  width: 0;
  border-left: 22px solid transparent;
  border-right: 22px solid transparent;
}

.hex-badge.small::before {
  bottom: 100%;
  border-bottom: 10px solid;
}

.hex-badge.small::after {
  top: 100%;
  border-top: 10px solid;
}

.hex-badge.small.t1 {
  background-color: #5a8fa3;
  color: white;
}

.hex-badge.small.t1::before {
  border-bottom-color: #5a8fa3;
}

.hex-badge.small.t1::after {
  border-top-color: #5a8fa3;
}

.hex-badge.small.t2 {
  background-color: #7aa9c0;
  color: white;
}

.hex-badge.small.t2::before {
  border-bottom-color: #7aa9c0;
}

.hex-badge.small.t2::after {
  border-top-color: #7aa9c0;
}

.hex-badge.small.t3 {
  background-color: #c8b8d1;
  color: white;
}

.hex-badge.small.t3::before {
  border-bottom-color: #c8b8d1;
}

.hex-badge.small.t3::after {
  border-top-color: #c8b8d1;
}

.hex-badge.small span {
  position: relative;
  z-index: 1;
  font-weight: 600;
  font-size: 0.8rem;
}

.rating-meta .teacher-name {
  font-weight: 600;
}

.rating-meta .date {
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.reason {
  margin-top: 6px;
  color: var(--text-primary);
}
</style>

