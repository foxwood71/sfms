import { MoonOutlined, SunOutlined } from "@ant-design/icons";
import { Button, Tooltip } from "antd";
import type React from "react";
import { useThemeStore } from "@/shared/stores/useThemeStore";

/**
 * 시스템 테마(다크/라이트) 전환 버튼 컴포넌트
 */
const ThemeToggle: React.FC = () => {
    const { theme: themeMode, toggleTheme } = useThemeStore();
    const isDarkMode = themeMode === "dark";

    return (
        <Tooltip title={isDarkMode ? "라이트 모드로 전환" : "다크 모드로 전환"}>
            <Button
                type="text"
                icon={isDarkMode ? <SunOutlined /> : <MoonOutlined />}
                onClick={toggleTheme}
                style={{ fontSize: "16px" }}
            />
        </Tooltip>
    );
};

export default ThemeToggle;
