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
              <div class="teacher-actions" v-if="!isAdmin">
                <el-button type="primary" size="large" @click="openRatingModal">
                  <el-icon><Edit /></el-icon>
                  给该老师评分
                </el-button>
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
            <!-- 神评标识 -->
            <div v-if="rating.is_featured" class="featured-badge">
              <div class="featured-icon">
                <el-icon><Medal /></el-icon>
              </div>
              <span class="featured-text">神评</span>
            </div>
            
            <div class="rating-header">
              <div class="rating-tier">
                <div class="hex-badge-small" :class="rating.tier.toLowerCase()">
                  <span>{{ rating.tier }}</span>
                </div>
              </div>
              <div class="rating-meta">
                <span class="rating-time">{{ formatDate(rating.createdAt) }}</span>
                <el-tag v-if="rating.invalid" type="danger" effect="plain" size="small">已失效</el-tag>
              </div>
            </div>
            
            <div class="rating-reason">
              {{ rating.reason }}
            </div>
            
            <div class="rating-actions">
              <div class="action-group">
                <button 
                  class="action-btn" 
                  :class="{ active: rating.userLiked }"
                  @click="toggleLike(rating)"
                >
                  <el-icon><CaretTop /></el-icon>
                  <span>{{ rating.likes || 0 }}</span>
                </button>
                <button 
                  class="action-btn" 
                  :class="{ active: rating.userDisliked }"
                  @click="toggleDislike(rating)"
                >
                  <el-icon><CaretBottom /></el-icon>
                  <span>{{ rating.dislikes || 0 }}</span>
                </button>
                <button 
                  class="action-btn comment-btn"
                  @click="toggleComments(rating.id)"
                >
                  <el-icon><ChatDotRound /></el-icon>
                  <span>{{ getCommentCount(rating.id) }}</span>
                </button>
                <button
                  v-if="isAdmin"
                  class="action-btn admin-btn"
                  @click="toggleFeatured(rating)"
                >
                  <el-icon><Medal /></el-icon>
                  <span>{{ rating.is_featured ? '取消' : '神评' }}</span>
                </button>
              </div>
                </div>
                
                <!-- 评论区 - 始终显示 -->
                <div class="comments-section">
                  <el-divider style="margin: 12px 0 16px 0;" />
                  
                  <!-- 评论列表 -->
                  <div class="comments-container" v-if="getRatingComments(rating.id).length > 0">
                    <div class="comments-header">
                      <span class="comments-title">评论 {{ getCommentCount(rating.id) }}</span>
                    </div>
                    
                    <div class="comments-list">
                      <div
                        v-for="(comment, index) in getDisplayComments(rating.id)"
                        :key="comment.comment_id"
                        class="comment-item"
                      >
                        <div class="comment-avatar">
                          <el-icon size="28"><UserFilled /></el-icon>
                        </div>
                        <div class="comment-main">
                          <div class="comment-header">
                            <span class="comment-user">{{ comment.user_name || '匿名用户' }}</span>
                            <span class="comment-time">{{ formatDateShort(comment.created_at) }}</span>
                          </div>
                          <div class="comment-content">{{ comment.content }}</div>
                          <div class="comment-actions">
                            <button 
                              class="comment-action-btn" 
                              :class="{ active: comment.userLiked }"
                              @click="toggleCommentLike(comment)"
                            >
                              <el-icon><CaretTop /></el-icon>
                              <span v-if="comment.likes">{{ comment.likes }}</span>
                            </button>
                            <button 
                              class="comment-action-btn" 
                              :class="{ active: comment.userDisliked }"
                              @click="toggleCommentDislike(comment)"
                            >
                              <el-icon><CaretBottom /></el-icon>
                              <span v-if="comment.dislikes">{{ comment.dislikes }}</span>
                            </button>
                            <button 
                              class="comment-action-btn reply-btn"
                              @click="replyToComment(comment)"
                            >
                              <span>回复</span>
                              <span v-if="comment.reply_count" class="reply-count">{{ comment.reply_count }}</span>
                            </button>
                            <button
                              v-if="isSuperAdmin"
                              class="comment-action-btn delete-btn"
                              @click="deleteComment(comment)"
                            >
                              <el-icon><Delete /></el-icon>
                            </button>
                          </div>
                          
                          <!-- 回复列表 -->
                          <div v-if="comment.replies && comment.replies.length > 0" class="replies-list">
                            <div
                              v-for="reply in comment.replies"
                              :key="reply.comment_id"
                              class="reply-item"
                            >
                              <div class="reply-avatar">
                                <el-icon size="24"><UserFilled /></el-icon>
                              </div>
                              <div class="reply-main">
                                <div class="comment-header">
                                  <span class="comment-user">{{ reply.user_name || '匿名用户' }}</span>
                                  <span class="comment-time">{{ formatDateShort(reply.created_at) }}</span>
                                </div>
                                <div class="comment-content">{{ reply.content }}</div>
                                <div class="comment-actions">
                                  <button 
                                    class="comment-action-btn" 
                                    :class="{ active: reply.userLiked }"
                                    @click="toggleCommentLike(reply)"
                                  >
                                    <el-icon><CaretTop /></el-icon>
                                    <span v-if="reply.likes">{{ reply.likes }}</span>
                                  </button>
                                  <button 
                                    class="comment-action-btn" 
                                    :class="{ active: reply.userDisliked }"
                                    @click="toggleCommentDislike(reply)"
                                  >
                                    <el-icon><CaretBottom /></el-icon>
                                    <span v-if="reply.dislikes">{{ reply.dislikes }}</span>
                                  </button>
                                  <button
                                    v-if="isSuperAdmin"
                                    class="comment-action-btn delete-btn"
                                    @click="deleteComment(reply)"
                                  >
                                    <el-icon><Delete /></el-icon>
                                  </button>
                                </div>
                              </div>
                            </div>
                          </div>
                          
                          <!-- 回复输入框 -->
                          <div v-if="replyingTo === comment.comment_id" class="reply-input-box">
                            <el-input
                              v-model="replyContent"
                              type="textarea"
                              :rows="3"
                              placeholder="写下你的回复..."
                              :maxlength="300"
                              show-word-limit
                            />
                            <div class="reply-actions">
                              <el-button size="small" @click="cancelReply">取消</el-button>
                              <el-button type="primary" size="small" @click="submitReply(rating.id, comment.comment_id)" :disabled="!replyContent.trim()">
                                发表回复
                              </el-button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    
                    <!-- 查看更多评论 -->
                    <div v-if="hasMoreComments(rating.id)" class="load-more">
                      <el-button text @click="expandAllComments(rating.id)">
                        查看全部 {{ getCommentCount(rating.id) }} 条评论
                        <el-icon><ArrowDown /></el-icon>
                      </el-button>
                    </div>
                  </div>
                  
                  <!-- 发表评论 -->
                  <div class="add-comment-box" @click="focusCommentInput(rating.id)">
                    <div class="comment-avatar">
                      <el-icon size="28"><UserFilled /></el-icon>
                    </div>
                    <div class="comment-input-wrapper">
                      <el-input
                        v-if="activeCommentBox === rating.id"
                        v-model="commentInputs[rating.id]"
                        type="textarea"
                        :rows="3"
                        placeholder="写下你的评论..."
                        :maxlength="300"
                        show-word-limit
                        ref="commentInput"
                      />
                      <div v-else class="comment-placeholder">写下你的评论...</div>
                      <div v-if="activeCommentBox === rating.id" class="comment-submit-actions">
                        <el-button size="small" @click="cancelComment(rating.id)">取消</el-button>
                        <el-button 
                          type="primary" 
                          size="small" 
                          @click="submitComment(rating.id)" 
                          :disabled="!commentInputs[rating.id] || !commentInputs[rating.id].trim()"
                        >
                          发表评论
                        </el-button>
                      </div>
                    </div>
                  </div>
                </div>
              </el-card>
            </div>
          </el-card>
        </div>
      </template>
    </el-skeleton>

    <!-- 评分弹窗 -->
    <el-dialog
      v-model="showRatingModal"
      :title="`为 ${teacher?.name} 评分`"
      width="600px"
      :close-on-click-modal="false"
    >
      <div class="rating-dialog">
        <el-alert
          type="warning"
          :closable="false"
          show-icon
          style="margin-bottom: 20px;"
        >
          <template #title>
            <span style="font-size: 0.9rem;">
              ⚠️ 请客观、真实地表达您的评价，避免恶意和粗鲁的言论
            </span>
          </template>
        </el-alert>
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
import { api } from '../api'
import { ranking } from '../utils/ranking'
import { 
  ArrowLeft, Star, Edit, Medal, CaretTop, CaretBottom, 
  ChatDotRound, UserFilled, Delete, ArrowDown 
} from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'

