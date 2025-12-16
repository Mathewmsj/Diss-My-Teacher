<template>
  <div class="app">
    <header class="header" v-if="isAuthenticated">
      <div class="container">
        <div class="logo" @click="$router.push('/')">
          <h1>Diss My Teacher</h1>
        </div>
        <nav class="nav">
          <router-link v-if="!isSuperAdmin" to="/" class="nav-item">首页</router-link>
          <router-link v-if="isAdmin && !isSuperAdmin" to="/admin" class="nav-item">管理员</router-link>
          <router-link v-if="isSuperAdmin" to="/superadmin" class="nav-item">超级管理员</router-link>
          <router-link v-if="!isSuperAdmin" to="/profile" class="nav-item">个人中心</router-link>
          <div class="nav-actions">
            <el-button type="text" size="small" @click="showFeedback">建议反馈</el-button>
            <el-button type="text" size="small" @click="handleLogout">退出登录</el-button>
          </div>
        </nav>
      </div>
    </header>
    <main class="main">
      <router-view />
    </main>

    <!-- 免责声明对话框 - 登录时必须同意 -->
    <el-dialog
      v-model="disclaimerVisible"
      title="免责声明"
      width="700px"
      :close-on-click-modal="!disclaimerRequired"
      :close-on-press-escape="!disclaimerRequired"
      :show-close="!disclaimerRequired"
      :modal="true"
    >
      <div class="disclaimer-content">
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
        <el-button type="primary" @click="agreeDisclaimer">我已阅读并同意</el-button>
      </template>
    </el-dialog>

    <!-- 建议反馈对话框 -->
    <el-dialog
      v-model="feedbackVisible"
      title="建议反馈"
      width="600px"
      :close-on-click-modal="false"
    >
      <el-form :model="feedbackForm" label-width="100px">
        <el-form-item label="反馈类型">
          <el-select v-model="feedbackForm.type" placeholder="请选择反馈类型">
            <el-option label="功能建议" value="feature" />
            <el-option label="问题反馈" value="bug" />
            <el-option label="其他" value="other" />
          </el-select>
        </el-form-item>
        <el-form-item label="反馈内容" required>
          <el-input
            v-model="feedbackForm.content"
            type="textarea"
            :rows="6"
            placeholder="请输入您的建议或反馈..."
            maxlength="500"
            show-word-limit
          />
        </el-form-item>
        <el-form-item label="联系方式（可选）">
          <el-input v-model="feedbackForm.contact" placeholder="邮箱或QQ等，方便我们回复您" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="feedbackVisible = false">取消</el-button>
        <el-button type="primary" :loading="feedbackLoading" @click="submitFeedback">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import { ElMessage } from 'element-plus'

export default {
  name: 'App',
  data() {
    return {
      isAuthenticated: false,
      isAdmin: false,
      isSuperAdmin: false,
      disclaimerVisible: false,
      disclaimerRequired: false, // 是否为登录时必须同意的免责声明
      feedbackVisible: false,
      feedbackLoading: false,
      feedbackForm: {
        type: '',
        content: '',
        contact: ''
      }
    }
  },
  mounted() {
    this.checkAuth()
    // 监听路由变化，更新认证状态
    this.$router.afterEach(() => {
      this.checkAuth()
      // 检查是否需要显示免责声明
      this.checkDisclaimer()
    })
    // 初始检查免责声明
    this.checkDisclaimer()
  },
  methods: {
    checkAuth() {
      this.isAuthenticated = !!localStorage.getItem('authToken')
      this.isAdmin = localStorage.getItem('isAdmin') === '1'
      this.isSuperAdmin = localStorage.getItem('isSuperAdmin') === '1'
    },
    checkDisclaimer() {
      // 如果用户已登录但未同意免责声明，则显示（必须同意）
      if (this.isAuthenticated && !localStorage.getItem('disclaimerAgreed')) {
        this.disclaimerRequired = true
        this.disclaimerVisible = true
      }
    },
    agreeDisclaimer() {
      // 记录用户已同意免责声明
      localStorage.setItem('disclaimerAgreed', '1')
      this.disclaimerRequired = false
      this.disclaimerVisible = false
      ElMessage.success('感谢您的确认，欢迎使用本网站！')
    },
    handleLogout() {
      localStorage.removeItem('authToken')
      localStorage.removeItem('isAdmin')
      localStorage.removeItem('isSuperAdmin')
      localStorage.removeItem('adminSchoolCode')
      localStorage.removeItem('disclaimerAgreed') // 退出登录时清除同意记录，下次登录需重新同意
      this.isAuthenticated = false
      this.isAdmin = false
      this.isSuperAdmin = false
      ElMessage.success('已退出登录')
      this.$router.push('/login')
    },
    showDisclaimer() {
      // 手动查看免责声明时，允许关闭
      this.disclaimerRequired = false
      this.disclaimerVisible = true
    },
    showFeedback() {
      this.feedbackForm = {
        type: '',
        content: '',
        contact: ''
      }
      this.feedbackVisible = true
    },
    async submitFeedback() {
      if (!this.feedbackForm.content.trim()) {
        ElMessage.warning('请输入反馈内容')
        return
      }
      this.feedbackLoading = true
      try {
        // 这里可以调用后端API保存反馈，暂时只显示成功消息
        // await api.submitFeedback(this.feedbackForm)
        await new Promise(resolve => setTimeout(resolve, 500)) // 模拟API调用
        ElMessage.success('感谢您的反馈，我们会认真考虑您的建议！')
        this.feedbackVisible = false
      } catch (err) {
        ElMessage.error(err.message || '提交失败，请稍后重试')
      } finally {
        this.feedbackLoading = false
      }
    }
  }
}
</script>

<style scoped>
.logo {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}
.logo h1 {
  margin: 0;
}

.nav-actions {
  display: flex;
  align-items: center;
  gap: 8px;
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
