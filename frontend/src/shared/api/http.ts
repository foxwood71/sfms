/**
 *
 * Axios 인스턴스 (공통 HTTP 요청 설정)
 *
 */

import axios from "axios";
import { message } from "antd"; // Ant Design의 알림 기능 활용

// Vite Proxy 설정에 맞춰 Base URL 설정 (/api -> http://localhost:8000/api)
const BASE_URL = "/api/v1";

export const http = axios.create({
  baseURL: BASE_URL,
  headers: {
    "Content-Type": "application/json",
  },
  timeout: 5000, // 5초 안에 응답 없으면 에러 처리
});

// [요청 인터셉터] 요청 보내기 전 실행 (예: 토큰 실어 보내기)
http.interceptors.request.use(
  (config) => {
    // 나중에 여기에 JWT 토큰 로직 추가:
    // const token = localStorage.getItem('accessToken');
    // if (token) config.headers.Authorization = `Bearer ${token}`;
    return config;
  },
  (error) => Promise.reject(error),
);

// [응답 인터셉터] 응답 받은 후 실행 (예: 공통 에러 처리)
http.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const msg =
      error.response?.data?.detail || "서버 통신 오류가 발생했습니다.";

    if (status === 401) {
      message.error("인증이 만료되었습니다. 다시 로그인해주세요.");
      // 로그인 페이지로 리다이렉트 로직 추가 가능
    } else if (status >= 500) {
      message.error(`서버 오류: ${msg}`);
    } else {
      message.warning(msg);
    }
    return Promise.reject(error);
  },
);
