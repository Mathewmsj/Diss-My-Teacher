<template>
  <div class="auth-page">
    <el-card class="auth-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <h2>🔐 超级管理员登录</h2>
          <span class="subtitle">仅限超级管理员访问</span>
        </div>
      </template>
      <el-form :model="form" :rules="rules" ref="formRef" label-position="top">
        <el-form-item label="超级管理员用户名" prop="username">
          <el-input v-model="form.username" placeholder="请输入超级管理员用户名" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" placeholder="请输入密码" type="password" show-password />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="onSubmit" style="width: 100%;">
            登录
          </el-button>
        </el-form-item>
        <div class="helper">
          <el-link type="primary" @click="$router.push('/login')">返回普通登录</el-link>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { ElMessage } from 'element-plus'
import { api } from '../api'

export default {
  name: 'SuperAdminLogin',
  data() {
    return {
      loading: false,
      form: {
        username: '',
        password: ''
      },
      rules: {
        username: [{ required: true, message: '请输入超级管理员用户名', trigger: 'blur' }],
        password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
      }
    }
  },
  methods: {
    onSubmit() {
      this.$refs.formRef.validate(async valid => {
        if (!valid) return
        this.loading = true
        try {
          const res = await api.loginSuperAdmin(this.form.username, this.form.password)
          localStorage.setItem('isSuperAdmin', '1')
          localStorage.removeItem('isAdmin')
          localStorage.removeItem('adminSchoolCode')
          if (res.token) {
            localStorage.setItem('authToken', res.token)
          }
          ElMessage.success('超级管理员登录成功')
          this.$router.push('/superadmin')
        } catch (err) {
          ElMessage.error(err.message || '登录失败')
        } finally {
          this.loading = false
        }
      })
    }
  }
}
</script>

<style scoped>
.auth-page {
  max-width: 480px;
  margin: 0 auto;
  padding: 40px 20px;
}

.auth-card {
  border: 1px solid var(--border-color);
}

.card-header h2 {
  margin: 0;
  font-size: 24px;
}

.subtitle {
  color: var(--text-secondary);
  font-size: 0.95rem;
}

.helper {
  text-align: center;
  color: var(--text-secondary);
}
</style>
