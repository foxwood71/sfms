import type { LoginResponse, Role } from "@/domains/iam/types";
import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";

/**
 * 로그인 실행 API (Zero Any 적용)
 */
export const loginApi = (payload: object): Promise<APIResponse<LoginResponse>> => 
    http.post("/auth/login", payload).then(res => res.data);

/**
 * 로그아웃 실행 API (보안 강화를 위해 리프레시 토큰 전달)
 */
export const logoutApi = (refreshToken?: string | null): Promise<APIResponse<null>> => 
    http.post("/auth/logout", { refresh_token: refreshToken }).then(res => res.data);

/**
 * 현재 로그인된 본인 정보 조회 API
 */
export const getMeApi = (token?: string): Promise<APIResponse<LoginResponse["user"]>> => {
    const headers = token ? { Authorization: `Bearer ${token}` } : {};
    return http.get("/auth/me", { headers }).then(res => res.data);
};

/**
 * 시스템 전체 역할 목록 조회
 */
export const getRolesApi = async (): Promise<Role[]> => {
    const res = await http.get<APIResponse<Role[]>>("/iam/roles");
    return res.data.data;
};

/**
 * 특정 사용자의 역할 할당 변경
 * @param userId 대상 사용자 ID
 * @param roleIds 할당할 역할 ID 리스트
 */
export const assignUserRolesApi = (userId: number, roleIds: number[]): Promise<APIResponse<null>> =>
    http.post(`/iam/users/${userId}/roles`, { role_ids: roleIds }).then(res => res.data);
