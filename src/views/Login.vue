<template>
  <!-- 登录页面容器 -->
  <div class="auth-page">
    <!-- Element Plus 卡片组件，用于展示登录表单 -->
    <el-card class="auth-card" shadow="hover">
      <!-- 卡片头部：显示标题和副标题 -->
      <template #header>
        <div class="card-header">
          <h2>登录</h2>
          <span class="subtitle">支持普通用户与管理员登录</span>
        </div>
      </template>
      
      <!-- 登录类型选择：用户登录 vs 管理员登录 -->
      <!-- v-model="isAdmin" 双向绑定，控制显示不同的登录表单 -->
      <el-radio-group v-model="isAdmin" style="margin-bottom: 12px;">
        <el-radio-button :label="false">用户登录</el-radio-button>
        <el-radio-button :label="true">管理员登录</el-radio-button>
      </el-radio-group>
      
      <!-- 登录表单 -->
      <!-- :model="form" 绑定表单数据对象 -->
      <!-- :rules="rules" 绑定表单验证规则 -->
      <!-- ref="formRef" 用于在方法中调用表单验证 -->
      <!-- label-position="top" 标签位置在输入框上方 -->
      <el-form :model="form" :rules="rules" ref="formRef" label-position="top">
        <!-- 普通用户登录：显示用户名或邮箱输入框 -->
        <!-- v-if="!isAdmin" 只在非管理员模式下显示 -->
        <el-form-item v-if="!isAdmin" label="用户名或邮箱" prop="identifier">
          <!-- v-model="form.identifier" 双向绑定用户输入的标识符 -->
          <el-input v-model="form.identifier" placeholder="请输入用户名或邮箱" />
        </el-form-item>
        
        <!-- 管理员登录：显示学校代码和管理员账号输入框 -->
        <!-- v-else 在管理员模式下显示 -->
        <template v-else>
          <!-- 学校代码输入框 -->
          <el-form-item label="学校代码" prop="school_code">
            <el-input v-model="form.school_code" placeholder="请输入学校代码" />
          </el-form-item>
          <!-- 管理员账号输入框 -->
          <el-form-item label="管理员账号" prop="username">
            <el-input v-model="form.username" placeholder="请输入管理员账号" />
          </el-form-item>
        </template>
        
        <!-- 密码输入框：所有登录类型都需要 -->
        <!-- show-password 显示密码显示/隐藏切换按钮 -->
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" placeholder="请输入密码" show-password />
        </el-form-item>
        
        <!-- 登录按钮 -->
        <!-- :loading="loading" 登录过程中显示加载状态，禁用按钮 -->
        <!-- @click="onSubmit" 点击时触发登录提交方法 -->
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="onSubmit" style="width: 100%;">
            登录
          </el-button>
        </el-form-item>
        
        <!-- 注册链接：引导未注册用户去注册页面 -->
        <div class="helper">
          还没有账号？
          <!-- @click="$router.push('/signup')" 点击后跳转到注册页面 -->
          <el-link type="primary" @click="$router.push('/signup')">去注册</el-link>
        </div>
      </el-form>
    </el-card>
  </div>
</template>

<script>
// 导入 Element Plus 的消息提示组件，用于显示成功/错误消息
import { ElMessage } from 'element-plus'
// 导入 API 客户端，包含登录相关的 API 方法
import { api } from '../api'

