import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

/**
 * 인증된 사용자 정보 인터페이스 (백엔드 UserWithPermissions 스키마와 동기화)
 */
export interface UserInfo {
	id: number;
	login_id: string;
	name: string;
	email?: string;
	emp_code?: string;
	org_id?: number | null;
	org_name?: string | null;
	organization_name?: string | null; // 백엔드 매핑 이름
	is_active?: boolean;
	account_status?: string;
	is_superuser?: boolean;
	/** 할당된 역할 코드 목록 */
	roles?: string[];
	/** 리소스별 통합 권한 매트릭스 */
	permissions?: Record<string, string[]>;
}

/**
 * 인증 상태 및 액션 인터페이스
 */
interface AuthState {
	/** 액세스 토큰 */
	accessToken: string | null;
	/** 리프레시 토큰 */
	refreshToken: string | null;
	/** 현재 로그인한 사용자 정보 */
	user: UserInfo | null;
	/** 로그인 여부 */
	isAuthenticated: boolean;

	/** 로그인 처리 액션 */
	setAuth: (accessToken: string, refreshToken: string, user: UserInfo | null) => void;
	/** 로그아웃 처리 액션 (MainLayout.tsx에서 사용) */
	clearAuth: () => void;
	/** 사용자 정보만 업데이트 */
	setUser: (user: UserInfo) => void;
}

/**
 * 전역 인증 상태 관리 훅 (Zustand)
 */
export const useAuthStore = create<AuthState>()(
	persist(
		(set) => ({
			accessToken: null,
			refreshToken: null,
			user: null,
			isAuthenticated: false,

			setAuth: (accessToken, refreshToken, user) =>
				set({
					accessToken,
					refreshToken,
					user,
					isAuthenticated: !!accessToken,
				}),

			clearAuth: () =>
				set({
					accessToken: null,
					refreshToken: null,
					user: null,
					isAuthenticated: false,
				}),

			setUser: (user) => set({ user }),
		}),
		{
			name: "sfms-auth-storage",
			storage: createJSONStorage(() => localStorage),
		},
	),
);
