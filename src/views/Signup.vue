<template>
  <div class="auth-page">
    <el-card class="auth-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <h2>注册</h2>
          <span class="subtitle">注册后需管理员审核通过才能评分</span>
        </div>
      </template>
      <el-form :model="form" :rules="rules" ref="formRef" label-position="top">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="邮箱" prop="email">
          <el-input v-model="form.email" placeholder="请输入邮箱" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-form-item label="学校代码" prop="school_code">
          <el-input v-model="form.school_code" placeholder="请输入学校代码" />
        </el-form-item>
        <el-form-item label="您的真实姓名" prop="real_name">
          <el-input v-model="form.real_name" placeholder="请输入您的真实姓名" />
          <div style="font-size: 0.85rem; color: var(--el-text-color-secondary); margin-top: 4px;">
            <el-icon><InfoFilled /></el-icon>
            此信息不会展示给任何人，仅做备用
          </div>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="onSubmit" style="width: 100%;">
            注册并登录
          </el-button>
        </el-form-item>
        <div class="helper">
          已有账号？
          <el-link type="primary" @click="$router.push('/login')">去登录</el-link>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { ElMessage } from 'element-plus'
import { api } from '../api'

export default {
  name: 'Signup',
  data() {
    return {
      loading: false,
      form: {
        username: '',
        email: '',
        password: '',
        school_code: '',
        real_name: ''
      },
      rules: {
        username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
        email: [{ required: true, message: '请输入邮箱', trigger: 'blur' }],
        password: [{ required: true, message: '请输入密码', trigger: 'blur' }],
        school_code: [{ required: true, message: '请输入学校代码', trigger: 'blur' }],
        real_name: [{ required: true, message: '请输入真实姓名', trigger: 'blur' }]
      }
    }
  },
  methods: {
    onSubmit() {
      this.$refs.formRef.validate(async valid => {
        if (!valid) return
        this.loading = true
        try {
          await api.signup({
            username: this.form.username,
            email: this.form.email,
            password: this.form.password,
            school_code: this.form.school_code,
            real_name: this.form.real_name
          })
          ElMessage.success('注册成功，等待管理员审核')
          this.$router.push('/login')
        } catch (err) {
          ElMessage.error(err.message || '注册失败')
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
}

.auth-card {
  border: 1px solid var(--border-color);
}

.card-header h2 {
  margin: 0;
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

