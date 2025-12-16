<template>
  <div class="ranking">
    <el-card class="page-header-card" shadow="never">
      <template #header>
    <div class="page-header">
      <h2>选择你要处分的老师</h2>
          <el-tag type="info" size="large">
            <el-icon><Clock /></el-icon>
            <span v-if="!isAdmin">
              <span v-if="quotaTier">
                今日额度：T1 {{ quotaTier.T1.used }}/{{ quotaTier.T1.limit }}，
                T2 {{ quotaTier.T2.used }}/{{ quotaTier.T2.limit }}，
                T3 {{ quotaTier.T3.used }}/{{ quotaTier.T3.limit }}
              </span>
              <span v-else>
                今日额度：{{ quotaUsed }}/{{ quotaLimit }}，剩余 {{ quotaRemaining }}
              </span>
            </span>
            <span v-else>
              管理员视图
            </span>
          </el-tag>
        </div>
      </template>
      <!-- 使用说明 - 可展开/收起 -->
      <div class="usage-guide-container">
        <div class="usage-guide-toggle" @click="showUsageGuide = !showUsageGuide">
          <el-icon :class="{ 'rotate-icon': showUsageGuide }">
            <ArrowDown />
          </el-icon>
          <span style="margin-left: 8px; font-weight: 500; cursor: pointer;">如何使用？</span>
        </div>
        <el-collapse-transition>
          <div v-show="showUsageGuide" class="usage-guide-content">
            <div class="usage-guide">
              <div class="guide-section">
                <p class="guide-section-title">📋 基本规则</p>
                <ul class="guide-list">
                  <li>每个等级（<strong>T1/T2/T3</strong>）每天有评分次数限制</li>
                  <li>评分理由至少需要<strong>4个字</strong>，最多<strong>50字</strong></li>
                  <li>请<strong>客观、真实</strong>地表达您的评价</li>
                  <li>每个老师每天只能评分<strong>一次</strong></li>
                </ul>
              </div>
              <el-divider style="margin: 16px 0;" />
              <div class="guide-section">
                <p class="guide-section-title">💬 社区互动</p>
                <ul class="guide-list">
                  <li>
                    <span style="font-size: 1.2em;">👍</span> <strong>点赞</strong>：支持您认为有价值的评论，让它们<strong style="color: var(--el-color-success);">优先展示</strong>
                  </li>
                  <li>
                    <span style="font-size: 1.2em;">👎</span> <strong>点踩</strong>：对恶意或不正当的评论点踩，当踩数超过赞数时，该评论将<strong style="color: var(--el-color-danger);">自动失效</strong>
                  </li>
                </ul>
              </div>
              <el-alert
                type="warning"
                :closable="false"
                style="margin-top: 16px;"
              >
                <template #title>
                  <span style="font-size: 0.9rem;">
                    💡 您的点赞和点踩有助于维护社区质量，让优质评论得到展示，让不当评论失效
                  </span>
                </template>
              </el-alert>
              <div style="text-align: right; margin-top: 16px;">
                <el-button type="text" size="small" @click="showUsageGuide = false">
                  <el-icon><ArrowUp /></el-icon>
                  收起
                </el-button>
              </div>
            </div>
          </div>
        </el-collapse-transition>
      </div>
      <div class="filter-section">
      <el-button-group class="time-filter">
        <el-button
          v-for="filter in timeFilters"
          :key="filter.value"
          :type="selectedTimeRange === filter.value ? 'primary' : 'default'"
          @click="selectedTimeRange = filter.value"
        >
          {{ filter.label }}
        </el-button>
      </el-button-group>
        <div class="search-box">
          <el-input
            v-model="searchKeyword"
            placeholder="输入姓名关键词搜索..."
            clearable
            style="max-width: 900px; width: 120%;"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
        </div>
      </div>
    </el-card>

    <el-skeleton :loading="loading" :rows="5" animated>
      <template #default>
        <el-empty v-if="filteredRankedTeachers.length === 0 && !searchKeyword" description="暂无排名数据" />
        <el-empty v-else-if="filteredRankedTeachers.length === 0 && searchKeyword" description="未找到匹配的老师" />
    <div v-else class="ranking-list">
          <el-card
        v-for="(teacher, index) in filteredRankedTeachers"
        :key="teacher.id"
        class="ranking-item"
            shadow="hover"
        @click="goToDetail(teacher.id)"
      >
            <div class="ranking-content">
        <div class="rank-number">
                <el-tag
                  :type="getRankTagType(teacher.rank - 1)"
                  size="large"
                  effect="dark"
                  class="rank-badge"
                >
            {{ teacher.rank }}
                </el-tag>
        </div>
        <div class="teacher-main">
          <div class="teacher-header">
            <h3>{{ teacher.name }}</h3>
                  <el-tag size="small" type="info">{{ teacher.department_name || teacher.department }}</el-tag>
          </div>
          <div class="tier-badges">
            <div class="tier-badge-container">
              <div class="hex-badge tier1">
                <span>Tier1</span>
              </div>
              <span class="tier-count">{{ teacher.T1 || 0 }} 次</span>
            </div>
            <div class="tier-badge-container">
              <div class="hex-badge tier2">
                <span>Tier2</span>
              </div>
              <span class="tier-count">{{ teacher.T2 || 0 }} 次</span>
            </div>
            <div class="tier-badge-container">
              <div class="hex-badge tier3">
                <span>Tier3</span>
              </div>
              <span class="tier-count">{{ teacher.T3 || 0 }} 次</span>
            </div>
          </div>
                <el-divider style="margin: 16px 0;" />
          <div class="teacher-footer">
            <div class="featured-comments">
              <span class="featured-label">
                <el-icon><Star /></el-icon>
                精选评论：
              </span>
              <div class="comment-scroll">
                <el-empty v-if="getFeaturedComments(teacher.id).length === 0" description="暂无精选评论" :image-size="60" />
                <div v-else class="comment-carousel" :key="teacher.id">
                  <transition name="fade" mode="out-in">
                    <div
                      :key="currentCommentIndex[teacher.id] || 0"
                      class="comment-item"
                    >
                      <div class="comment-tier">
                        <el-tag :type="currentComment(teacher.id)?.tier === 'T3' ? 'danger' : currentComment(teacher.id)?.tier === 'T2' ? 'warning' : 'info'" size="small">
                          {{ currentComment(teacher.id)?.tier }}
                        </el-tag>
                      </div>
                      <div class="comment-content">
                        <div class="comment-text">{{ currentComment(teacher.id)?.reason }}</div>
                        <div class="comment-meta">
                          <span class="comment-likes">👍 {{ currentComment(teacher.id)?.likes || 0 }}</span>
                          <span class="comment-date">{{ formatDateShort(currentComment(teacher.id)?.createdAt) }}</span>
                        </div>
                      </div>
                    </div>
                  </transition>
                </div>
              </div>
            </div>
            <div class="total-score">
                    <el-tag type="success" size="large" effect="dark">
              总分：<strong>{{ teacher.totalScore }}</strong>
                    </el-tag>
            </div>
          </div>
          <div class="action-buttons">
        <el-button 
          v-if="!isAdmin"
          type="primary" 
          size="small"
          @click.stop="openRatingModal(teacher)"
        >
          评分
        </el-button>
            <el-button 
              type="default" 
              size="small"
              @click.stop="goToDetail(teacher.id)"
            >
              查看详情
            </el-button>
          </div>
        </div>
      </div>
          </el-card>
    </div>
      </template>
    </el-skeleton>

    <el-dialog
      v-model="showRatingModal"
      :title="`为 ${selectedTeacher?.name} 评分`"
      width="600px"
      :close-on-click-modal="false"
    >
      <div class="rating-dialog">
        <div class="tier-selector">
          <el-button
              v-for="tier in tiers"
              :key="tier"
            :type="selectedTier === tier ? 'primary' : 'default'"
            :class="[tier.toLowerCase(), { 'active-tier': selectedTier === tier }]"
            size="large"
              @click="selectedTier = tier"
            style="flex: 1; height: 80px; font-size: 24px; font-weight: bold;"
            >
              {{ tier }}
          </el-button>
          </div>
        <el-divider />
          <div class="reason-input">
          <el-form-item label="评分理由" required>
            <el-input
              v-model="reason"
              type="textarea"
              :rows="4"
              placeholder="请详细说明评分理由，至少4字，最多50字..."
              :maxlength="50"
              show-word-limit
            />
          </el-form-item>
          <el-alert
            v-if="reason.length > 0 && reason.length < 4"
            title="评分理由至少需要4个字"
            type="warning"
            :closable="false"
            show-icon
          />
        </div>
      </div>
      <template #footer>
        <span class="dialog-footer">
          <el-button @click="closeModal">取消</el-button>
          <el-button type="primary" :disabled="!canSubmit || submitting" :loading="submitting" @click="submitRating">
            提交评分
          </el-button>
        </span>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ranking } from '../utils/ranking'
