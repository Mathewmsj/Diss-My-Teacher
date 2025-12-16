import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import App from './App.vue'
import Ranking from './views/Ranking.vue'
import TeacherDetail from './views/TeacherDetail.vue'
import Login from './views/Login.vue'
import SuperAdminLogin from './views/SuperAdminLogin.vue'
import Signup from './views/Signup.vue'
import Profile from './views/Profile.vue'
import AdminPanel from './views/AdminPanel.vue'
import SuperAdminPanel from './views/SuperAdminPanel.vue'
import './style.css'

const routes = [
  { path: '/login', component: Login },
  { path: '/superadmin-login', component: SuperAdminLogin },
  { path: '/signup', component: Signup },
  { path: '/', component: Ranking, meta: { requiresAuth: true } },
  { path: '/teacher/:id', component: TeacherDetail, meta: { requiresAuth: true } },
  { path: '/admin', component: AdminPanel, meta: { requiresAuth: true, admin: true } },
  { path: '/superadmin', component: SuperAdminPanel, meta: { requiresAuth: true, superAdmin: true } },
  { path: '/profile', component: Profile, meta: { requiresAuth: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：检查用户是否已登录
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('authToken')
  const isAdmin = localStorage.getItem('isAdmin') === '1'
  const isSuperAdmin = localStorage.getItem('isSuperAdmin') === '1'
  const disclaimerAgreed = localStorage.getItem('disclaimerAgreed') === '1'
  
  if (to.meta.requiresAuth && !token) return next('/login')
  if (to.meta.admin && !isAdmin) return next('/')
  if (to.meta.superAdmin && !isSuperAdmin) return next('/')
  
  // 已登录但未同意免责声明，阻止访问（登录页面除外）
  if (token && !disclaimerAgreed && to.path !== '/login' && to.path !== '/signup' && to.path !== '/superadmin-login') {
    // 如果不在登录相关页面，允许进入但会在 App.vue 中显示免责声明
    // 这里不阻止，让 App.vue 的 checkDisclaimer 处理
  }
  
  // 已登录访问登录/注册时重定向首页
  if (token && disclaimerAgreed && (to.path === '/login' || to.path === '/signup' || to.path === '/superadmin-login')) {
    if (isSuperAdmin) return next('/superadmin')
    return next('/')
  }
  return next()
})

const app = createApp(App)
app.use(router)
app.use(ElementPlus)

// 注册所有图标
for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.mount('#app')
