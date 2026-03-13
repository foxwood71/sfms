/**
 * 권한(Permission) 정보 인터페이스
 */
export interface Permission {
	id: number;
	resource: string;
	action: string;
	description?: string;
}

/**
 * 역할(Role) 정보 인터페이스
 */
export interface Role {
	id: number;
	name: string;
	code: string;
	description?: string;
	permissions?: Permission[];
}

/**
 * 로그인 폼 입력 값 인터페이스
 */
export interface LoginFormValues {
	login_id: string;
	password: string;
	remember?: boolean;
}

/**
 * 로그인 성공 시 서버 응답 인터페이스
 */
export interface LoginResponse {
	access_token: string;
	refresh_token: string;
	token_type: string;
	user: {
		id: number;
		login_id: string;
		name: string;
		email?: string;
		emp_code?: string;
		org_id?: number | null;
		org_name?: string | null;
		is_active?: boolean;
		is_superuser?: boolean;
		roles?: string[];
		permissions?: Record<string, string[]>;
	};
}
