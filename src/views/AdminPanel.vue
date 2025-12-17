<template>
  <div class="admin-panel">
    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>学校设置</h2>
          <el-button type="primary" @click="loadData" :loading="loading">刷新</el-button>
        </div>
      </template>
      <el-table :data="schools" style="width: 100%" size="small">
        <el-table-column prop="school_code" label="学校代码" width="160" />
        <el-table-column prop="school_name" label="学校名称" />
        <el-table-column label="每日评分上限（按等级）" width="500">
          <template #default="{ row }">
            <div style="display: flex; gap: 12px; align-items: center; flex-wrap: wrap;">
              <div style="display: flex; align-items: center; gap: 4px;">
                <span style="min-width: 40px; font-weight: 500;">T1:</span>
                <el-input-number 
                  v-model="row.daily_t1_limit" 
                  :min="0" 
                  :max="99" 
                  size="small" 
                  style="width: 100px;" 
                  :controls="true"
                />
              </div>
              <div style="display: flex; align-items: center; gap: 4px;">
                <span style="min-width: 40px; font-weight: 500;">T2:</span>
                <el-input-number 
                  v-model="row.daily_t2_limit" 
                  :min="0" 
                  :max="99" 
                  size="small" 
                  style="width: 100px;" 
                  :controls="true"
                />
              </div>
              <div style="display: flex; align-items: center; gap: 4px;">
                <span style="min-width: 40px; font-weight: 500;">T3:</span>
                <el-input-number 
                  v-model="row.daily_t3_limit" 
                  :min="0" 
                  :max="99" 
                  size="small" 
                  style="width: 100px;" 
                  :controls="true"
                />
              </div>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160">
          <template #default="{ row }">
            <el-button type="primary" size="small" @click="updateLimit(row)">保存</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>待审批用户</h2>
          <el-button type="primary" @click="loadPending" :loading="pendingLoading">刷新</el-button>
        </div>
      </template>
      <el-table :data="pending" style="width: 100%" size="small">
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="school" label="学校" width="160" />
        <el-table-column prop="can_rate" label="可评分" width="100">
          <template #default="{ row }">
            <el-tag :type="row.can_rate ? 'success' : 'info'">{{ row.can_rate ? '是' : '否' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button type="success" size="small" @click="approve(row)">通过</el-button>
              <el-button type="warning" size="small" @click="toggleRate(row, !row.can_rate)">
                {{ row.can_rate ? '禁用评分' : '启用评分' }}
              </el-button>
              <el-button type="danger" size="small" @click="reject(row)">拒绝</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>导入老师 (CSV)</h2>
        </div>
      </template>
      <div class="upload-row">
        <el-upload
          :show-file-list="false"
          :before-upload="beforeUpload"
          :http-request="handleUpload"
        >
          <el-button type="primary" :loading="uploading">上传 CSV 文件</el-button>
        </el-upload>
        <span class="upload-hint">字段：name, department, school_code（可选）</span>
      </div>
      <div class="paste-row">
        <el-input
          v-model="csvText"
          type="textarea"
          :rows="6"
          placeholder="可直接粘贴 CSV 文本，表头需包含 name, department, school_code（可选）"
        />
        <el-button style="margin-top: 8px;" type="primary" :loading="uploading" @click="handlePasteImport">
          粘贴导入
        </el-button>
      </div>
    </el-card>

    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>教师管理</h2>
          <el-button type="primary" @click="loadTeachers" :loading="teachersLoading">刷新</el-button>
        </div>
      </template>
      <div class="single-add">
        <el-input v-model="newTeacher.name" placeholder="姓名" style="max-width: 200px;" />
        <el-input v-model="newTeacher.department_name" placeholder="部门名称" style="max-width: 200px;" />
        <el-input v-model="newTeacher.school_code" placeholder="学校代码(可选)" style="max-width: 200px;" />
        <el-button type="primary" :loading="addingTeacher" @click="addTeacher">单个添加</el-button>
      </div>
      <el-table :data="teachers" style="width: 100%" size="small">
        <el-table-column prop="name" label="姓名" />
        <el-table-column prop="department_name" label="部门" />
        <el-table-column prop="school_code" label="学校" width="160" />
        <el-table-column label="操作" width="140">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button type="danger" size="small" @click="deleteTeacher(row)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>已通过用户</h2>
          <el-button type="primary" @click="loadApproved" :loading="approvedLoading">刷新</el-button>
        </div>
      </template>
      <el-table :data="approved" style="width: 100%" size="small">
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="school" label="学校" width="160" />
        <el-table-column prop="can_rate" label="可评分" width="100">
          <template #default="{ row }">
            <el-tag :type="row.can_rate ? 'success' : 'info'">{{ row.can_rate ? '是' : '否' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button type="warning" size="small" @click="toggleRate(row, !row.can_rate)">
                {{ row.can_rate ? '禁用评分' : '启用评分' }}
              </el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="hover" class="panel-card">
      <template #header>
        <div class="panel-header">
          <h2>已拒绝用户</h2>
          <el-button type="primary" @click="loadRejected" :loading="rejectedLoading">刷新</el-button>
        </div>
      </template>
      <el-table :data="rejected" style="width: 100%" size="small">
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="email" label="邮箱" />
        <el-table-column prop="school" label="学校" width="160" />
        <el-table-column prop="can_rate" label="可评分" width="100">
          <template #default="{ row }">
            <el-tag :type="row.can_rate ? 'success' : 'info'">{{ row.can_rate ? '是' : '否' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <div class="action-btns">
              <el-button type="success" size="small" @click="approve(row)">改为通过</el-button>
              <el-button type="danger" size="small" @click="deleteUser(row)">删除</el-button>
            </div>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { api } from '../api'
import { ElMessage } from 'element-plus'

export default {
  name: 'AdminPanel',
  data() {
    return {
      schools: [],
      pending: [],
      approved: [],
      rejected: [],
      teachers: [],
      newTeacher: { name: '', department_name: '', school_code: '' },
      loading: false,
      pendingLoading: false,
      approvedLoading: false,
      rejectedLoading: false,
      teachersLoading: false,
      addingTeacher: false,
      uploading: false,
      csvText: ''
    }
  },
  mounted() {
    this.loadData()
    this.loadPending()
    this.loadApproved()
    this.loadRejected()
    this.loadTeachers()
  },
  methods: {
    async loadData() {
      this.loading = true
      try {
        const schools = await api.getSchools()
        // 确保新字段有默认值
        this.schools = schools.map(s => ({
          ...s,
          daily_t1_limit: s.daily_t1_limit !== undefined ? s.daily_t1_limit : 3,
          daily_t2_limit: s.daily_t2_limit !== undefined ? s.daily_t2_limit : 2,
          daily_t3_limit: s.daily_t3_limit !== undefined ? s.daily_t3_limit : 1
        }))
      } catch (err) {
        ElMessage.error(err.message || '学校数据加载失败')
      } finally {
        this.loading = false
      }
    },
    async loadPending() {
      this.pendingLoading = true
      try {
        this.pending = await api.getPendingUsers()
      } catch (err) {
        ElMessage.error(err.message || '待审批用户加载失败')
      } finally {
        this.pendingLoading = false
      }
    },
    async loadApproved() {
      this.approvedLoading = true
      try {
        this.approved = await api.getApprovedUsers()
      } catch (err) {
        ElMessage.error(err.message || '已通过用户加载失败')
      } finally {
        this.approvedLoading = false
      }
    },
    async loadRejected() {
      this.rejectedLoading = true
      try {
        this.rejected = await api.getRejectedUsers()
      } catch (err) {
        ElMessage.error(err.message || '已拒绝用户加载失败')
      } finally {
        this.rejectedLoading = false
      }
    },
    async loadTeachers() {
      this.teachersLoading = true
      try {
        const list = await api.getTeachersRaw()
        this.teachers = list.map(t => ({
          ...t,
          id: t.teacher_id || t.id,
          department_name: t.department_name || t.department,
          school_code: t.school_code || (t.school && t.school.school_code) || ''
        }))
      } catch (err) {
        ElMessage.error(err.message || '教师加载失败')
      } finally {
        this.teachersLoading = false
      }
    },
    async updateLimit(row) {
      try {
        await api.setSchoolLimit(row.id || row.school_code, {
          daily_t1_limit: row.daily_t1_limit !== undefined ? row.daily_t1_limit : 3,
          daily_t2_limit: row.daily_t2_limit !== undefined ? row.daily_t2_limit : 2,
          daily_t3_limit: row.daily_t3_limit !== undefined ? row.daily_t3_limit : 1
        })
        ElMessage.success('保存成功')
      } catch (err) {
        ElMessage.error(err.message || '保存失败')
      }
    },
    async approve(row) {
      try {
        await api.approveUser(row.id)
        ElMessage.success('已通过')
        this.loadPending()
        this.loadApproved()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async reject(row) {
      try {
        await api.rejectUser(row.id)
        ElMessage.success('已拒绝')
        this.loadPending()
        this.loadRejected()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    async toggleRate(row, can_rate) {
      try {
        await api.toggleRate(row.id, can_rate)
        ElMessage.success('已更新')
        this.loadPending()
        this.loadApproved()
        this.loadRejected()
      } catch (err) {
        ElMessage.error(err.message || '操作失败')
      }
    },
    beforeUpload(file) {
      const isCsv = file.type === 'text/csv' || file.name.endsWith('.csv')
      if (!isCsv) {
        ElMessage.error('请上传 CSV 文件')
      }
      return isCsv
    },
    async handleUpload({ file }) {
      this.uploading = true
      try {
        await api.bulkImportTeachers(file)
        ElMessage.success('导入成功')
      } catch (err) {
        ElMessage.error(err.message || '导入失败')
      } finally {
        this.uploading = false
      }
    },
    async handlePasteImport() {
      const text = (this.csvText || '').trim()
      if (!text) {
        ElMessage.error('请先粘贴 CSV 文本')
        return
      }
      // 把文本转换成 File 形式上传
      const blob = new Blob([text], { type: 'text/csv' })
      const file = new File([blob], 'pasted.csv', { type: 'text/csv' })
      await this.handleUpload({ file })
      this.csvText = ''
      this.loadTeachers()
    },
    async addTeacher() {
      const { name, department_name, school_code } = this.newTeacher
      if (!name || !department_name) {
        ElMessage.error('姓名和部门名称必填')
        return
      }
      this.addingTeacher = true
      try {
        await api.createTeacher({ name, department_name, school_code })
        ElMessage.success('添加成功')
        this.newTeacher = { name: '', department_name: '', school_code: '' }
        this.loadTeachers()
      } catch (err) {
        ElMessage.error(err.message || '添加失败')
      } finally {
        this.addingTeacher = false
      }
    },
    async deleteTeacher(row) {
      const id = row.teacher_id || row.id
      if (!id) return
      try {
        await api.deleteTeacher(id)
        ElMessage.success('已删除')
        this.loadTeachers()
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    },
    async deleteUser(row) {
      const id = row.id
      if (!id) return
      try {
        await api.deleteUser(id)
        ElMessage.success('用户已删除')
        this.loadRejected()
        this.loadPending()
        this.loadApproved()
      } catch (err) {
        ElMessage.error(err.message || '删除失败')
      }
    }
  }
}
</script>

<style scoped>
.admin-panel {
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.panel-card {
  border: 1px solid var(--border-color);
}
.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.action-btns {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.upload-hint {
  margin-left: 12px;
  color: var(--text-secondary);
  font-size: 0.9rem;
}
.upload-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 12px;
}
.paste-row {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.single-add {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
  margin-bottom: 12px;
}
</style>
