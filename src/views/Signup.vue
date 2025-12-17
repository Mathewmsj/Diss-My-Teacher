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
          <el-button type="primary" :loading="loading" :disabled="!disclaimerAgreed" @click="onSubmit" style="width: 100%;">
            注册并登录
          </el-button>
        </el-form-item>
        <div class="helper">
          已有账号？
          <el-link type="primary" @click="$router.push('/login')">去登录</el-link>
        </div>
      </el-form>
    </el-card>

    <!-- 免责声明对话框 - 注册时必须同意 -->
    <el-dialog
      v-model="disclaimerVisible"
      title="免责声明"
      width="700px"
      :close-on-click-modal="false"
      :close-on-press-escape="false"
      :show-close="false"
      :modal="true"
    >
      <div class="disclaimer-content" ref="disclaimerContentRef" @scroll="handleScroll">
        <h3>重要提示</h3>
        <p>欢迎使用本网站。在使用本网站服务前，请您仔细阅读以下免责声明。使用本网站即表示您已充分理解并同意接受本声明的全部内容。</p>
        
        <h3>1. 服务性质</h3>
        <p>本网站是一个用户生成内容的平台，所有评分、评论、意见等均由用户自行发布。网站制作者不对用户发布的内容的真实性、准确性、完整性、合法性承担任何责任。</p>
        
        <h3>2. 内容免责</h3>
        <p>本网站上的所有信息、数据、内容（包括但不限于评分、评论、用户意见等）均由用户自行提供，网站制作者不对以下事项承担责任：</p>
        <ul>
          <li>用户发布内容的真实性、准确性、完整性</li>
          <li>用户发布内容可能造成的任何直接或间接损失</li>
          <li>用户之间的争议或纠纷</li>
          <li>因用户发布内容导致的任何法律后果</li>
        </ul>
        
        <h3>3. 使用风险</h3>
        <p>用户使用本网站服务时，应当自行承担使用风险。网站制作者不对因使用或无法使用本网站服务而产生的任何直接、间接、偶然、特殊或后果性损害承担责任。</p>
        
        <h3>4. 第三方内容</h3>
        <p>本网站可能包含指向第三方网站的链接。网站制作者不对第三方网站的内容、隐私政策或做法负责，也不对因访问第三方网站而可能产生的任何损失承担责任。</p>
        
        <h3>5. 服务中断</h3>
        <p>网站制作者保留随时修改、中断或终止服务的权利，无需事先通知。对于因服务中断、终止或修改而可能造成的任何损失，网站制作者不承担责任。</p>
        
        <h3>6. 知识产权</h3>
        <p>用户在本网站发布的内容，其知识产权归用户所有。用户授权网站制作者使用、展示、存储这些内容。用户保证其发布的内容不侵犯任何第三方的合法权益。</p>
        
        <h3>7. 法律适用</h3>
        <p>本声明的解释、适用及争议解决均适用中华人民共和国法律。如因本声明产生争议，双方应友好协商解决；协商不成的，任何一方均可向网站制作者所在地有管辖权的人民法院提起诉讼。</p>
        
        <h3>8. 免责范围</h3>
        <p>在法律允许的最大范围内，网站制作者对因以下原因造成的任何损失不承担责任：</p>
        <ul>
          <li>不可抗力因素（包括但不限于自然灾害、战争、罢工、政府行为等）</li>
          <li>计算机病毒、黑客攻击、系统故障、网络中断等</li>
          <li>用户违反本声明或相关法律法规的行为</li>
          <li>其他超出网站制作者合理控制范围的情况</li>
        </ul>
        
        <h3>9. 用户责任</h3>
        <p>用户应当：</p>
        <ul>
          <li>对其在本网站上的所有行为负责</li>
          <li>确保发布的内容真实、合法，不侵犯他人权益</li>
          <li>遵守相关法律法规和本网站的使用规则</li>
          <li>承担因违反上述规定而产生的所有法律责任</li>
        </ul>
        
        <h3>10. 声明修改</h3>
        <p>网站制作者有权随时修改本免责声明。修改后的声明一经发布即生效。用户继续使用本网站即视为接受修改后的声明。</p>
        
        <p class="disclaimer-footer"><strong>最后更新日期：2025年12月</strong></p>
      </div>
      <template #footer>
        <div style="display: flex; flex-direction: column; gap: 12px;">
          <el-input
            v-model="disclaimerAgreement"
            placeholder="请输入“我同意”以继续注册"
            :disabled="!hasScrolledToBottom"
            style="width: 100%;"
          />
          <el-button 
            type="primary" 
            :disabled="disclaimerAgreement !== '我同意' || !hasScrolledToBottom"
            @click="agreeDisclaimer"
            style="width: 100%;"
          >
            我已阅读并同意
          </el-button>
        </div>
      </template>
    </el-dialog>
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
      disclaimerVisible: true,
      disclaimerAgreed: false,
      disclaimerAgreement: '',
      hasScrolledToBottom: false,
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
  mounted() {
    // 注册时强制显示免责声明
    this.disclaimerVisible = true
  },
  methods: {
    handleScroll(event) {
      const element = event.target
      const scrollTop = element.scrollTop
      const scrollHeight = element.scrollHeight
      const clientHeight = element.clientHeight
      // 允许5px的误差
      if (scrollTop + clientHeight >= scrollHeight - 5) {
        this.hasScrolledToBottom = true
      }
    },
    agreeDisclaimer() {
      if (this.disclaimerAgreement === '我同意' && this.hasScrolledToBottom) {
        this.disclaimerAgreed = true
        this.disclaimerVisible = false
        ElMessage.success('感谢您的确认')
      }
    },
    onSubmit() {
      if (!this.disclaimerAgreed) {
        ElMessage.warning('请先阅读并同意免责声明')
        this.disclaimerVisible = true
        return
      }
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

.disclaimer-content {
  max-height: 60vh;
  overflow-y: auto;
  padding-right: 10px;
  line-height: 1.8;
}

.disclaimer-content h3 {
  margin-top: 20px;
  margin-bottom: 10px;
  color: var(--el-color-primary);
  font-size: 1.1rem;
}

.disclaimer-content h3:first-child {
  margin-top: 0;
}

.disclaimer-content p {
  margin-bottom: 12px;
  color: var(--el-text-color-primary);
}

.disclaimer-content ul {
  margin: 10px 0;
  padding-left: 25px;
}

.disclaimer-content li {
  margin-bottom: 8px;
  color: var(--el-text-color-regular);
}

.disclaimer-footer {
  margin-top: 30px;
  padding-top: 20px;
  border-top: 1px solid var(--el-border-color);
  text-align: center;
  color: var(--el-text-color-secondary);
}
</style>

