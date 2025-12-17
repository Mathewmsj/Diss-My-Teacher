<template>
  <div class="auth-page">
    <el-card class="auth-card" shadow="hover">
      <template #header>
        <div class="card-header">
          <h2>登录</h2>
          <span class="subtitle">支持普通用户与管理员登录</span>
        </div>
      </template>
      <el-radio-group v-model="isAdmin" style="margin-bottom: 12px;">
        <el-radio-button :label="false">用户登录</el-radio-button>
        <el-radio-button :label="true">管理员登录</el-radio-button>
      </el-radio-group>
      <el-form :model="form" :rules="rules" ref="formRef" label-position="top">
        <el-form-item v-if="!isAdmin" label="用户名或邮箱" prop="identifier">
          <el-input v-model="form.identifier" placeholder="请输入用户名或邮箱" />
        </el-form-item>
        <template v-else>
          <el-form-item label="学校代码" prop="school_code">
            <el-input v-model="form.school_code" placeholder="请输入学校代码" />
          </el-form-item>
          <el-form-item label="管理员账号" prop="username">
            <el-input v-model="form.username" placeholder="请输入管理员账号" />
          </el-form-item>
        </template>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" placeholder="请输入密码" show-password />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="onSubmit" style="width: 100%;">
            登录
          </el-button>
        </el-form-item>
        <div class="helper">
          还没有账号？
          <el-link type="primary" @click="$router.push('/signup')">去注册</el-link>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script>
import { ElMessage } from 'element-plus'
import { api } from '../api'

export default {
  name: 'Login',
  data() {
    return {
      loading: false,
      isAdmin: false,
      form: {
        identifier: '',
        username: '',
        school_code: '',
        password: ''
      },
      rules: {
        identifier: [{ required: true, message: '请输入用户名或邮箱', trigger: 'blur' }],
        username: [{ required: true, message: '请输入管理员账号', trigger: 'blur' }],
        school_code: [{ required: true, message: '请输入学校代码', trigger: 'blur' }],
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
          let res
          if (this.isAdmin) {
            res = await api.loginAdmin(this.form.school_code, this.form.username, this.form.password)
            localStorage.setItem('isAdmin', '1')
            localStorage.setItem('adminSchoolCode', res.school_code || this.form.school_code)
            localStorage.removeItem('isSuperAdmin')
            if (res.token) {
              localStorage.setItem('authToken', res.token)
            }
            ElMessage.success('登录成功')
            this.$router.push('/')
          } else {
            res = await api.loginUser(this.form.identifier, this.form.password)
            localStorage.removeItem('isAdmin')
            localStorage.removeItem('isSuperAdmin')
            localStorage.removeItem('adminSchoolCode')
            if (res.token) {
              localStorage.setItem('authToken', res.token)
            }
            ElMessage.success('登录成功')
            this.$router.push('/')
          }
        } catch (err) {
          // API 错误处理已经提取了详细信息，直接显示
          ElMessage.error(err.message || '登录失败，请检查用户名/邮箱和密码是否正确')
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

