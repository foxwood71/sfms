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
        controlItemBgActive: "#111d2c",
        controlItemBgActiveHover: "#162b45",

        // 전체 배경 및 컴포넌트 배경 미세 조정
        colorBgBase: "#000000",
        colorBgContainer: "#141414",
        colorBgElevated: "#1f1f1f",

        borderRadius: 6,
    },

    // 3. Component Tokens: 특정 컴포넌트의 고유 스타일 세부 제어
    components: {
        Table: {
            headerBg: "#1d1d1d",
            headerColor: "rgba(255, 255, 255, 0.85)",
            rowSelectedBg: "#111d2c",
            rowSelectedHoverBg: "#162b45",
            rowHoverBg: "#1f1f1f",
            borderColor: "#303030",
        },
        Card: {
            colorBgContainer: "#141414",
            headerFontSize: 16,
        },
        Layout: {
            headerBg: "#001529",
            bodyBg: "#000000",
            triggerBg: "#002140",
        },
        Menu: {
            itemSelectedBg: "#111d2c",
            itemSelectedColor: "#1677ff",
        },
    },
};

/**
 * SFMS 시스템 전역 라이트 테마 설정
 */
export const lightTheme: ThemeConfig = {
    // 1. AntD 공식 기본 알고리즘 적용
    algorithm: theme.defaultAlgorithm,

    // 2. Seed & Map Tokens
    token: {
        colorPrimary: "#1677ff",
        colorInfo: "#1677ff",
        borderRadius: 6,
        colorBgContainer: "#ffffff",
    },

    // 3. Component Tokens
    components: {
        Table: {
            headerBg: "#fafafa",
            borderColor: "#f0f0f0",
        },
        Layout: {
            headerBg: "#ffffff",
            bodyBg: "#f5f5f5",
        },
    },
};

/**
 * 테마 모드에 따른 Ant Design ThemeConfig 반환 함수
 *
 * @param mode 'light' 또는 'dark'
 * @returns Ant Design 테마 설정 객체
 */
export const getThemeConfig = (mode: "light" | "dark"): ThemeConfig => {
    return mode === "dark" ? darkTheme : lightTheme;
};
