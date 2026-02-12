import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";

// https://vite.dev/config/
/** @type {import('vite').UserConfig} */
export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  server: {
    proxy: {
      // '/api'로 시작하는 요청은 백엔드(8000)로 전달
      "/api": {
        target: "http://localhost:8000",
        changeOrigin: true,
        secure: false,
        // 만약 백엔드에서 /api 접두사를 안 쓴다면 아래 주석 해제
        // rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
});
