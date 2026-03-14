import axios from "axios";
import type { AxiosError, AxiosInstance, InternalAxiosRequestConfig } from "axios";
import { useAuthStore } from "../stores/useAuthStore";
import type { APIErrorResponse } from "../types/api";
import { MESSAGES, getErrorMessage } from "../locales/i18n-utils";
import { message } from "antd";

/**
 * SFMS 전역 HTTP 클라이언트 인스턴스 (Axios)
 */
export const http: AxiosInstance = axios.create({
	baseURL: "/api/v1",
	timeout: 10000,
	headers: {
		"Content-Type": "application/json",
	},
});

// 토큰 갱신 중임을 나타내는 플래그 및 대기 중인 요청 큐
let isRefreshing = false;
let failedQueue: any[] = [];

const processQueue = (error: any, token: string | null = null) => {
	failedQueue.forEach((prom) => {
		if (error) {
			prom.reject(error);
		} else {
			prom.resolve(token);
		}
	});
	failedQueue = [];
};

/**
 * 요청 인터셉터
 */
http.interceptors.request.use(
	(config: InternalAxiosRequestConfig) => {
		// 이미 Authorization 헤더가 있는지 확인
		const currentAuth = config.headers.get("Authorization") || config.headers.get("authorization");
		
		if (currentAuth) {
			return config;
		}

		// 스토어에서 토큰 가져오기
		const token = useAuthStore.getState().accessToken;
		if (token) {
			config.headers.set("Authorization", `Bearer ${token}`);
		}
		
		return config;
	},
	(error: unknown) => Promise.reject(error),
);

/**
 * 응답 인터셉터
 */
http.interceptors.response.use(
	(response) => response,
	async (error: AxiosError<APIErrorResponse>) => {
		const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

		// 401 에러 발생 시 토큰 자동 갱신 시도
		if (error.response?.status === 401 && !originalRequest._retry) {
			// 로그인 페이지 요청이거나 이미 재시도한 요청인 경우 중단
			if (window.location.pathname.includes("/login")) {
				return Promise.reject(error);
			}

			if (isRefreshing) {
				// 이미 다른 요청이 갱신 중이라면 큐에 추가
				return new Promise((resolve, reject) => {
					failedQueue.push({ resolve, reject });
				})
					.then((token) => {
						originalRequest.headers.set("Authorization", `Bearer ${token}`);
						return http(originalRequest);
					})
					.catch((err) => Promise.reject(err));
			}

			originalRequest._retry = true;
			isRefreshing = true;

			const refreshToken = useAuthStore.getState().refreshToken;

			if (!refreshToken) {
				isRefreshing = false;
				useAuthStore.getState().clearAuth();
				window.location.href = "/login";
				return Promise.reject(error);
			}

			try {
				// 토큰 갱신 API 호출 (직접 axios 사용하여 인터셉터 무한루프 방지)
				const response = await axios.post("/api/v1/auth/refresh", { refresh_token: refreshToken });
				const { access_token, refresh_token } = response.data.data;

				// 스토어 갱신
				useAuthStore.getState().setAuth(access_token, refresh_token, useAuthStore.getState().user);

				// 대기 중이던 요청 처리
				processQueue(null, access_token);
				
				// 현재 실패했던 요청 재시도
				originalRequest.headers.set("Authorization", `Bearer ${access_token}`);
				return http(originalRequest);
			} catch (refreshError) {
				processQueue(refreshError, null);
				useAuthStore.getState().clearAuth();
				message.error(MESSAGES.AUTH.SESSION_EXPIRED);
				window.location.href = "/login";
				return Promise.reject(refreshError);
			} finally {
				isRefreshing = false;
			}
		}

		// 에러 메시지 번역 처리
		const errorKey = error.response?.data?.message;
		if (errorKey) {
			const translatedMessage = getErrorMessage(errorKey);
			if (error.response?.data) {
				error.response.data.message = translatedMessage;
			}
		}

		return Promise.reject(error);
	},
);
