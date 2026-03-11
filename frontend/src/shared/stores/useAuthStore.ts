import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

/**
 * 인증된 사용자 정보 인터페이스
 */
interface UserInfo {
    id: number;
    login_id: string;
    name: string;
    email: string;
    org_id: number | null;
    organization_name: string | null;
    is_superuser: boolean;
    /** 할당된 역할 코드 목록 */
    roles: string[];
    /** 리소스별 통합 권한 매트릭스 (예: { USR: ["READ", "WRITE"] }) */
    permissions: Record<string, string[]>;
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
    setAuth: (accessToken: string, refreshToken: string, user: UserInfo) => void;
    /** 로그아웃 처리 액션 */
    clearAuth: () => void;
    /** 사용자 정보만 업데이트 */
    setUser: (user: UserInfo) => void;
}

/**
 * 전역 인증 상태 관리 훅 (Zustand)
 *
 * @description 로컬 스토리지를 통해 토큰 정보를 유지하며, API 요청 시 전역에서 참조됩니다.
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
                    isAuthenticated: true,
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
            name: "sfms-auth-storage", // 로컬 스토리지 키 이름
            storage: createJSONStorage(() => localStorage),
        },
    ),
);
