/**
 * 조직(Organization) 도메인 타입 정의
 */
export interface Organization {
    id: number;
    name: string;
    code: string;
    parent_id: number | null;
    sort_order: number;
    description: string | null; // 추가
    is_active: boolean;
    children?: Organization[];
    created_at: string;
    updated_at: string;
    created_by: number | null;
    updated_by: number | null;
}

/**
 * 사용자(User) 도메인 타입 정의
 */
export interface User {
    id: number;
    login_id: string;
    emp_code: string;
    name: string;
    email: string | null;
    phone?: string | null; // 추가
    org_id: number;
    org_name?: string;
    is_active: boolean;
    account_status: string; // 추가
    profile_image_id?: string | null;
    metadata?: Record<string, any>;
    roles?: { id: number; name: string; code: string }[]; // 추가
    created_at: string;
    updated_at: string;
}

/**
 * 역할 및 통합 권한 정보를 포함하는 사용자 타입
 */
export interface UserWithPermissions extends User {
    roles: string[];
    permissions: Record<string, string[]>;
}

/**
 * 사용자 생성 요청 DTO
 */
export interface CreateUserParams {
    login_id: string;
    password?: string;
    emp_code: string;
    name: string;
    email?: string;
    org_id: number;
    is_active?: boolean;
    profile_id?: string;
    metadata?: Record<string, unknown>;}

/**
 * 사용자 수정 요청 DTO
 */
export interface UpdateUserParams extends Partial<CreateUserParams> {
    id: number;
}

/**
 * 조직 생성 요청 DTO
 */
export interface CreateOrgParams {
    name: string;
    code: string;
    parent_id?: number | null;
    sort_order?: number;
    description?: string | null; // 추가
    is_active?: boolean;
}

/**
 * 조직 수정 요청 DTO
 */
export interface UpdateOrgParams extends Partial<CreateOrgParams> {
    id: number;
}