export default {
  name: 'Login',  // 组件名称
  
  /**
   * 组件数据定义
   * 返回一个对象，包含组件的响应式数据
   */
  data() {
    return {
      // 登录按钮加载状态：true 表示正在登录中，false 表示空闲状态
      // 用于控制登录按钮的禁用状态和加载动画
      loading: false,
      
      // 是否为管理员登录模式：false 表示普通用户登录，true 表示管理员登录
      // 控制显示不同的登录表单字段
      isAdmin: false,
      
      // 表单数据对象：存储用户输入的登录信息
      form: {
        identifier: '',    // 普通用户登录：用户名或邮箱（二选一）
        username: '',       // 管理员登录：管理员账号
        school_code: '',   // 管理员登录：学校代码
        password: ''       // 所有登录类型：密码
      },
      
      // 表单验证规则：定义每个字段的验证要求
      rules: {
        // 普通用户标识符验证：必填，失去焦点时触发验证
        identifier: [{ required: true, message: '请输入用户名或邮箱', trigger: 'blur' }],
        // 管理员账号验证：必填
        username: [{ required: true, message: '请输入管理员账号', trigger: 'blur' }],
        // 学校代码验证：必填
        school_code: [{ required: true, message: '请输入学校代码', trigger: 'blur' }],
        // 密码验证：必填
        password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
      }
    }
  },
  
  /**
   * 组件方法定义
   */
  methods: {
    /**
     * 提交登录表单
     * 这是登录流程的核心方法，处理用户登录的完整流程
     */
    onSubmit() {
      // 调用 Element Plus 表单验证方法
      // validate 是异步方法，接收一个回调函数，参数 valid 表示验证是否通过
      this.$refs.formRef.validate(async valid => {
        // 如果表单验证失败，直接返回，不执行登录逻辑
        if (!valid) return
        
        // 设置加载状态为 true，禁用登录按钮并显示加载动画
        this.loading = true
        
        try {
          let res  // 存储 API 响应结果
          
          // 判断登录类型：管理员登录还是普通用户登录
          if (this.isAdmin) {
            // ========== 管理员登录流程 ==========
            
            // 调用管理员登录 API，传入学校代码、用户名和密码
            // 该 API 会验证用户是否为管理员（is_staff=True）且学校代码匹配
            res = await api.loginAdmin(
              this.form.school_code, 
              this.form.username, 
              this.form.password
            )
            
            // 登录成功后，在 localStorage 中存储管理员相关标识
            // 这些标识用于后续的权限判断和页面访问控制
            
            // 设置管理员标识：'1' 表示是管理员
            localStorage.setItem('isAdmin', '1')
            
            // 存储学校代码：用于管理员只能管理自己学校的用户和教师
            // res.school_code 是服务器返回的学校代码，如果不存在则使用表单中的值
            localStorage.setItem('adminSchoolCode', res.school_code || this.form.school_code)
            
            // 清除超级管理员标识（如果存在），确保角色清晰
            localStorage.removeItem('isSuperAdmin')
            
            // 存储身份验证令牌（Token）
            // Token 是服务器生成的唯一标识，后续所有 API 请求都需要在请求头中携带此 Token
            // 格式：Authorization: Token <token_string>
            if (res.token) {
              localStorage.setItem('authToken', res.token)
            }
            
            // 显示登录成功消息
            ElMessage.success('登录成功')
            
            // 跳转到首页（排行榜页面）
            this.$router.push('/')
            
          } else {
            // ========== 普通用户登录流程 ==========
            
            // 调用普通用户登录 API，传入标识符（用户名或邮箱）和密码
            // 后端会先尝试用标识符查找用户（先查用户名，再查邮箱）
            // 然后验证密码是否正确
            res = await api.loginUser(
              this.form.identifier,  // 可以是用户名或邮箱
              this.form.password
            )
            
            // 登录成功后，清除管理员相关标识，确保角色清晰
            
            // 清除管理员标识
            localStorage.removeItem('isAdmin')
            
            // 清除超级管理员标识
            localStorage.removeItem('isSuperAdmin')
            
            // 清除学校代码（普通用户不需要）
            localStorage.removeItem('adminSchoolCode')
            
            // 存储身份验证令牌
            // Token 用于后续 API 请求的身份验证
            if (res.token) {
              localStorage.setItem('authToken', res.token)
            }
            
            // 显示登录成功消息
            ElMessage.success('登录成功')
            
            // 跳转到首页
            this.$router.push('/')
          }
          
        } catch (err) {
          // ========== 错误处理 ==========
          // 如果登录过程中发生错误（如密码错误、用户不存在、网络错误等）
          
          // API 错误处理已经在 api.js 中提取了详细的错误信息
          // err.message 包含后端返回的具体错误信息（如"用户不存在"、"认证失败"等）
          // 如果没有错误信息，则显示默认的错误提示
          ElMessage.error(err.message || '登录失败，请检查用户名/邮箱和密码是否正确')
          
        } finally {
          // ========== 清理工作 ==========
          // 无论登录成功还是失败，都要执行以下清理工作
          
          // 恢复加载状态，重新启用登录按钮
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