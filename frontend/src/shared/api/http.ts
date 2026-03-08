/**
 *
 * Axios 인스턴스 (공통 HTTP 요청 설정)
 *
 */

import axios from "axios";
import { message } from "antd";
import { useAuthStore } from "@/shared/stores/useAuthStore";

const BASE_URL = "/api/v1";

export const http = axios.create({
	baseURL: BASE_URL,
	headers: {
		"Content-Type": "application/json",
	},
	timeout: 10000,
});

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

http.interceptors.response.use(
	(response) => response,
	async (error) => {
		const status = error.response?.status;
		const serverMessage = error.response?.data?.message;
		const defaultMessage = error.message || "알 수 없는 오류가 발생했습니다.";
		const displayMsg = serverMessage || defaultMessage;

		// [글로벌 처리] 인증 및 서버 자체 장애만 인터셉터에서 알림
		if (status === 401) {
			const { clearAuth } = useAuthStore.getState();
			clearAuth();
			if (!window.location.pathname.includes("/login")) {
				message.error("세션이 만료되었습니다. 다시 로그인해주세요.");
				window.location.href = "/login";
			}
		} else if (status >= 500) {
			message.error(`시스템 서버 오류: ${displayMsg}`);
		} else if (error.code === "ECONNABORTED") {
			message.error("요청 시간이 초과되었습니다.");
		} else if (!error.response) {
			message.error("서버와 연결할 수 없습니다.");
		}

		// 비즈니스 에러(400, 409, 422 등)는 UI에서 직접 처리하도록 에러만 반환
		return Promise.reject(error);
	},
);
