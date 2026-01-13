import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0', // 监听所有网络接口
    port: parseInt(process.env.PORT) || 8080, // 支持环境变量 PORT，默认 8080
    open: false, // 服务器部署时不自动打开浏览器
    // 允许的域名列表
    allowedHosts: [
      'mathew.yunguhs.com',
      'yunguhs.com',
      'localhost',
      '127.0.0.1',
      '110.40.153.38'
    ],
    watch: {
      // 排除虚拟环境目录，避免文件监控限制问题
      ignored: ['**/backend-env/**', '**/node_modules/**', '**/.git/**']
    }
  }
})
