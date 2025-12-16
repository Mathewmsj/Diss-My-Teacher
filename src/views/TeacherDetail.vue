<template>
  <div class="teacher-detail">
    <el-skeleton :loading="loading" :rows="8" animated>
      <template #default>
        <el-empty v-if="!teacher" description="老师不存在" />
    <div v-else>
          <el-button
            class="back-btn"
            type="default"
            :icon="ArrowLeft"
            @click="$router.back()"
          >
            返回
          </el-button>

          <el-card class="teacher-header-card" shadow="never">
            <div class="teacher-header-content">
              <div class="teacher-basic-info">
        <h2>{{ teacher.name }}</h2>
                <el-tag size="large" type="info">{{ teacher.department_name || teacher.department }}</el-tag>
          </div>
              <el-row :gutter="20" class="teacher-overview">
                <el-col :span="8">
                  <el-statistic title="总分" :value="stats.totalScore" />
                </el-col>
                <el-col :span="8">
                  <el-statistic title="总评分" :value="stats.count" />
                </el-col>
                <el-col :span="8">
                  <el-statistic title="平均分" :value="getAverageScore()" :precision="1" />
                </el-col>
              </el-row>
          </div>
          </el-card>

          <el-card class="tier-summary-card" shadow="hover">
            <template #header>
              <span>Tier统计</span>
            </template>
      <div class="tier-summary">
        <div class="tier-badge-container">
          <div class="hex-badge tier1">
            <span>Tier1</span>
          </div>
          <span class="tier-count">{{ stats.T1 || 0 }} 次</span>
        </div>
        <div class="tier-badge-container">
          <div class="hex-badge tier2">
            <span>Tier2</span>
          </div>
          <span class="tier-count">{{ stats.T2 || 0 }} 次</span>
        </div>
        <div class="tier-badge-container">
          <div class="hex-badge tier3">
            <span>Tier3</span>
          </div>
          <span class="tier-count">{{ stats.T3 || 0 }} 次</span>
        </div>
      </div>
          </el-card>

          <el-card class="featured-comments-section" shadow="hover">
            <template #header>
              <span>
                <el-icon><Star /></el-icon>
                精选评论
              </span>
            </template>
            <div class="comment-scroll">
              <el-empty v-if="featuredComments.length === 0" description="暂无精选评论" :image-size="60" />
              <div v-else class="comment-carousel">
                <transition name="fade" mode="out-in">
                  <div
                    :key="currentCommentIndex"
                    class="comment-item"
                  >
                    <div class="comment-tier">
                      <el-tag :type="currentComment?.tier === 'T3' ? 'danger' : currentComment?.tier === 'T2' ? 'warning' : 'info'" size="small">
                        {{ currentComment?.tier }}
                      </el-tag>
                    </div>
                    <div class="comment-content">
                      <div class="comment-text">{{ currentComment?.reason }}</div>
                      <div class="comment-meta">
                        <span class="comment-likes">👍 {{ currentComment?.likes || 0 }}</span>
                        <span class="comment-date">{{ formatDateShort(currentComment?.createdAt) }}</span>
                      </div>
                    </div>
                  </div>
                </transition>
              </div>
            </div>
          </el-card>

          <el-card class="ratings-section" shadow="hover">
            <template #header>
              <span>所有评分 ({{ sortedRatings.length }})</span>
            </template>
            <el-empty v-if="sortedRatings.length === 0" description="暂无评分" />
            <div v-else class="ratings-list">
              <el-card
            v-for="rating in sortedRatings"
            :key="rating.id"
            class="rating-item"
                shadow="never"
                :body-style="{ padding: '16px' }"
          >
            <div class="rating-header">
              <div class="rating-tier">
                <div class="hex-badge-small" :class="rating.tier.toLowerCase()">
                  <span>{{ rating.tier }}</span>
                </div>
              </div>
                  <el-tag size="small" type="info">{{ formatDate(rating.createdAt) }}</el-tag>
            </div>
            <div class="rating-reason">
              {{ rating.reason }}
            </div>
            <div class="rating-actions">
              <div class="rating-status" v-if="rating.invalid">
                <el-tag type="danger" effect="dark" size="small">已失效（踩多于赞）</el-tag>
              </div>
              <div class="rating-votes">
                <el-button
                  :type="rating.userLiked ? 'success' : 'default'"
                  @click="toggleLike(rating)"
                >
                  👍 {{ rating.likes || 0 }}
                </el-button>
                <el-button
                  :type="rating.userDisliked ? 'warning' : 'default'"
                  @click="toggleDislike(rating)"
                >
                  👎 {{ rating.dislikes || 0 }}
                </el-button>
              </div>
                </div>
              </el-card>
            </div>
          </el-card>
        </div>
      </template>
    </el-skeleton>
  </div>
