<template>
  <div class="super-admin-panel">
    <el-card class="header-card" shadow="hover">
      <template #header>
        <div class="header-content">
          <h2>🔐 超级管理员控制台</h2>
          <el-tag type="danger" size="large">超级管理员模式</el-tag>
        </div>
      </template>
    </el-card>

    <!-- 系统统计 -->
    <el-card class="stats-card" shadow="hover">
      <template #header>
        <span>📊 系统统计</span>
      </template>
      <el-row :gutter="20" v-if="stats">
        <el-col :span="6">
          <el-statistic title="学校总数" :value="stats.schools" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="老师总数" :value="stats.teachers" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="用户总数" :value="stats.users" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="管理员数" :value="stats.admins" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="评分总数" :value="stats.ratings" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="今日评分" :value="stats.ratings_today" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="待审批用户" :value="stats.pending_users" />
        </el-col>
        <el-col :span="6">
          <el-statistic title="已通过用户" :value="stats.approved_users" />
        </el-col>
      </el-row>
    </el-card>

    <el-tabs v-model="activeTab" type="border-card">
      <!-- 学校管理 -->
      <el-tab-pane label="🏫 学校管理" name="schools">
        <div class="tab-content">
          <div class="action-bar">
            <el-button type="primary" @click="openCreateSchoolDialog">新增学校</el-button>
            <el-button @click="loadSchools">刷新</el-button>
          </div>
          <el-table :data="schools" border stripe>
            <el-table-column prop="school_code" label="学校代码" width="150" />
            <el-table-column prop="school_name" label="学校名称" />
            <el-table-column prop="address" label="地址" />
            <el-table-column prop="daily_rating_limit" label="每日评分上限" width="120" />
            <el-table-column prop="created_at" label="创建时间" width="180" />
            <el-table-column label="操作" width="280" fixed="right">
              <template #default="{ row }">
                <el-button size="small" @click="openEditSchoolDialog(row)">编辑</el-button>
                <el-button size="small" type="warning" @click="openUpdateSchoolCodeDialog(row)">修改代码</el-button>
                <el-popconfirm title="确定删除这个学校吗？" @confirm="deleteSchool(row.school_code)">
                  <template #reference>
                    <el-button size="small" type="danger">删除</el-button>
                  </template>
                </el-popconfirm>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

      <!-- 用户管理 -->
      <el-tab-pane label="👥 用户管理" name="users">
        <div class="tab-content">
          <div class="action-bar">
            <el-button type="primary" @click="openCreateAdminDialog">创建管理员</el-button>
            <el-button @click="loadUsers">刷新</el-button>
            <el-select
              v-model="userSchoolFilter"
              placeholder="按学校筛选"
              clearable
              style="width: 200px; margin-left: 10px;"
            >
              <el-option label="全部学校" value="" />
              <el-option
                v-for="school in schools"
                :key="school.school_code"
                :label="school.school_name"
                :value="school.school_code"
              />
            </el-select>
            <el-input
              v-model="userSearchKeyword"
              placeholder="搜索用户名/邮箱"
              style="width: 300px; margin-left: 10px;"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
          </div>
          <el-table :data="filteredUsers" border stripe>
            <el-table-column prop="id" label="ID" width="80" />
            <el-table-column prop="username" label="用户名" width="150" />
            <el-table-column prop="email" label="邮箱" width="200" />
            <el-table-column prop="school_name" label="所属学校" />
            <el-table-column prop="school_code" label="学校代码" width="120" />
            <el-table-column label="角色" width="100">
              <template #default="{ row }">
                <el-tag v-if="row.is_superuser" type="danger">超级管理员</el-tag>
                <el-tag v-else-if="row.is_staff" type="warning">管理员</el-tag>
                <el-tag v-else type="info">普通用户</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="状态" width="120">
              <template #default="{ row }">
                <el-tag :type="row.is_active ? 'success' : 'danger'">
                  {{ row.is_active ? '激活' : '停用' }}
                </el-tag>
                <el-tag :type="row.approval_status === 'approved' ? 'success' : row.approval_status === 'pending' ? 'warning' : 'danger'" style="margin-left: 5px;">
                  {{ row.approval_status === 'approved' ? '已通过' : row.approval_status === 'pending' ? '待审批' : '已拒绝' }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="date_joined" label="注册时间" width="180" />
            <el-table-column label="操作" width="350" fixed="right">
              <template #default="{ row }">
                <el-button size="small" @click="openEditUserDialog(row)">编辑</el-button>
                <el-button size="small" type="warning" @click="openResetPasswordDialog(row)">重置密码</el-button>
                <el-popconfirm title="确定删除这个用户吗？" @confirm="deleteUserSuper(row.id)">
                  <template #reference>
                    <el-button size="small" type="danger">删除</el-button>
                  </template>
                </el-popconfirm>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>

      <!-- 评分管理 -->
      <el-tab-pane label="📝 评分管理" name="ratings">
        <div class="tab-content">
          <div class="action-bar">
            <el-button @click="loadRatings">刷新</el-button>
            <el-select
              v-model="ratingSchoolFilter"
              placeholder="按学校筛选"
              clearable
              style="width: 200px; margin-left: 10px;"
            >
              <el-option label="全部学校" value="" />
              <el-option
                v-for="school in schools"
                :key="school.school_code"
                :label="school.school_name"
                :value="school.school_code"
              />
            </el-select>
            <el-input
              v-model="ratingSearchKeyword"
              placeholder="搜索老师/用户"
              style="width: 300px; margin-left: 10px;"
              clearable
            >
              <template #prefix>
                <el-icon><Search /></el-icon>
              </template>
            </el-input>
          </div>
          <el-table :data="filteredRatings" border stripe max-height="600">
            <el-table-column prop="rating_id" label="ID" width="80" />
            <el-table-column prop="teacher_name" label="老师" width="120" />
            <el-table-column prop="user_name" label="评分用户" width="120" />
            <el-table-column prop="user_email" label="用户邮箱" width="180" />
            <el-table-column prop="school_name" label="学校" width="150" />
            <el-table-column label="等级" width="80">
              <template #default="{ row }">
                <el-tag :type="row.tier === 'T3' ? 'danger' : row.tier === 'T2' ? 'warning' : 'info'">
                  {{ row.tier }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="reason" label="评分理由" show-overflow-tooltip />
            <el-table-column label="点赞/点踩" width="120">
              <template #default="{ row }">
                <el-tag type="success">👍 {{ row.likes }}</el-tag>
                <el-tag type="warning" style="margin-left: 5px;">👎 {{ row.dislikes }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="created_at" label="创建时间" width="180" />
            <el-table-column label="操作" width="200" fixed="right">
              <template #default="{ row }">
                <el-button size="small" @click="showRatingDetail(row)">详情</el-button>
                <el-popconfirm title="确定删除这条评分吗？" @confirm="deleteRatingSuper(row.rating_id)">
                  <template #reference>
                    <el-button size="small" type="danger">删除</el-button>
                  </template>
                </el-popconfirm>
              </template>
            </el-table-column>
          </el-table>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 创建/编辑学校对话框 -->
    <el-dialog
      v-model="schoolDialogVisible"
      :title="editingSchool ? '编辑学校' : '新增学校'"
      width="500px"
    >
      <el-form :model="schoolForm" label-width="120px">
        <el-form-item label="学校代码" required>
          <el-input v-model="schoolForm.school_code" :disabled="!!editingSchool" />
        </el-form-item>
        <el-form-item label="学校名称" required>
          <el-input v-model="schoolForm.school_name" />
        </el-form-item>
        <el-form-item label="地址">
          <el-input v-model="schoolForm.address" type="textarea" />
        </el-form-item>
        <el-form-item label="每日评分上限（按等级）" required>
          <div style="display: flex; gap: 15px; align-items: center;">
            <span style="min-width: 50px;">T1:</span>
            <el-input-number v-model="schoolForm.daily_t1_limit" :min="0" :max="99" />
            <span style="min-width: 50px;">T2:</span>
            <el-input-number v-model="schoolForm.daily_t2_limit" :min="0" :max="99" />
            <span style="min-width: 50px;">T3:</span>
            <el-input-number v-model="schoolForm.daily_t3_limit" :min="0" :max="99" />
          </div>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="schoolDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveSchool">保存</el-button>
      </template>
    </el-dialog>

    <!-- 创建管理员对话框 -->
    <el-dialog v-model="adminDialogVisible" title="创建管理员" width="500px">
      <el-form :model="adminForm" label-width="120px">
        <el-form-item label="用户名" required>
          <el-input v-model="adminForm.username" />
        </el-form-item>
        <el-form-item label="邮箱" required>
          <el-input v-model="adminForm.email" />
        </el-form-item>
        <el-form-item label="密码" required>
          <el-input v-model="adminForm.password" type="password" show-password />
        </el-form-item>
        <el-form-item label="学校代码">
          <el-input v-model="adminForm.school_code" placeholder="留空则不绑定学校" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="adminDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveAdmin">创建</el-button>
      </template>
    </el-dialog>

    <!-- 编辑用户对话框 -->
    <el-dialog v-model="userDialogVisible" title="编辑用户" width="600px">
      <el-form :model="userForm" label-width="120px">
        <el-form-item label="用户名">
          <el-input v-model="userForm.username" />
        </el-form-item>
        <el-form-item label="邮箱">
          <el-input v-model="userForm.email" />
        </el-form-item>
        <el-form-item label="学校代码">
          <el-input v-model="userForm.school_code" placeholder="留空则取消绑定" />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="userForm.password" type="password" show-password placeholder="留空则不修改" />
        </el-form-item>
        <el-form-item label="角色">
          <el-checkbox v-model="userForm.is_staff">管理员</el-checkbox>
          <el-checkbox v-model="userForm.is_superuser" style="margin-left: 20px;">超级管理员</el-checkbox>
        </el-form-item>
        <el-form-item label="状态">
          <el-checkbox v-model="userForm.is_active">激活</el-checkbox>
          <el-checkbox v-model="userForm.is_approved" style="margin-left: 20px;">已审批</el-checkbox>
          <el-checkbox v-model="userForm.can_rate" style="margin-left: 20px;">可评分</el-checkbox>
        </el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="userForm.approval_status">
            <el-option label="待审批" value="pending" />
            <el-option label="已通过" value="approved" />
            <el-option label="已拒绝" value="rejected" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveUser">保存</el-button>
      </template>
    </el-dialog>

    <!-- 评分详情对话框 -->
    <el-dialog v-model="ratingDetailVisible" title="评分详情" width="800px">
      <div v-if="selectedRating">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="评分ID">{{ selectedRating.rating_id }}</el-descriptions-item>
          <el-descriptions-item label="老师">{{ selectedRating.teacher_name }}</el-descriptions-item>
          <el-descriptions-item label="评分用户">{{ selectedRating.user_name }}</el-descriptions-item>
          <el-descriptions-item label="用户邮箱">{{ selectedRating.user_email }}</el-descriptions-item>
          <el-descriptions-item label="学校">{{ selectedRating.school_name }}</el-descriptions-item>
          <el-descriptions-item label="等级">
            <el-tag :type="selectedRating.tier === 'T3' ? 'danger' : selectedRating.tier === 'T2' ? 'warning' : 'info'">
              {{ selectedRating.tier }}
            </el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="评分理由" :span="2">{{ selectedRating.reason }}</el-descriptions-item>
          <el-descriptions-item label="点赞数">{{ selectedRating.likes }}</el-descriptions-item>
          <el-descriptions-item label="点踩数">{{ selectedRating.dislikes }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ selectedRating.created_at }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ selectedRating.updated_at }}</el-descriptions-item>
        </el-descriptions>
        
        <el-divider>点赞用户列表</el-divider>
        <el-table :data="selectedRating.liked_users" border size="small" v-if="selectedRating.liked_users.length > 0">
          <el-table-column prop="username" label="用户名" />
          <el-table-column prop="email" label="邮箱" />
          <el-table-column prop="created_at" label="点赞时间" />
        </el-table>
        <el-empty v-else description="暂无点赞" />

        <el-divider>点踩用户列表</el-divider>
        <el-table :data="selectedRating.disliked_users" border size="small" v-if="selectedRating.disliked_users.length > 0">
          <el-table-column prop="username" label="用户名" />
          <el-table-column prop="email" label="邮箱" />
          <el-table-column prop="created_at" label="点踩时间" />
        </el-table>
        <el-empty v-else description="暂无点踩" />
      </div>
    </el-dialog>

    <!-- 重置密码对话框 -->
    <el-dialog v-model="resetPasswordDialogVisible" title="重置用户密码" width="500px">
      <el-form :model="resetPasswordForm" label-width="120px">
        <el-form-item label="新密码" required>
          <el-input v-model="resetPasswordForm.password" type="password" show-password placeholder="至少6位" />
        </el-form-item>
        <el-form-item label="确认密码" required>
          <el-input v-model="resetPasswordForm.confirmPassword" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="resetPasswordDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveResetPassword">重置</el-button>
      </template>
    </el-dialog>

    <!-- 修改学校代码对话框 -->
    <el-dialog v-model="updateSchoolCodeDialogVisible" title="修改学校代码" width="500px">
      <el-alert
        title="注意"
        type="warning"
        :closable="false"
        style="margin-bottom: 20px;"
      >
        <template #default>
          <div>修改学校代码后，所有相关记录（用户、老师、评分等）的学校代码都会自动更新。</div>
          <div style="margin-top: 5px;">此操作不可逆，请谨慎操作！</div>
        </template>
      </el-alert>
      <el-form :model="updateSchoolCodeForm" label-width="120px">
        <el-form-item label="当前代码">
          <el-input v-model="updateSchoolCodeForm.old_code" disabled />
        </el-form-item>
        <el-form-item label="新代码" required>
          <el-input v-model="updateSchoolCodeForm.new_code" placeholder="请输入新的学校代码" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="updateSchoolCodeDialogVisible = false">取消</el-button>
        <el-button type="warning" @click="saveUpdateSchoolCode">确认修改</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { api } from '../api'
import { ElMessage } from 'element-plus'
import { Search } from '@element-plus/icons-vue'

export default {
  name: 'SuperAdminPanel',
  components: {
    Search
  },
  data() {
    return {
      activeTab: 'schools',
      stats: null,
      schools: [],
      users: [],
      ratings: [],
      userSearchKeyword: '',
      ratingSearchKeyword: '',
      userSchoolFilter: '',
      ratingSchoolFilter: '',
      schoolDialogVisible: false,
      adminDialogVisible: false,
      userDialogVisible: false,
      ratingDetailVisible: false,
      resetPasswordDialogVisible: false,
      updateSchoolCodeDialogVisible: false,
      editingSchool: null,
      selectedRating: null,
      resetPasswordUserId: null,
      resetPasswordForm: {
        password: '',
        confirmPassword: ''
      },
      updateSchoolCodeForm: {
        old_code: '',
        new_code: ''
      },
      schoolForm: {
        school_code: '',
        school_name: '',
        address: '',
        daily_rating_limit: 2,
        daily_t1_limit: 3,
        daily_t2_limit: 2,
        daily_t3_limit: 1
      },
      adminForm: {
        username: '',
        email: '',
        password: '',
        school_code: ''
      },
      userForm: {
        username: '',
        email: '',
        school_code: '',
        password: '',
        is_staff: false,
        is_superuser: false,
        is_active: true,
        is_approved: true,
        can_rate: true,
        approval_status: 'approved'
      }
    }
  },
  computed: {
    filteredUsers() {
      let result = this.users
      
      // 学校筛选
      if (this.userSchoolFilter) {
        result = result.filter(u => u.school_code === this.userSchoolFilter)
      }
      
      // 关键词搜索
      if (this.userSearchKeyword) {
        const keyword = this.userSearchKeyword.toLowerCase()
        result = result.filter(u => 
          u.username.toLowerCase().includes(keyword) || 
          (u.email && u.email.toLowerCase().includes(keyword))
        )
      }
      
      return result
    },
    filteredRatings() {
      let result = this.ratings
      
      // 学校筛选
      if (this.ratingSchoolFilter) {
        result = result.filter(r => r.school_code === this.ratingSchoolFilter)
      }
      
      // 关键词搜索
      if (this.ratingSearchKeyword) {
        const keyword = this.ratingSearchKeyword.toLowerCase()
        result = result.filter(r => 
          (r.teacher_name && r.teacher_name.toLowerCase().includes(keyword)) ||
          (r.user_name && r.user_name.toLowerCase().includes(keyword))
        )
      }
      
      return result
    }
  },
  mounted() {
    this.loadData()
  },
  methods: {
    async loadData() {
      try {
        await Promise.all([
          this.loadStats(),
          this.loadSchools(),
          this.loadUsers(),
          this.loadRatings()
        ])
      } catch (err) {
        ElMessage.error(err.message || '数据加载失败')
      }
    },
    async loadStats() {
      this.stats = await api.getSuperAdminStats()
    },
    async loadSchools() {
      this.schools = await api.getAllSchools()
    },
    async loadUsers() {
      this.users = await api.getAllUsers()
    },
    async loadRatings() {
      this.ratings = await api.getAllRatings()
    },
    openCreateSchoolDialog() {
      this.editingSchool = null
      this.schoolForm = {
        school_code: '',
        school_name: '',
        address: '',
        daily_rating_limit: 2,
        daily_t1_limit: 3,
        daily_t2_limit: 2,
        daily_t3_limit: 1
      }
      this.schoolDialogVisible = true
    },
    openEditSchoolDialog(school) {
      this.editingSchool = school
      this.schoolForm = {
        school_code: school.school_code,
        school_name: school.school_name,
        address: school.address || '',
        daily_rating_limit: school.daily_rating_limit || 2,
        daily_t1_limit: school.daily_t1_limit !== undefined ? school.daily_t1_limit : 3,
        daily_t2_limit: school.daily_t2_limit !== undefined ? school.daily_t2_limit : 2,
        daily_t3_limit: school.daily_t3_limit !== undefined ? school.daily_t3_limit : 1
      }
      this.schoolDialogVisible = true
    },
    async saveSchool() {
      try {
        if (this.editingSchool) {
          await api.updateSchool(this.editingSchool.school_code, this.schoolForm)
          ElMessage.success('学校更新成功')
        } else {
          await api.createSchool(this.schoolForm)
          ElMessage.success('学校创建成功')
        }
        this.schoolDialogVisible = false
        this.loadSchools()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async deleteSchool(schoolCode) {
      try {
        await api.deleteSchool(schoolCode)
        ElMessage.success('学校删除成功')
        this.loadSchools()
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    },
    openCreateAdminDialog() {
      this.adminForm = {
        username: '',
        email: '',
        password: '',
        school_code: ''
      }
      this.adminDialogVisible = true
    },
    async saveAdmin() {
      try {
        await api.createAdmin(this.adminForm)
        ElMessage.success('管理员创建成功')
        this.adminDialogVisible = false
        this.loadUsers()
      } catch (err) {
        ElMessage.error(err.message || '创建失败')
      }
    },
    openEditUserDialog(user) {
      this.userForm = {
        username: user.username,
        email: user.email,
        school_code: user.school_code || '',
        password: '',
        is_staff: user.is_staff || false,
        is_superuser: user.is_superuser || false,
        is_active: user.is_active !== false,
        is_approved: user.is_approved || false,
        can_rate: user.can_rate !== false,
        approval_status: user.approval_status || 'pending'
      }
      this.editingUserId = user.id
      this.userDialogVisible = true
    },
    async saveUser() {
      try {
        const payload = { ...this.userForm }
        if (!payload.password) {
          delete payload.password
        }
        await api.updateUser(this.editingUserId, payload)
        ElMessage.success('用户更新成功')
        this.userDialogVisible = false
        this.loadUsers()
      } catch (err) {
        ElMessage.error(err.message || '更新失败')
      }
    },
    async deleteUserSuper(id) {
      try {
        await api.deleteUserSuper(id)
        ElMessage.success('用户删除成功')
        this.loadUsers()
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    },
    showRatingDetail(rating) {
      this.selectedRating = rating
      this.ratingDetailVisible = true
    },
    openResetPasswordDialog(user) {
      this.resetPasswordUserId = user.id
      this.resetPasswordForm = {
        password: '',
        confirmPassword: ''
      }
      this.resetPasswordDialogVisible = true
    },
    async saveResetPassword() {
      if (!this.resetPasswordForm.password) {
        ElMessage.warning('请输入新密码')
        return
      }
      if (this.resetPasswordForm.password.length < 6) {
        ElMessage.warning('密码长度至少6位')
        return
      }
      if (this.resetPasswordForm.password !== this.resetPasswordForm.confirmPassword) {
        ElMessage.warning('两次输入的密码不一致')
        return
      }
      try {
        await api.resetUserPassword(this.resetPasswordUserId, this.resetPasswordForm.password)
        ElMessage.success('密码重置成功')
        this.resetPasswordDialogVisible = false
      } catch (err) {
        ElMessage.error(err.message || '密码重置失败')
      }
    },
    openUpdateSchoolCodeDialog(school) {
      this.updateSchoolCodeForm = {
        old_code: school.school_code,
        new_code: ''
      }
      this.updateSchoolCodeDialogVisible = true
    },
    async saveUpdateSchoolCode() {
      if (!this.updateSchoolCodeForm.new_code) {
        ElMessage.warning('请输入新学校代码')
        return
      }
      if (this.updateSchoolCodeForm.new_code === this.updateSchoolCodeForm.old_code) {
        ElMessage.warning('新代码与旧代码相同')
        return
      }
      try {
        await api.updateSchoolCode(this.updateSchoolCodeForm.old_code, this.updateSchoolCodeForm.new_code)
        ElMessage.success('学校代码更新成功，所有相关记录已同步更新')
        this.updateSchoolCodeDialogVisible = false
        await this.loadSchools()
        await this.loadUsers()
        await this.loadRatings()
      } catch (err) {
        ElMessage.error(err.message || '更新失败')
      }
    },
    async deleteRatingSuper(id) {
      try {
        await api.deleteRatingSuper(id)
        ElMessage.success('评分删除成功')
        this.loadRatings()
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    }
  }
}
</script>

<style scoped>
.super-admin-panel {
  padding: 20px;
}

.header-card {
  margin-bottom: 20px;
}

.header-content {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content h2 {
  margin: 0;
}

.stats-card {
  margin-bottom: 20px;
}

.tab-content {
  padding: 20px 0;
}

.action-bar {
  margin-bottom: 20px;
  display: flex;
  align-items: center;
}

.el-table {
  margin-top: 10px;
}
</style>
