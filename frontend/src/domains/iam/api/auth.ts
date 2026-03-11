import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types"; // 아직 없으면 생성 필요

/**
 * 로그인 요청 데이터 인터페이스
 */
export interface LoginParams {
    login_id: string;
    password: string;
}

/**
 * 로그인 성공 시 반환되는 토큰 정보
 */
export interface LoginResult {
    access_token: string;
    refresh_token: string;
    expires_in: number;
    token_type: string;
}

/**
 * 사용자 인증 API
 *
 * @param params { login_id, password }
 * @returns { access_token, refresh_token, ... }
 */
export const loginApi = async (params: LoginParams): Promise<LoginResult> => {
    const response = await http.post<APIResponse<LoginResult>>("/auth/login", params);
    return response.data.data;
};

/**
 * 현재 로그인한 사용자 정보 조회 API
 *
 * @returns 사용자 상세 정보
 */
export const getMeApi = async () => {
    const response = await http.get("/auth/me");
    return response.data.data;
};
