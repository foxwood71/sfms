import { MoonOutlined, SunOutlined } from "@ant-design/icons";
import { Button, Tooltip } from "antd";
import type React from "react";
import { useThemeStore } from "../../stores/useThemeStore";

/**
 * 테마 토글 버튼 컴포넌트
 *
 * @description 라이트 모드와 다크 모드 간의 전환을 수행하는 버튼을 렌더링합니다.
 */
const ThemeToggle: React.FC = () => {
    const { theme, toggleTheme } = useThemeStore();

    return (
        <Tooltip title={theme === "light" ? "다크 모드로 전환" : "라이트 모드로 전환"}>
            <Button
                type="text"
                icon={theme === "light" ? <MoonOutlined /> : <SunOutlined />}
                onClick={toggleTheme}
                style={{
                    fontSize: "16px",
                    width: 40,
                    height: 40,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                }}
            />
        </Tooltip>
    );
};

export default ThemeToggle;
