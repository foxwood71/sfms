import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type { UserWithPermissions } from "@/domains/usr/types";

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
 */
export const loginApi = async (params: LoginParams): Promise<LoginResult> => {
	const response = await http.post<APIResponse<LoginResult>>("/auth/login", params);
	return response.data.data;
};

/**
 * 현재 로그인한 사용자 정보 조회 API
 * 
 * @param token - 로그인 직후 store 업데이트 전일 경우 직접 전달할 토큰
 * @returns 사용자 상세 정보
 */
export const getMeApi = async (token?: string): Promise<UserWithPermissions> => {
	const config = token ? { headers: { Authorization: `Bearer ${token}` } } : {};
	const response = await http.get<APIResponse<UserWithPermissions>>("/auth/me", config);
	return response.data.data;
};

/**
 * 전체 역할 목록 조회 API
 */
export const getRolesApi = async (): Promise<any[]> => {
	const response = await http.get<APIResponse<any[]>>("/roles");
	return response.data.data;
};

/**
 * 사용자별 역할 할당 API
 */
export const assignUserRolesApi = async (userId: number, roleIds: number[]): Promise<void> => {
	await http.put(`/roles/users/${userId}/roles`, { user_id: userId, role_ids: roleIds });
};
