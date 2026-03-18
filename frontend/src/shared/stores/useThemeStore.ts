import { create } from "zustand";
import { persist } from "zustand/middleware";

/**
 * 테마 모드 타입 정의
 */
export type ThemeMode = "light" | "dark" | "navy" | "gov" | "mac";

/**
 * 테마 상태 관리를 위한 인터페이스
 */
interface ThemeState {
	/** 현재 테마 모드 */
	theme: ThemeMode;
	/** 테마 모드 변경 함수 */
	setTheme: (theme: ThemeMode) => void;
}

/**
 * SFMS 시스템 전역 테마 상태 저장소 (Zustand)
 */
export const useThemeStore = create<ThemeState>()(
	persist(
		(set) => ({
			// 기본 테마: 네이비 (추천 테마를 기본으로 변경)
			theme: "navy",

			setTheme: (theme) => set({ theme }),
		}),
		{
			name: "sfms-theme-storage",
		},
	),
);