export default {
  name: 'TeacherDetail',
  components: {
    ArrowLeft,
    Star,
    Edit,
    Medal,
    CaretTop,
    CaretBottom,
    ChatDotRound,
    UserFilled,
    Delete,
    ArrowDown
  },
  data() {
    return {
      teacher: null,
      ratings: [],
      loading: true,
      currentCommentIndex: 0,
      commentTimer: null,
      showRatingModal: false,
      selectedTier: null,
      reason: '',
      tiers: ['T1', 'T2', 'T3'],
      submitting: false,
      isAdmin: false,
      isSuperAdmin: false,
      quotaTier: null,
      comments: [],
      expandedRatings: {},
      commentInputs: {},
      activeCommentBox: null,
      replyingTo: null,
      replyContent: '',
      commentInteractions: {}
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
          // 神评优先置顶
          if (a.is_featured && !b.is_featured) return -1
          if (!a.is_featured && b.is_featured) return 1
          
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
    this.checkAuth()
    this.loadData()
  },
  beforeUnmount() {
    if (this.commentTimer) {
      clearTimeout(this.commentTimer)
    }
  },
  methods: {
    checkAuth() {
      this.isAdmin = localStorage.getItem('isAdmin') === '1'
      this.isSuperAdmin = localStorage.getItem('isSuperAdmin') === '1'
    },
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
        
        // 如果不是管理员，加载额度信息
        if (!this.isAdmin) {
          try {
            const quota = await api.getQuota()
            if (quota && quota.T1 && quota.T2 && quota.T3) {
              this.quotaTier = {
                T1: quota.T1,
                T2: quota.T2,
                T3: quota.T3
              }
            }
          } catch (err) {
            console.error('加载额度失败', err)
          }
        }
      } catch (err) {
        ElMessage.error(err.message || '加载失败')
      } finally {
        this.loading = false
      }
    },
    startCommentCarousel() {
      // 清除旧的定时器
      if (this.commentTimer) {
        clearTimeout(this.commentTimer)
      }
      
      if (this.featuredComments.length <= 1) {
        // 如果只有1个或0个评论，不需要滚动
        this.currentCommentIndex = 0
        return
      }
      
      // 初始化索引
      this.currentCommentIndex = 0
      
      // 根据当前评论长度计算显示时间（自适应）
      const getDisplayTime = (comment) => {
        if (!comment || !comment.reason) return 3000
        const textLength = comment.reason.length
        // 基础时间 3 秒，每 10 个字增加 1 秒，最多 10 秒
        const baseTime = 3000
        const extraTime = Math.min(Math.floor(textLength / 10) * 1000, 7000)
        return baseTime + extraTime
      }
      
      // 设置下一个评论的切换时间
      const scheduleNext = () => {
        if (this.featuredComments.length === 0) return
        
        const currentIndex = this.currentCommentIndex || 0
        const currentComment = this.featuredComments[currentIndex]
        const displayTime = getDisplayTime(currentComment)
        
        this.commentTimer = setTimeout(() => {
          this.currentCommentIndex = (currentIndex + 1) % this.featuredComments.length
          scheduleNext() // 递归设置下一个
        }, displayTime)
      }
      
      scheduleNext()
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
    openRatingModal() {
      if (this.isAdmin) {
        ElMessage.info('管理员不支持评分')
        return
      }
      if (this.quotaTier) {
        // 检查是否有剩余额度
        const hasQuota = Object.values(this.quotaTier).some(tier => tier.remaining > 0)
        if (!hasQuota) {
          ElMessage.warning('今日额度已用完，无法继续评分')
          return
        }
      }
      this.selectedTier = null
      this.reason = ''
      this.showRatingModal = true
    },
    closeModal() {
      this.showRatingModal = false
      this.selectedTier = null
      this.reason = ''
    },
    get canSubmit() {
      const basic = this.selectedTier && this.reason.length >= 4 && this.reason.length <= 50
      if (this.quotaTier && this.selectedTier) {
        const tierQuota = this.quotaTier[this.selectedTier]
        return basic && tierQuota && tierQuota.remaining > 0
      }
      return basic
    },
    async submitRating() {
      if (!this.canSubmit || this.submitting) return
      
      if (this.quotaTier && this.selectedTier) {
        const tierQuota = this.quotaTier[this.selectedTier]
        if (!tierQuota || tierQuota.remaining <= 0) {
          ElMessage.warning(`今日${this.selectedTier}等级评分次数已达上限（${tierQuota?.limit || 0}次）`)
          return
        }
      }

      this.submitting = true
      try {
        await api.postRating({
          teacher: this.teacher.teacher_id || this.teacher.id,
          tier: this.selectedTier,
          reason: this.reason
        })
        ElMessage.success({
          message: `评分提交成功！您为 ${this.teacher.name} 给予了 ${this.selectedTier} 评价`,
          duration: 3000
        })
        this.loadData()
        this.closeModal()
      } catch (err) {
        ElMessage.error(err.message || '提交失败')
      } finally {
        this.submitting = false
      }
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
    },
    async toggleFeatured(rating) {
      try {
        await api.setFeatured(rating.id, !rating.is_featured)
        ElMessage.success(rating.is_featured ? '已取消神评' : '已设为神评')
        this.loadData()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    toggleComments(ratingId) {
      if (!this.expandedRatings[ratingId]) {
        this.loadComments()
      }
    },
    getDisplayComments(ratingId) {
      const comments = this.getRatingComments(ratingId)
      if (this.expandedRatings[ratingId]) {
        return comments
      }
      return comments.slice(0, 3)
    },
    hasMoreComments(ratingId) {
      return this.getRatingComments(ratingId).length > 3 && !this.expandedRatings[ratingId]
    },
    expandAllComments(ratingId) {
      this.expandedRatings[ratingId] = true
    },
    focusCommentInput(ratingId) {
      this.activeCommentBox = ratingId
      if (!this.commentInputs[ratingId]) {
        this.commentInputs[ratingId] = ''
      }
      this.$nextTick(() => {
        const input = this.$refs.commentInput?.[0]
        if (input) {
          input.focus()
        }
      })
    },
    cancelComment(ratingId) {
      this.activeCommentBox = null
      this.commentInputs[ratingId] = ''
    },
    async loadComments() {
      try {
        const allComments = await api.getAllComments()
        this.comments = allComments.map(c => ({
          ...c,
          id: c.comment_id || c.id,
          replies: []
        }))
        
        // 构建评论树结构（父评论和回复）
        const commentsMap = new Map()
        this.comments.forEach(c => commentsMap.set(c.id, c))
        
        const rootComments = []
        this.comments.forEach(c => {
          if (c.parent) {
            const parent = commentsMap.get(c.parent)
            if (parent) {
              if (!parent.replies) parent.replies = []
              parent.replies.push(c)
            }
          } else {
            rootComments.push(c)
          }
        })
        
        this.comments = rootComments
      } catch (err) {
        console.error('加载评论失败', err)
      }
    },
    getRatingComments(ratingId) {
      return this.comments.filter(c => c.rating === ratingId)
    },
    getCommentCount(ratingId) {
      const comments = this.getRatingComments(ratingId)
      let count = comments.length
      comments.forEach(c => {
        if (c.replies) count += c.replies.length
      })
      return count
    },
    async submitComment(ratingId) {
      const content = this.commentInputs[ratingId]?.trim()
      if (!content) return
      try {
        await api.postComment({
          rating: ratingId,
          content: content
        })
        this.commentInputs[ratingId] = ''
        this.activeCommentBox = null
        await this.loadComments()
        ElMessage.success('评论发表成功')
      } catch (err) {
        ElMessage.error(err.message || '评论失败')
      }
    },
    replyToComment(comment) {
      this.replyingTo = comment.comment_id
      this.replyContent = ''
    },
    cancelReply() {
      this.replyingTo = null
      this.replyContent = ''
    },
    async submitReply(ratingId, parentId) {
      if (!this.replyContent.trim()) return
      try {
        await api.postComment({
          rating: ratingId,
          content: this.replyContent.trim(),
          parent: parentId
        })
        this.cancelReply()
        await this.loadComments()
        ElMessage.success('回复发表成功')
      } catch (err) {
        ElMessage.error(err.message || '回复失败')
      }
    },
    async toggleCommentLike(comment) {
      try {
        await api.likeComment(comment.id)
        await this.loadComments()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async toggleCommentDislike(comment) {
      try {
        await api.dislikeComment(comment.id)
        await this.loadComments()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async deleteComment(comment) {
      try {
        await ElMessageBox.confirm('确定删除这条评论吗？', '提示', {
          confirmButtonText: '删除',
          cancelButtonText: '取消',
          type: 'warning'
        })
        await api.deleteComment(comment.id)
        await this.loadComments()
        ElMessage.success('评论已删除')
      } catch (err) {
        if (err !== 'cancel') {
          ElMessage.error(err.message || '删除失败')
        }
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

.teacher-actions {
  margin-bottom: 20px;
  display: flex;
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
  background-color: #4a7c8f;
  border-color: #4a7c8f;
  color: white;
}

.tier-selector .el-button.active-tier.t2 {
  background-color: #6b9fb5;
  border-color: #6b9fb5;
  color: white;
}

.tier-selector .el-button.active-tier.t3 {
  background-color: #b8a5c4;
  border-color: #b8a5c4;
  color: white;
}

.reason-input {
  margin-top: 20px;
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
/* 神评标识 - 微博风格 */
.featured-badge {
  position: absolute;
  top: -1px;
  right: -1px;
  display: flex;
  align-items: center;
  gap: 4px;
  background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
  color: white;
  padding: 4px 12px 4px 8px;
  border-radius: 0 8px 0 12px;
  font-size: 0.75rem;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(255, 107, 107, 0.3);
  z-index: 1;
}

.featured-icon {
  display: flex;
  align-items: center;
  font-size: 1rem;
}

.featured-text {
  line-height: 1;
}

.rating-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.rating-meta {
  display: flex;
  align-items: center;
  gap: 8px;
}

.rating-time {
  color: var(--el-text-color-secondary);
  font-size: 0.85rem;
}

/* 操作按钮 - 社交媒体风格 */
.action-group {
  display: flex;
  gap: 4px;
  align-items: center;
}

.action-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 6px 12px;
  border: none;
  background: transparent;
  color: var(--el-text-color-secondary);
  font-size: 0.9rem;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s;
}

.action-btn:hover {
  background: var(--el-fill-color-light);
  color: var(--el-text-color-primary);
}

.action-btn.active {
  color: var(--el-color-primary);
  background: var(--el-color-primary-light-9);
}

.action-btn.comment-btn {
  color: var(--el-text-color-regular);
}

.action-btn.admin-btn {
  color: var(--el-color-warning);
}

.action-btn.admin-btn:hover {
  background: var(--el-color-warning-light-9);
}

/* 评论区样式 - 社交媒体风格 */
.comments-section {
  margin-top: 0;
}

.comments-container {
  margin-bottom: 16px;
}

.comments-header {
  margin-bottom: 12px;
}

.comments-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.comments-list {
  display: flex;
  flex-direction: column;
  gap: 0;
}

.comment-item {
  display: flex;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid var(--el-border-color-lighter);
}

.comment-item:last-child {
  border-bottom: none;
}

.comment-avatar {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  background: var(--el-fill-color);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--el-text-color-secondary);
}

.comment-main {
  flex: 1;
  min-width: 0;
}

.comment-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.comment-user {
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--el-text-color-primary);
}

.comment-time {
  font-size: 0.8rem;
  color: var(--el-text-color-placeholder);
}

.comment-content {
  margin-bottom: 8px;
  line-height: 1.6;
  color: var(--el-text-color-regular);
  word-wrap: break-word;
  white-space: pre-wrap;
}

.comment-actions {
  display: flex;
  gap: 16px;
  align-items: center;
}

.comment-action-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0;
  border: none;
  background: none;
  color: var(--el-text-color-secondary);
  font-size: 0.85rem;
  cursor: pointer;
  transition: color 0.2s;
}

.comment-action-btn:hover {
  color: var(--el-text-color-primary);
}

.comment-action-btn.active {
  color: var(--el-color-primary);
}

.comment-action-btn.delete-btn {
  color: var(--el-color-danger);
}

.comment-action-btn.delete-btn:hover {
  color: var(--el-color-danger);
  opacity: 0.8;
}

.reply-count {
  margin-left: 2px;
}

/* 回复列表 */
.replies-list {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 0;
}

.reply-item {
  display: flex;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid var(--el-border-color-extralight);
}

.reply-item:last-child {
  border-bottom: none;
}

.reply-avatar {
  flex-shrink: 0;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  background: var(--el-fill-color-light);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--el-text-color-placeholder);
}

.reply-main {
  flex: 1;
  min-width: 0;
}

/* 回复输入框 */
.reply-input-box {
  margin-top: 12px;
  padding: 12px;
  background: var(--el-fill-color-light);
  border-radius: 8px;
}

.reply-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 8px;
}

/* 查看更多 */
.load-more {
  padding: 12px 0;
  text-align: center;
}

.load-more .el-button {
  color: var(--el-color-primary);
}

/* 发表评论框 */
.add-comment-box {
  display: flex;
  gap: 12px;
  padding: 16px 0;
  cursor: text;
}

.comment-input-wrapper {
  flex: 1;
  min-width: 0;
}

.comment-placeholder {
  padding: 8px 12px;
  background: var(--el-fill-color-light);
  border: 1px solid var(--el-border-color-lighter);
  border-radius: 4px;
  color: var(--el-text-color-placeholder);
  cursor: text;
  transition: all 0.2s;
}

.comment-placeholder:hover {
  border-color: var(--el-border-color);
  background: var(--el-fill-color);
}

.comment-submit-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 8px;
}
</style>
