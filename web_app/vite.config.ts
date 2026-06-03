import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => ({
  plugins: [react()],
  // In production the app is served from /app/ on the combined Netlify site
  base: mode === 'production' ? '/app/' : '/',
  server: {
    port: 5173,
    host: true,
    proxy: {
      // ── PocketBase proxy ─────────────────────────────────────────────────
      // All PocketBase SDK calls go to localhost:5174/pb-proxy/... (same-origin).
      // Vite forwards them server-side to localhost:8091/...
      // Result: no CORS, PocketBase URL never appears in the browser network tab,
      //         and the auth token is only sent to your own origin.
      '/pb-proxy': {
        target: 'http://localhost:8091',
        changeOrigin: true,
        ws: true, // also proxy SSE/WebSocket (PocketBase realtime)
        rewrite: (path) => path.replace(/^\/pb-proxy/, ''),
      },

      // ── Next.js API proxy ────────────────────────────────────────────────
      // All fetch(`/api/...`) calls are forwarded to the Next.js server on 3040.
      // No CORS preflight needed — the browser sees it as same-origin.
      '/api': {
        target: 'http://localhost:3040',
        changeOrigin: true,
        // No rewrite — /api/kyc/submit → /api/kyc/submit on Next.js
      },
    },
  },
}))
