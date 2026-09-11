import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import https from 'node:https';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const snowflakeUrl = env.VITE_SNOWFLAKE_ACCOUNT_URL || 'https://ELAXJLQ-SF16912.snowflakecomputing.com';

  // Force a fresh TLS connection per request — prevents ECONNRESET
  const agent = new https.Agent({
    keepAlive: false,
    rejectUnauthorized: true,
  });

  return {
    plugins: [react()],
    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: snowflakeUrl,
          changeOrigin: true,
          secure: true,
          agent,
          timeout: 0,
          proxyTimeout: 0,
          configure: (proxy) => {
            proxy.on('error', (err, _req, res) => {
              console.warn('[proxy]', err.message);
              if (res && 'writeHead' in res && !res.headersSent) {
                res.writeHead(502, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ message: 'Proxy error — retrying' }));
              }
            });
          },
        },
      },
    },
  };
});
