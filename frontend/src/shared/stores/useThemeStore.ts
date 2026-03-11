import { create } from "zustand";
import { persist } from "zustand/middleware";

/**
 * 테마 모드 타입 정의
 */
export type ThemeMode = "light" | "dark";

/**
 * 테마 상태 관리를 위한 인터페이스
 */
interface ThemeState {
    /** 현재 테마 모드 */
    theme: ThemeMode;
    /** 테마 모드 변경 함수 */
    setTheme: (theme: ThemeMode) => void;
    /** 테마 모드 토글 함수 */
    toggleTheme: () => void;
}

/**
 * SFMS 시스템 전역 테마 상태 저장소 (Zustand)
 *
 * @description 로컬 스토리지를 통해 사용자의 테마 설정을 유지하며,
 * Ant Design ConfigProvider와 연동하여 실시간 테마 변경을 지원합니다.
 */
export const useThemeStore = create<ThemeState>()(
    persist(
        (set) => ({
            // 기본 테마: 다크 (프로젝트 기본값)
            theme: "dark",

            setTheme: (theme) => set({ theme }),

            toggleTheme: () =>
                set((state) => ({
                    theme: state.theme === "light" ? "dark" : "light",
                })),
        }),
        {
            name: "sfms-theme-storage", // 로컬 스토리지 키 이름
        },
    ),
);