</template>

<script>
import { api } from '../api'
import { ranking } from '../utils/ranking'
import { ArrowLeft, Star } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

export default {
  name: 'TeacherDetail',
  components: {
    ArrowLeft,
    Star
  },
  data() {
    return {
      teacher: null,
      ratings: [],
      loading: true,
      currentCommentIndex: 0,
      commentTimer: null
    }
  },
  computed: {
    teacherId() {
      return parseInt(this.$route.params.id)
    },
    stats() {
      return ranking.calculateTeacherStats(this.teacherId, this.ratings, 'all')
    },
    featuredComments() {
      const teacherRatings = this.ratings
        .filter(r => (r.teacherId || r.teacher) === this.teacherId)
        .filter(r => !r.invalid) // 排除失效的评论
        .sort((a, b) => {
          // 按点赞数降序，相同点赞数按时间降序
          const likesA = a.likes || 0
          const likesB = b.likes || 0
          if (likesB !== likesA) {
            return likesB - likesA
          }
          return new Date(b.createdAt || b.created_at) - new Date(a.createdAt || a.created_at)
        })
        .slice(0, 3) // 取前3个
      return teacherRatings
    },
    currentComment() {
      if (this.featuredComments.length === 0) return null
      return this.featuredComments[this.currentCommentIndex % this.featuredComments.length]
    },
    sortedRatings() {
      return this.ratings
        .filter(r => (r.teacherId || r.teacher) === this.teacherId)
        .sort((a, b) => {
          const scoreA = (a.likes || 0) - (a.dislikes || 0)
          const scoreB = (b.likes || 0) - (b.dislikes || 0)
          if (scoreA !== scoreB) {
            return scoreB - scoreA
          }
          return new Date(b.createdAt || b.created_at) - new Date(a.createdAt || a.created_at)
        })
    }
  },
  mounted() {
    this.loadData()
  },
  beforeUnmount() {
    if (this.commentTimer) {
      clearInterval(this.commentTimer)
    }
  },
  methods: {
    async loadData() {
      this.loading = true
      try {
        const [teachers, ratings] = await Promise.all([
          api.getTeachers(),
          api.getRatings()
        ])
        const teacher = teachers.find(t => (t.teacher_id || t.id) === this.teacherId)
        this.teacher = teacher
        this.ratings = ratings.map(r => ({
          ...r,
          id: r.rating_id || r.id,
          teacherId: r.teacher_id || r.teacher,
          createdAt: r.created_at || r.createdAt,
          invalid: (r.dislikes || 0) > (r.likes || 0)
        }))
        
        // 启动精选评论自动滚动
        this.startCommentCarousel()
      } catch (err) {
        ElMessage.error(err.message || '加载失败')
      } finally {
        this.loading = false
      }
    },
    startCommentCarousel() {
      // 清除旧的定时器
      if (this.commentTimer) {
        clearInterval(this.commentTimer)
      }
      
      if (this.featuredComments.length <= 1) {
        // 如果只有1个或0个评论，不需要滚动
        this.currentCommentIndex = 0
        return
      }
      
      // 初始化索引
      this.currentCommentIndex = 0
      
      // 每3秒切换一次
      this.commentTimer = setInterval(() => {
        if (this.featuredComments.length > 0) {
          this.currentCommentIndex = (this.currentCommentIndex + 1) % this.featuredComments.length
        }
      }, 3000)
    },
    getAverageScore() {
      if (this.stats.count === 0) return 0
      return (this.stats.totalScore / this.stats.count).toFixed(1)
    },
    formatDate(dateString) {
      const date = new Date(dateString)
      const now = new Date()
      const diff = now - date
      const days = Math.floor(diff / (1000 * 60 * 60 * 24))
      
      if (days === 0) return '今天'
      if (days === 1) return '昨天'
      if (days < 7) return `${days}天前`
      
      return date.toLocaleDateString('zh-CN', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      })
    },
    formatDateShort(dateString) {
      if (!dateString) return ''
      const date = new Date(dateString)
      const now = new Date()
      const diff = now - date
      const days = Math.floor(diff / (1000 * 60 * 60 * 24))
      if (days === 0) return '今天'
      if (days === 1) return '昨天'
      if (days < 7) return `${days}天前`
      return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' })
    },
    async toggleLike(rating) {
      try {
        const updated = await api.likeRating(rating.id)
        Object.assign(rating, {
          ...rating,
          likes: updated.likes,
          dislikes: updated.dislikes,
          invalid: (updated.dislikes || 0) > (updated.likes || 0)
        })
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async toggleDislike(rating) {
      try {
        const updated = await api.dislikeRating(rating.id)
        Object.assign(rating, {
          ...rating,
          likes: updated.likes,
          dislikes: updated.dislikes,
          invalid: (updated.dislikes || 0) > (updated.likes || 0)
        })
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    }
  }
}
</script>

<style scoped>
.teacher-detail {
  padding: 0;
}

.back-btn {
  margin-bottom: 20px;
}

.teacher-header-card {
  margin-bottom: 20px;
  background: linear-gradient(135deg, #4a7c8f 0%, #5a8fa3 50%, #6b9fb5 100%);
  border: none;
}

.teacher-header-card :deep(.el-card__body) {
  color: white;
}

.teacher-header-content {
  color: white;
}

.teacher-basic-info {
  margin-bottom: 24px;
}

.teacher-basic-info h2 {
  font-size: 2rem;
  margin: 0 0 12px 0;
  color: white;
  font-weight: 700;
}

.teacher-overview {
  margin-top: 20px;
}

.teacher-overview :deep(.el-statistic__head) {
  color: rgba(255, 255, 255, 0.8);
  font-size: 0.95rem;
}

.teacher-overview :deep(.el-statistic__number) {
  color: white;
  font-size: 2rem;
  font-weight: 700;
}

.tier-summary-card {
  margin-bottom: 20px;
}

.tier-summary {
  display: flex;
  justify-content: center;
  gap: 2rem;
  flex-wrap: wrap;
}

.tier-badge-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.hex-badge {
  width: 60px;
  height: 46px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  filter: drop-shadow(0 3px 6px rgba(0, 0, 0, 0.25));
  transition: transform 0.3s;
}

.hex-badge:hover {
  transform: scale(1.05);
}

.hex-badge::before,
.hex-badge::after {
  content: '';
  position: absolute;
  width: 0;
  border-left: 30px solid transparent;
  border-right: 30px solid transparent;
}

.hex-badge::before {
  bottom: 100%;
  border-bottom: 12px solid;
}

.hex-badge::after {
  top: 100%;
  border-top: 12px solid;
}

.hex-badge.tier1 {
  background-color: #5a8fa3;
  color: white;
}

.hex-badge.tier1::before {
  border-bottom-color: #5a8fa3;
}

.hex-badge.tier1::after {
  border-top-color: #5a8fa3;
}

.hex-badge.tier2 {
  background-color: #7aa9c0;
  color: white;
}

.hex-badge.tier2::before {
  border-bottom-color: #7aa9c0;
}

.hex-badge.tier2::after {
  border-top-color: #7aa9c0;
}

.hex-badge.tier3 {
  background-color: #c8b8d1;
  color: white;
}

.hex-badge.tier3::before {
  border-bottom-color: #c8b8d1;
}

.hex-badge.tier3::after {
  border-top-color: #c8b8d1;
}

.hex-badge span {
  position: relative;
  z-index: 1;
  font-weight: 600;
  font-size: 0.8rem;
  letter-spacing: 0.3px;
}

.featured-comments-section {
  margin-bottom: 20px;
}

.featured-comments-section .el-card__header {
  display: flex;
  align-items: center;
  gap: 6px;
}

.comment-scroll {
  min-height: 120px;
  position: relative;
}

.comment-carousel {
  position: relative;
  min-height: 120px;
}

.comment-item {
  display: flex;
  gap: 12px;
  padding: 12px;
  background: var(--el-bg-color-page);
  border-radius: 6px;
  border: 1px solid var(--el-border-color-light);
  transition: all 0.2s;
  position: absolute;
  width: 100%;
  top: 0;
  left: 0;
}

.comment-item:hover {
  border-color: var(--el-border-color);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.comment-tier {
  flex-shrink: 0;
}

.comment-content {
  flex: 1;
  min-width: 0;
}

.comment-text {
  font-size: 0.9rem;
  color: var(--el-text-color-primary);
  margin-bottom: 6px;
  line-height: 1.5;
}

.comment-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: var(--el-text-color-secondary);
}

.comment-likes {
  color: var(--el-color-success);
  font-weight: 500;
}

.comment-date {
  color: var(--el-text-color-placeholder);
}

.ratings-section {
  margin-bottom: 20px;
}

.ratings-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.rating-item {
  margin-bottom: 16px;
  border: 1px solid var(--border-color);
  transition: all 0.3s ease;
  background: var(--card-bg);
}

.rating-item:hover {
  border-color: var(--primary-light);
  transform: translateX(2px);
  box-shadow: var(--shadow);
}

.rating-item:last-child {
  margin-bottom: 0;
}

.rating-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.rating-tier {
  display: flex;
  align-items: center;
}

.hex-badge-small {
  width: 44px;
  height: 36px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
}

.hex-badge-small::before,
.hex-badge-small::after {
  content: '';
  position: absolute;
  width: 0;
  border-left: 22px solid transparent;
  border-right: 22px solid transparent;
}

.hex-badge-small::before {
  bottom: 100%;
  border-bottom: 10px solid;
}

.hex-badge-small::after {
  top: 100%;
  border-top: 10px solid;
}

.hex-badge-small.t1 {
  background-color: #4a7c8f;
  color: white;
}

.hex-badge-small.t1::before {
  border-bottom-color: #4a7c8f;
}

.hex-badge-small.t1::after {
  border-top-color: #4a7c8f;
}

.hex-badge-small.t2 {
  background-color: #6b9fb5;
  color: white;
}

.hex-badge-small.t2::before {
  border-bottom-color: #6b9fb5;
}

.hex-badge-small.t2::after {
  border-top-color: #6b9fb5;
}

.hex-badge-small.t3 {
  background-color: #b8a5c4;
  color: white;
}

.hex-badge-small.t3::before {
  border-bottom-color: #b8a5c4;
}

.hex-badge-small.t3::after {
  border-top-color: #b8a5c4;
}

.hex-badge-small span {
  position: relative;
  z-index: 1;
  font-weight: 600;
  font-size: 0.75rem;
}

.rating-reason {
  color: var(--text-primary);
  line-height: 1.8;
  margin-bottom: 12px;
  padding: 14px;
  background: var(--bg-color);
  border-radius: 8px;
  font-size: 0.95rem;
  border-left: 3px solid var(--primary-light);
}

.rating-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.rating-status {
  display: flex;
  align-items: center;
}
.rating-votes {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
}
</style>
