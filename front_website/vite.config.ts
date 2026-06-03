import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  // Serve the original Front website folder as the static asset root
  // so /assets/img/..., /logo.png, /assets/css/... all resolve correctly
  publicDir: path.resolve(__dirname, '../Front website'),
  server: {
    port: 3000,
    host: true,
  },
})
