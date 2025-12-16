import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0', // 监听所有网络接口
    port: 8080, // 使用更常见的端口，防火墙通常允许
    open: true
  }
})
