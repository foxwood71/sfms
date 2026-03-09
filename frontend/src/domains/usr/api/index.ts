import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type {
	CreateOrgParams,
	CreateUserParams,
	Organization,
	UpdateOrgParams,
	UpdateUserParams,
	User,
} from "../types";

// --- Organizations API ---

/**
 * 조직 목록 조회 (트리 또는 플랫)
 */
export const getOrganizationsApi = async (mode: "tree" | "flat" = "tree", is_active?: boolean) => {
	const response = await http.get<APIResponse<Organization[]>>("/usr/organizations", {
		params: { mode, is_active },
	});
	return response.data;
};

/**
 * 조직 생성
 */
export const createOrganizationApi = async (params: CreateOrgParams) => {
	const response = await http.post<APIResponse<Organization>>("/usr/organizations", params);
	return response.data;
};

/**
 * 조직 정보 수정
 */
export const updateOrganizationApi = async (id: number, params: UpdateOrgParams) => {
	const response = await http.patch<APIResponse<Organization>>(`/usr/organizations/${id}`, params);
	return response.data;
};

/**
 * 조직 삭제
 */
export const deleteOrganizationApi = async (id: number) => {
	const response = await http.delete<APIResponse<void>>(`/usr/organizations/${id}`);
	return response.data;
};

// --- Users API ---

/**
 * 사용자 목록 조회 및 검색 (백엔드 경로: /usr)
 */
export const getUsersApi = async (params: {
	keyword?: string;
	org_id?: number;
	include_children?: boolean;
	is_active?: boolean;
}) => {
	const response = await http.get<APIResponse<User[]>>("/usr", { params });
	return response.data;
};

/**
 * 사용자 상세 조회 (백엔드 경로: /usr/{id})
 */
export const getUserDetailApi = async (id: number) => {
	const response = await http.get<APIResponse<User>>(`/usr/${id}`);
	return response.data;
};

/**
 * 신규 사용자 등록 (백엔드 경로: /usr/users)
 */
export const createUserApi = async (params: CreateUserParams) => {
	const response = await http.post<APIResponse<User>>("/usr/users", params);
	return response.data;
};

/**
 * 사용자 정보 수정 (백엔드 경로: /usr/{id})
 */
export const updateUserApi = async (id: number, params: UpdateUserParams) => {
	const response = await http.patch<APIResponse<User>>(`/usr/${id}`, params);
	return response.data;
};

/**
 * 사용자 계정 비활성화 (백엔드 경로: /usr/{id})
 */
export const deleteUserApi = async (id: number) => {
	const response = await http.delete<APIResponse<void>>(`/usr/${id}`);
	return response.data;
};

/**
 * 비밀번호 변경 (백엔드 경로: /usr/{id}/password)
 */
export const changePasswordApi = async (id: number, params: { current_password?: string; new_password: string }) => {
	const response = await http.put<APIResponse<void>>(`/usr/${id}/password`, params);
	return response.data;
};
