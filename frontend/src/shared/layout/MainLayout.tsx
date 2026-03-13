import { LogoutOutlined, UserOutlined } from "@ant-design/icons";
import { ProLayout } from "@ant-design/pro-components";
import { App as AntdApp, Dropdown } from "antd";
import type React from "react";
import { useMemo } from "react";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useAuthStore } from "../stores/useAuthStore";
import HealthIndicator from "./components/HealthIndicator";
import ThemeToggle from "./components/ThemeToggle";
import { filterMenus, menuConfig } from "./menuConfig";
import { logoutApi } from "@/domains/iam/api/auth";

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
	const translateMenus = (items: any[]) => {
		return items.map((item) => {
			const newItem = { ...item };
			// key가 'usr/organizations' 형태면 'menu.usr_organizations'로 변환 시도
			const i18nKey = `menu.${item.key.replace(/\//g, "_")}`;
			newItem.name = t(i18nKey, item.name);
			
			if (newItem.children) {
				newItem.children = translateMenus(newItem.children);
				newItem.routes = newItem.children;
			}
			return newItem;
		});
	};

	/**
	 * 사용자의 권한에 따라 필터링되고 번역된 메뉴 목록
	 */
	const dynamicMenuData = useMemo(() => {
		const isSuper = !!user?.is_superuser;
		const filtered = filterMenus(menuConfig, user?.permissions, isSuper);
		const translated = translateMenus(filtered);
		
		return {
			path: "/",
			routes: translated,
		};
	}, [user, t]);

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
					<div
						onClick={() => navigate(item.path || "/")}
						style={{ display: "flex", alignItems: "center", gap: 8 }}
					>
						{dom}
					</div>
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
