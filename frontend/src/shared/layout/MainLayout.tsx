import { LogoutOutlined, UserOutlined } from "@ant-design/icons";
import { ProLayout } from "@ant-design/pro-components";
import { App as AntdApp, Dropdown } from "antd";
import type React from "react";
import { useCallback, useMemo } from "react";
import { useTranslation } from "react-i18next";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { logoutApi } from "@/domains/iam/api/auth";
import { useAuthStore } from "../stores/useAuthStore";
import HealthIndicator from "./components/HealthIndicator";
import ThemeToggle from "./components/ThemeToggle";
import type { MenuItem } from "./menuConfig";
import { filterMenus, menuConfig } from "./menuConfig";

/**
 * SFMS 메인 레이아웃 컴포넌트
 */
const MainLayout: React.FC = () => {
	const { t } = useTranslation();
	const navigate = useNavigate();
	const location = useLocation();
	const { message } = AntdApp.useApp();

	// 전역 상태에서 사용자 정보 및 로그아웃 액션 추출
	const { user, refreshToken, clearAuth } = useAuthStore();

	/**
	 * 메뉴 아이템의 이름을 다국어 키를 기반으로 번역합니다.
	 */
	const translateMenus = useCallback(
		(items: MenuItem[]): MenuItem[] => {
			return items.map((item) => {
				const newItem = { ...item };
				// key가 'usr/organizations' 형태면 'menu.usr-organizations'로 변환 시도
				const keyStr = String(item.key || "");
				const i18nKey = `menu.${keyStr.replace(/\//g, "-")}`;

				// [FIX] i18next t 함수의 타입 규격에 맞게 defaultValue 전달 방식 수정
				newItem.name = t(i18nKey, { defaultValue: item.name as string });

				if (newItem.children) {
					newItem.children = translateMenus(newItem.children);
					newItem.routes = newItem.children;
				}
				return newItem;
			});
		},
		[t],
	);

	/**
	 * 사용자의 권한에 따라 필터링되고 번역된 메뉴 목록
	 */
	const dynamicMenuData = useMemo(() => {
		const isSuper = !!user?.is_superuser;
		const filtered = filterMenus(menuConfig, user?.permissions, isSuper);
		// [FIX] translateMenus를 의존성 배열에 포함하기 위해 useCallback 처리됨
		const translated = translateMenus(filtered);

		return {
			path: "/",
			routes: translated,
		};
	}, [user, translateMenus]);

	/**
	 * 로그아웃 핸들러
	 */
	const handleLogout = async () => {
		try {
			await logoutApi(refreshToken);
		} catch (error) {
			console.error("Logout API failed:", error);
		} finally {
			clearAuth();
			message.success(t("auth.logout_success"));
			navigate("/login");
		}
	};

	return (
		<div style={{ height: "100vh" }}>
			<ProLayout
				title="SFMS"
				logo="/vite.svg"
				layout="mix"
				fixedHeader
				fixSiderbar
				route={dynamicMenuData}
				location={location}
				actionsRender={() => [
					<HealthIndicator key="health" />,
					<ThemeToggle key="theme" />,
				]}
				menuItemRender={(item, dom) => (
					<button
						type="button"
						onClick={() => navigate(item.path || "/")}
						style={{
							display: "flex",
							alignItems: "center",
							gap: 8,
							width: "100%",
							cursor: "pointer",
							background: "none",
							border: "none",
							padding: 0,
							textAlign: "left",
							font: "inherit",
							color: "inherit",
						}}
					>
						{dom}
					</button>
				)}
				avatarProps={{
					icon: <UserOutlined />,
					size: "small",
					title: user?.name || t("common.user"),
					render: (_props, dom) => (
						<Dropdown
							menu={{
								items: [
									{
										key: "profile",
										icon: <UserOutlined />,
										label: t("common.edit_profile"),
										onClick: () => navigate("/usr/me"),
									},
									{
										type: "divider",
									},
									{
										key: "logout",
										icon: <LogoutOutlined />,
										label: t("auth.logout"),
										danger: true,
										onClick: handleLogout,
									},
								],
							}}
						>
							{dom}
						</Dropdown>
					),
				}}
			>
				{/* 메인 콘텐츠 영역 */}
				<div style={{ padding: "16px", minHeight: "calc(100vh - 120px)" }}>
					<Outlet />
				</div>
			</ProLayout>
		</div>
	);
};

export default MainLayout;
