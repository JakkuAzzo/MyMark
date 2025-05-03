import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import fs from 'fs'
import path from 'path'
import child_process from 'child_process'

// Dynamically extract all SAN IPs from the certificate
function getSanIpsFromCert(certPath) {
  try {
    const output = child_process.execSync(
      `openssl x509 -in "${certPath}" -noout -text | grep "IP Address"`,
      { encoding: 'utf8' }
    );
    // Example output: "                DNS:localhost, IP Address:127.0.0.1, IP Address:127.0.2.2, IP Address:192.168.0.120"
    return output
      .split(',')
      .map(s => s.trim())
      .filter(s => s.startsWith('IP Address:'))
      .map(s => s.replace('IP Address:', '').trim());
  } catch (e) {
    // Fallback to localhost if cert not found or openssl not available
    return ['127.0.0.1'];
  }
}

const keyPath = path.resolve(__dirname, '../server.key');
const certPath = path.resolve(__dirname, '../server.crt');
const SAN_IPS = getSanIpsFromCert(certPath);

// Helper: pick the correct backend target based on request Host header
function getProxyTarget(req) {
  const host = req.headers.host?.split(':')[0];
  if (SAN_IPS.includes(host)) {
    return `https://${host}:5050`;
  }
  return `https://${SAN_IPS[0]}:5050`;
}

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
        target: `https://${SAN_IPS[0]}:5050`, // fallback
        changeOrigin: true,
        secure: false,
        configure: (proxy, options) => {
          proxy.on('proxyReq', (proxyReq, req, res) => {
            proxy.options.target = getProxyTarget(req);
          });
        }
      }
    },
    fs: {
      strict: false
    },
    historyApiFallback: true
  }
})
