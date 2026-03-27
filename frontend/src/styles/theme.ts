import { type ThemeConfig, theme } from "antd";

/**
 * SFMS 테마 타입 정의
 */
export type ThemeMode = "light" | "dark" | "navy" | "gov" | "mac" | "win";

/**
 * 1. Default Light 테마
 */
export const lightTheme: ThemeConfig = {
	algorithm: theme.defaultAlgorithm,
	token: {
		colorPrimary: "#1677ff",
		borderRadius: 6,
		colorBgContainer: "#ffffff",
	},
	components: {
		Table: { headerBg: "#fafafa", borderColor: "#f0f0f0" },
		Layout: { headerBg: "#ffffff", bodyBg: "#f5f5f5" },
		Card: { borderRadiusLG: 12 },
	},
};

/**
 * 2. Pure Dark 테마
 */
export const darkTheme: ThemeConfig = {
	algorithm: theme.darkAlgorithm,
	token: {
		colorPrimary: "#1677ff",
		colorBgBase: "#000000",
		colorBgContainer: "#141414",
		borderRadius: 6,
	},
	components: {
		Card: { borderRadiusLG: 12 },
		Layout: { headerBg: "#001529", bodyBg: "#000000" },
	},
};

/**
 * 3. Deep Navy 테마 (Dark 추천)
 */
export const navyTheme: ThemeConfig = {
	algorithm: theme.darkAlgorithm,
	token: {
		colorPrimary: "#38bdf8",
		colorBgBase: "#0f172a",
		colorBgContainer: "#1e293b",
		colorBgElevated: "#334155",
		borderRadius: 6,
	},
	components: {
		Card: { borderRadiusLG: 12 },
		Layout: {
			headerBg: "#0f172a",
			bodyBg: "#020617",
			siderBg: "#0f172a",
		},
		Table: {
			headerBg: "#1e293b",
			rowHoverBg: "#334155",
		},
	},
};

/**
 * 4. K-Gov 테마 (한국 공공 표준 - Indigo & White)
 */
export const govTheme: ThemeConfig = {
	algorithm: theme.defaultAlgorithm,
	token: {
		colorPrimary: "#1a3a5f", // 정부 신뢰 남색
		colorBgBase: "#f0f4f8", // 깔끔한 미스트 배경
		colorBgContainer: "#ffffff",
		colorInfo: "#1a3a5f",
		borderRadius: 4,
	},
	components: {
		Card: { borderRadiusLG: 8 },
		Layout: {
			headerBg: "#1a3a5f",
			headerColor: "#ffffff",
			bodyBg: "#f0f4f8",
			siderBg: "#ffffff",
		},
		Table: {
			headerBg: "#f8fafc",
			borderColor: "#e2e8f0",
		},
	},
};

/**
 * 5. Soft Mac 테마 (MacOS Style - Off White & Azure)
 */
export const macTheme: ThemeConfig = {
	algorithm: theme.defaultAlgorithm,
	token: {
		colorPrimary: "#007aff",
		colorBgBase: "#f5f5f7",
		colorBgContainer: "#ffffff",
		colorBgLayout: "#f5f5f7",
		colorTextBase: "#1d1d1f",
		borderRadius: 8,
	},
	components: {
		Card: { borderRadiusLG: 12 },
		Layout: {
			headerBg: "rgba(255, 255, 255, 0.8)",
			bodyBg: "#f5f5f7",
			siderBg: "#ffffff",
		},
		Table: {
			headerBg: "#fafafa",
			rowHoverBg: "#f5f5f7",
		},
	},
};

/**
 * 6. Windows Style 테마 (Windows 11 스타일 - Light Blue & Gray)
 */
export const winTheme: ThemeConfig = {
	algorithm: theme.defaultAlgorithm,
	token: {
		colorPrimary: "#0078d4", // Windows Blue
		colorInfo: "#0078d4",    // 정보 알림 강조
		colorLink: "#0078d4",    // 링크 색상
		colorBgBase: "#f3f3f3",  // Windows 11 배경색 (Mica 효과 대체)
		colorBgContainer: "#ffffff",
		colorBgLayout: "#f3f3f3",
		colorTextBase: "#000000",
		borderRadius: 4,         // 윈도우의 절제된 곡률
	},
	components: {
		Card: {
			borderRadiusLG: 12, // Bento Standard v1.1 준수
			boxShadow: "0 2px 8px rgba(0, 0, 0, 0.08)", // 윈도우 스타일의 부드러운 그림자
		},
		Layout: {
			headerBg: "#ffffff",
			bodyBg: "#f3f3f3",
			siderBg: "#eeeeee",
		},
		Table: {
			headerBg: "#ffffff",
			headerColor: "#000000",
			rowHoverBg: "#e5e5e5",
			borderColor: "#d2d2d2",
		},
		Button: {
			borderRadius: 4,
			colorPrimaryHover: "#005a9e", // 윈도우 블루 호버 (조금 더 어두운 파랑)
			colorPrimaryActive: "#004578", // 윈도우 블루 클릭 (더 어두운 파랑)
		},
		Input: {
			borderRadius: 4,
			activeBorderColor: "#0078d4",
		},
		Menu: {
			itemSelectedBg: "#e5e5e5",
			itemSelectedColor: "#0078d4",
		},
		Tabs: {
			itemSelectedColor: "#0078d4",
			inkBarColor: "#0078d4",
		},
	},
};

/**
 * 모드에 따른 테마 설정 반환
 */
export const getThemeConfig = (mode: ThemeMode): ThemeConfig => {
	switch (mode) {
		case "light":
			return lightTheme;
		case "dark":
			return darkTheme;
		case "navy":
			return navyTheme;
		case "gov":
			return govTheme;
		case "mac":
			return macTheme;
		case "win":
			return winTheme;
		default:
			return navyTheme;
	}
};
