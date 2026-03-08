/**
 *
 * Axios 인스턴스 (공통 HTTP 요청 설정)
 *
 */

import axios from "axios";
import { message } from "antd";
import { useAuthStore } from "@/shared/stores/useAuthStore";

// Vite Proxy 설정에 맞춰 Base URL 설정
const BASE_URL = "/api/v1";

export const http = axios.create({
	baseURL: BASE_URL,
	headers: {
		"Content-Type": "application/json",
	},
	timeout: 10000, // 10초
});

// [요청 인터셉터] 모든 요청에 인증 토큰 자동 삽입
http.interceptors.request.use(
	(config) => {
		const token = useAuthStore.getState().accessToken;
		if (token) {
			config.headers.Authorization = `Bearer ${token}`;
		}
		return config;
	},
	(error) => Promise.reject(error),
);

// [응답 인터셉터] 공통 에러 처리 및 세션 만료 대응
http.interceptors.response.use(
	(response) => response,
	async (error) => {
		const status = error.response?.status;
		const msg = error.response?.data?.message || "통신 오류가 발생했습니다.";

		if (status === 401) {
			// 토큰이 만료되었거나 없는 경우
			const { clearAuth } = useAuthStore.getState();
			clearAuth();
			
			// 로그인 페이지로 이동 (window.location 사용 권장 - 훅 밖이므로)
			if (!window.location.pathname.includes("/login")) {
				window.location.href = "/login";
			}
		} else if (status >= 500) {
			message.error(`서버 오류: ${msg}`);
		} else {
			// 4xx 에러 등
			message.warning(msg);
		}
		return Promise.reject(error);
	},
);
