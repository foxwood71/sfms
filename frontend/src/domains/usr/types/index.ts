import type { Role } from "@/domains/iam/types";

/**
 * 사용자 계정 상태
 */
export type AccountStatus = "ACTIVE" | "BLOCKED";

/**
 * 사용자 상세 정보 인터페이스
 */
export interface User {
    id: number;
    login_id: string;
    name: string;
    emp_code: string;
    email: string;
    phone?: string;
    org_id?: number;
    org_name?: string;
    is_active: boolean;
    account_status: AccountStatus;
    profile_image_id?: string;
    last_login_at?: string;
    created_at: string;
    updated_at: string;
    /** JSONB로 관리되는 추가 속성 */
    metadata?: {
        pos?: string;  // 직위/직급 코드
        duty?: string; // 직책 코드
        [key: string]: any; // 추후 확장을 위해 허용 (메타데이터 특성)
    };
    /** 할당된 역할 리스트 */
    roles?: Role[];
}

/**
 * 조직(부서) 정보 인터페이스
 */
export interface Organization {
    id: number;
    name: string;
    code: string;
    parent_id?: number;
    parent_name?: string;
    sort_order: number;
    description?: string;
    is_active: boolean;
    children?: Organization[];
    created_at?: string;
    updated_at?: string;
}

/**
 * 조직 생성 파라미터
 */
export interface CreateOrgParams {
    name: string;
    code: string;
    parent_id?: number | null;
    sort_order?: number;
    description?: string;
    is_active?: boolean;
}

/**
 * 조직 수정 파라미터
 */
export interface UpdateOrgParams extends Partial<CreateOrgParams> {}

/**
 * 신규 사용자 생성 파라미터
 */
export interface CreateUserParams {
    login_id: string;
    name: string;
    emp_code: string;
    email: string;
    password?: string;
    phone?: string;
    org_id?: number;
    is_active?: boolean;
    account_status?: AccountStatus;
    profile_image_id?: string;
    metadata?: Record<string, any>;
    role_ids?: number[];
}

/**
 * 사용자 정보 수정 파라미터
 */
export interface UpdateUserParams extends Partial<Omit<CreateUserParams, "login_id" | "password">> {
    password?: string; // 비밀번호는 별도 API로 처리하지만 스키마에는 존재 가능
}

/**
 * 사용자 상세 드로어 폼 값 인터페이스 (UI 전용)
 */
export interface UserFormValues extends CreateUserParams {
    /** 폼에서 CodeSelect와 매핑하기 위한 임시 필드 */
    pos?: string;
    duty?: string;
}
