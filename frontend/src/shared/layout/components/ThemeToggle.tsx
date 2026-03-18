import { BgColorsOutlined, CheckOutlined } from "@ant-design/icons";
import { Button, Dropdown, Tooltip, type MenuProps } from "antd";
import type React from "react";
import { useThemeStore, type ThemeMode } from "@/shared/stores/useThemeStore";

/**
 * 시스템 다중 테마 선택 드롭다운 컴포넌트
 */
const ThemeToggle: React.FC = () => {
	const { theme: currentTheme, setTheme } = useThemeStore();

	const items: MenuProps["items"] = [
		{ key: "light", label: "Default Light", icon: currentTheme === "light" ? <CheckOutlined /> : null },
		{ key: "dark", label: "Pure Dark", icon: currentTheme === "dark" ? <CheckOutlined /> : null },
		{ type: "divider" },
		{ key: "navy", label: "Deep Navy (Dark 추천)", icon: currentTheme === "navy" ? <CheckOutlined /> : null },
		{ key: "gov", label: "K-Gov (Indigo & White)", icon: currentTheme === "gov" ? <CheckOutlined /> : null },
		{ key: "mac", label: "Soft Mac (MacOS Style)", icon: currentTheme === "mac" ? <CheckOutlined /> : null },
	];

	const handleMenuClick: MenuProps["onClick"] = ({ key }) => {
		setTheme(key as ThemeMode);
	};

	return (
		<Tooltip title="시스템 테마 변경">
			<Dropdown menu={{ items, onClick: handleMenuClick }} placement="bottomRight" trigger={["click"]}>
				<Button
					type="text"
					icon={<BgColorsOutlined />}
					style={{ fontSize: "18px" }}
				/>
			</Dropdown>
		</Tooltip>
	);
};

export default ThemeToggle;
