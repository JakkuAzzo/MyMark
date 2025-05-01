import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'

// Updated SERVER_IP to match the IP in the certificate SAN (e.g., 10.154.92.142)
const SERVER_IP = '127.0.2.2';
const keyPath = path.resolve(__dirname, '../server.key');
const certPath = path.resolve(__dirname, '../server.crt');

export default defineConfig({
  plugins: [vue()],
  server: {
    host: '0.0.0.0',
    https: {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(certPath)
    },
    port: 5173,
    proxy: {
      '/api': {
        target: `https://${SERVER_IP}:5000`,
        changeOrigin: true,
        secure: false
      }
    },
    // Add this to serve index.html for unknown routes (SPA fallback)
    fs: {
      strict: false
    },
    historyApiFallback: true
  }
})
