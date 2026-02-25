import { type ThemeConfig, theme } from "antd";

/**
 * SFMS 시스템 전역 다크 테마 설정
 * Ant Design 5의 디자인 토큰 시스템을 사용하여 하드코딩 없이 테마를 관리합니다.
 */
export const darkTheme: ThemeConfig = {
	// 1. AntD 공식 다크 알고리즘 적용 (기본 색상 체계 구축)
	algorithm: theme.darkAlgorithm,

	// 2. Seed & Map Tokens: 앱 전체에 영향을 미치는 공통 색상
	token: {
		colorPrimary: "#1677ff", // 메인 브랜드 컬러 (블루)
		colorInfo: "#1677ff",

		// [중요] 모든 선택된 항목(Select, Menu, Table Row 등)의 배경색
		// 기존에 글씨가 안 보였던 문제를 해결하는 핵심 토큰입니다.
		controlItemBgActive: "#111d2c", // 매우 짙은 블루 그레이 (다크모드 정석 선택색)
		controlItemBgActiveHover: "#162b45",

		// 전체 배경 및 컴포넌트 배경 미세 조정
		colorBgBase: "#000000", // 앱 전체 기본 배경 (완전 블랙)
		colorBgContainer: "#141414", // 카드, 테이블 등 컨테이너 배경
		colorBgElevated: "#1f1f1f", // 모달, 팝업 등 떠있는 요소 배경

		borderRadius: 6, // 전역 모서리 둥글기 통일
	},

	// 3. Component Tokens: 특정 컴포넌트의 고유 스타일 세부 제어
	components: {
		Table: {
			// 테이블 헤더 배경색
			headerBg: "#1d1d1d",
			headerColor: "rgba(255, 255, 255, 0.85)",

			// [핵심] 선택된 행(Row)의 배경색 - 하드코딩 대신 이 토큰을 사용하게 됩니다.
			rowSelectedBg: "#111d2c",
			rowSelectedHoverBg: "#162b45",

			// 행 호버 시 배경색
			rowHoverBg: "#1f1f1f",

			// 테이블 경계선 색상
			borderColor: "#303030",
		},
		Card: {
			// 카드(ProCard 포함) 내부 배경색 통일
			colorBgContainer: "#141414",
			headerFontSize: 16,
		},
		Layout: {
			// ProLayout 사이드바 및 헤더 색상 제어
			colorBgHeader: "#001529",
			colorBgBody: "#000000",
			colorBgTrigger: "#002140",
		},
		Menu: {
			// 사이드 메뉴 선택 시 배경색
			itemSelectedBg: "#111d2c",
			itemSelectedColor: "#1677ff",
		},
	},
};
