import path from "node:path";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
	plugins: [
		react(),
		tsconfigPaths(),
		tailwindcss(), // 2. 플러그인 등록
	],
	resolve: {
		alias: { "@": path.resolve(__dirname, "./src") },
	},
	server: {
		port: 5173,
		proxy: {
			// /api로 시작하는 요청은 FastAPI(8000)로 전달
			"/api": {
				target: "http://localhost:8000",
				changeOrigin: true,
				secure: false,
			},
			// /minio로 시작하는 이미지/파일 요청은 MinIO(9000)로 전달
			"/minio": {
				target: "http://localhost:9000",
				changeOrigin: true,
				secure: false,
			},
		},
	},
});