import { Search, Clock, Star } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { api } from '../api'

export default {
  name: 'Ranking',
  components: {
    Search,
    Clock,
    Star
  },
  data() {
    return {
      teachers: [],
      ratings: [],
      selectedTimeRange: 'all',
      searchKeyword: '',
      timeFilters: [
        { label: '当天', value: 'today' },
        { label: '当月', value: 'month' },
        { label: '当学期', value: 'semester' },
        { label: '当学年', value: 'year' },
        { label: '历史总排名', value: 'all' }
      ],
      loading: false,
      showRatingModal: false,
      selectedTeacher: null,
      selectedTier: null,
      reason: '',
      tiers: ['T1', 'T2', 'T3'],
      isAdmin: localStorage.getItem('isAdmin') === '1',
      quotaLimit: 0,
      quotaUsed: 0,
      quotaRemaining: 0,
      quotaTier: null,  // 按等级分组的额度信息
      currentCommentIndex: {},  // 每个老师当前显示的评论索引
      commentTimers: {},  // 每个老师的滚动定时器
      submitting: false,  // 提交中状态，防止重复提交
      showUsageGuide: false  // 是否显示使用说明
    }
  },
  computed: {
    rankedTeachers() {
      const filteredRatings = ranking.filterByTimeRange(this.ratings, this.selectedTimeRange)
      
      const teacherStats = this.teachers.map(teacher => {
        const stats = ranking.calculateTeacherStats(teacher.id, filteredRatings)
        return {
          ...teacher,
          ...stats
        }
      })

      const sorted = teacherStats
        .sort((a, b) => {
          if (b.totalScore !== a.totalScore) {
            return b.totalScore - a.totalScore
          }
          return b.count - a.count
        })
      
      // 为每个老师添加原始排名（即便 0 评分也展示）
      return sorted.map((teacher, index) => ({
        ...teacher,
        rank: index + 1
      }))
    },
    filteredRankedTeachers() {
      if (!this.searchKeyword.trim()) {
        return this.rankedTeachers
      }
      const keyword = this.searchKeyword.trim().toLowerCase()
      return this.rankedTeachers.filter(teacher => 
        teacher.name.toLowerCase().includes(keyword)
      )
    },
    canSubmit() {
      const basic =
        this.selectedTier && this.reason.length >= 4 && this.reason.length <= 50
      // 有额度信息时，还要校验对应等级的剩余次数
      if (this.quotaTier && this.selectedTier) {
        const tierQuota = this.quotaTier[this.selectedTier]
        return basic && tierQuota && tierQuota.remaining > 0
      }
      // 兼容旧版本
      if (this.quotaLimit) {
        return basic && this.quotaRemaining > 0
      }
      return basic
    }
  },
  watch: {
    selectedTimeRange() {
      this.loadData()
    }
  },
  mounted() {
    this.loadData()
  },
  beforeUnmount() {
    // 清理所有定时器
    Object.keys(this.commentTimers).forEach(teacherId => {
      this.stopCommentCarousel(teacherId)
    })
  },
  methods: {
    async loadData() {
      this.loading = true
      try {
        const basePromises = [
          api.getTeachers(),
          api.getRatings()
        ]
        const promises = this.isAdmin ? basePromises : [...basePromises, api.getQuota()]
        const [teachers, ratings, quota] = await Promise.all(promises)

        this.teachers = teachers.map(t => ({ ...t, id: t.teacher_id || t.id }))
        this.ratings = ratings.map(r => ({
          ...r,
          id: r.rating_id || r.id,
          teacherId: r.teacher_id || r.teacher,
          createdAt: r.created_at || r.createdAt,
          invalid: (r.dislikes || 0) > (r.likes || 0)
        }))

        if (!this.isAdmin && quota) {
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
          this.quotaLimit = 0
          this.quotaUsed = 0
          this.quotaRemaining = 0
          this.quotaTier = null
        }
        
        // 启动精选评论自动滚动
        this.$nextTick(() => {
          this.teachers.forEach(teacher => {
            const teacherId = teacher.id
            this.startCommentCarousel(teacherId)
          })
        })
      } catch (err) {
        ElMessage.error(err.message || '数据加载失败')
      } finally {
        this.loading = false
      }
    },
    getRankClass(index) {
      if (index === 0) return 'gold'
      if (index === 1) return 'silver'
      if (index === 2) return 'bronze'
      return ''
    },
    getRankTagType(index) {
      if (index === 0) return 'warning'
      if (index === 1) return 'info'
      if (index === 2) return ''
      return 'default'
    },
    getFeaturedComments(teacherId) {
      const filteredRatings = ranking.filterByTimeRange(this.ratings, this.selectedTimeRange)
      const teacherRatings = filteredRatings
        .filter(r => (r.teacherId || r.teacher) === teacherId)
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
    currentComment(teacherId) {
      const comments = this.getFeaturedComments(teacherId)
      if (comments.length === 0) return null
      const index = this.currentCommentIndex[teacherId] || 0
      return comments[index % comments.length]
    },
    startCommentCarousel(teacherId) {
      // 清除旧的定时器
      if (this.commentTimers[teacherId]) {
        clearInterval(this.commentTimers[teacherId])
      }
      
      const comments = this.getFeaturedComments(teacherId)
      if (comments.length <= 1) {
        // 如果只有1个或0个评论，不需要滚动
        this.currentCommentIndex[teacherId] = 0
        return
      }
      
      // 初始化索引
      if (this.currentCommentIndex[teacherId] === undefined) {
        this.currentCommentIndex[teacherId] = 0
      }
      
      // 每3秒切换一次
      this.commentTimers[teacherId] = setInterval(() => {
        const comments = this.getFeaturedComments(teacherId)
        if (comments.length > 0) {
          this.currentCommentIndex[teacherId] = (this.currentCommentIndex[teacherId] + 1) % comments.length
        }
      }, 3000)
    },
    stopCommentCarousel(teacherId) {
      if (this.commentTimers[teacherId]) {
        clearInterval(this.commentTimers[teacherId])
        delete this.commentTimers[teacherId]
      }
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
    goToDetail(teacherId) {
      this.$router.push(`/teacher/${teacherId}`)
    },
    openRatingModal(teacher) {
      if (this.isAdmin) {
        ElMessage.info('管理员不支持评分')
        return
      }
      // 检查额度（如果有按等级分组的额度信息，则检查对应等级）
      if (this.quotaTier) {
        // 暂时不在这里检查，在提交时检查对应等级
      } else if (this.quotaLimit && this.quotaRemaining <= 0) {
        ElMessage.warning('今日额度已用完，无法继续评分')
        return
      }
      this.selectedTeacher = teacher
      this.selectedTier = null
      this.reason = ''
      this.showRatingModal = true
    },
    closeModal() {
      this.showRatingModal = false
      this.selectedTeacher = null
      this.selectedTier = null
      this.reason = ''
    },
    submitRating() {
      if (!this.canSubmit || this.submitting) return
      
      // 检查对应等级的剩余额度
      if (this.quotaTier && this.selectedTier) {
        const tierQuota = this.quotaTier[this.selectedTier]
        if (!tierQuota || tierQuota.remaining <= 0) {
          ElMessage.warning(`今日${this.selectedTier}等级评分次数已达上限（${tierQuota?.limit || 0}次）`)
          return
        }
      }

      this.submitting = true
      api.postRating({
        teacher: this.selectedTeacher.teacher_id || this.selectedTeacher.id,
        tier: this.selectedTier,
        reason: this.reason
      })
        .then(() => {
          ElMessage.success({
            message: `评分提交成功！您为 ${this.selectedTeacher.name} 给予了 ${this.selectedTier} 评价`,
            duration: 3000
          })
          this.loadData()
          this.closeModal()
        })
        .catch(err => {
          ElMessage.error(err.message || '提交失败')
        })
        .finally(() => {
          this.submitting = false
        })
    }
  }
}
</script>

<style scoped>
.ranking {
  padding: 0;
}

.page-header-card {
  margin-bottom: 24px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.page-header h2 {
  font-size: 1.75rem;
  margin: 0;
  color: var(--text-primary);
  font-weight: 700;
  letter-spacing: -0.5px;
}

.filter-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.time-filter {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.search-box {
  display: flex;
  justify-content: flex-end;
}

.ranking-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.ranking-item {
  cursor: pointer;
  transition: all 0.3s ease;
  border: 1px solid var(--border-color);
  background: var(--card-bg);
}

.ranking-item:hover {
  transform: translateX(2px);
  box-shadow: var(--shadow-hover);
  border-color: var(--primary-light);
}

.ranking-content {
  display: flex;
  gap: 20px;
}

.rank-number {
  display: flex;
  align-items: flex-start;
  min-width: 60px;
}

.rank-badge {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
  font-weight: 700;
}

.teacher-main {
  flex: 1;
}

.teacher-header {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

.teacher-header h3 {
  font-size: 1.25rem;
  color: var(--text-primary);
  margin: 0;
  font-weight: 600;
}

.tier-badges {
  display: flex;
  gap: 1.5rem;
  margin-bottom: 1rem;
  flex-wrap: wrap;
}

.tier-badge-container {
  display: flex;
  align-items: center;
  gap: 0.75rem;
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

.tier-count {
  color: var(--text-primary);
  font-weight: 500;
  font-size: 0.95rem;
  white-space: nowrap;
}

.teacher-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.featured-comments {
  flex: 1;
  min-width: 0;
}

.featured-label {
  color: var(--text-secondary);
  font-size: 0.9rem;
  font-weight: 500;
  display: flex;
  align-items: center;
  gap: 4px;
  margin-bottom: 8px;
}

.comment-scroll {
  min-height: 80px;
  position: relative;
}

.comment-carousel {
  position: relative;
  min-height: 80px;
}

.comment-item {
  display: flex;
  gap: 8px;
  padding: 8px;
  background: var(--el-bg-color-page);
  border-radius: 4px;
  border: 1px solid var(--el-border-color-light);
  transition: all 0.2s;
  position: absolute;
  width: 100%;
  top: 0;
  left: 0;
}

.comment-item:hover {
  border-color: var(--el-border-color);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

.usage-guide-container {
  margin-bottom: 20px;
  border: 1px solid var(--el-border-color-light);
  border-radius: 4px;
  background: var(--el-bg-color-page);
  overflow: hidden;
}

.usage-guide-toggle {
  display: flex;
  align-items: center;
  padding: 12px 16px;
  cursor: pointer;
  user-select: none;
  transition: background-color 0.2s;
  color: var(--el-color-primary);
  font-size: 0.95rem;
}

.usage-guide-toggle:hover {
  background-color: var(--el-fill-color-light);
}

.usage-guide-toggle .el-icon {
  transition: transform 0.3s ease;
}

.rotate-icon {
  transform: rotate(180deg);
}

.usage-guide-content {
  padding: 0 16px 16px 16px;
  border-top: 1px solid var(--el-border-color-lighter);
}

.usage-guide {
  line-height: 1.8;
  padding-top: 16px;
}

.guide-section {
  margin-bottom: 0;
}

.guide-section-title {
  font-size: 0.95rem;
  font-weight: 600;
  margin: 0 0 10px 0;
  color: var(--el-text-color-primary);
}

.guide-list {
  margin: 0;
  padding-left: 24px;
  font-size: 0.9rem;
  color: var(--el-text-color-regular);
}

.guide-list li {
  margin: 8px 0;
  line-height: 1.7;
}

.comment-tier {
  flex-shrink: 0;
}

.comment-content {
  flex: 1;
  min-width: 0;
}

.comment-text {
  font-size: 0.85rem;
  color: var(--el-text-color-primary);
  margin-bottom: 4px;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  line-height: 1.4;
}

.comment-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.75rem;
  color: var(--el-text-color-secondary);
}

.comment-likes {
  color: var(--el-color-success);
  font-weight: 500;
}

.total-score strong {
  font-size: 1.1rem;
}

.action-buttons {
  display: flex;
  gap: 8px;
  margin-top: 16px;
  justify-content: flex-end;
}

.rating-dialog {
  padding: 10px 0;
}

.tier-selector {
  display: flex;
  gap: 12px;
  margin-bottom: 20px;
}

.tier-selector .el-button.t1 {
  border-color: #4a7c8f;
  color: #4a7c8f;
  font-weight: 600;
}

.tier-selector .el-button.t2 {
  border-color: #6b9fb5;
  color: #6b9fb5;
  font-weight: 600;
}

.tier-selector .el-button.t3 {
  border-color: #b8a5c4;
  color: #b8a5c4;
  font-weight: 600;
}

.tier-selector .el-button.active-tier.t1 {
  background: linear-gradient(135deg, #4a7c8f, #5a8fa3);
  border-color: #4a7c8f;
  color: white;
}

.tier-selector .el-button.active-tier.t2 {
  background: linear-gradient(135deg, #6b9fb5, #7aa9c0);
  border-color: #6b9fb5;
  color: white;
}

.tier-selector .el-button.active-tier.t3 {
  background: linear-gradient(135deg, #b8a5c4, #c8b8d1);
  border-color: #b8a5c4;
  color: white;
}

.reason-input {
  margin-top: 20px;
}
</style>
