import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'

const SERVER_IP = '127.0.2.2';

export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0',
    https: {
      key: fs.readFileSync('../server.key'),
      cert: fs.readFileSync('../server.crt')
    },
    port: 5173,
    proxy: {
      '/api': {
        target: `https://${SERVER_IP}:5000`,
        changeOrigin: true,
        secure: false
      }
    }
  }
})
