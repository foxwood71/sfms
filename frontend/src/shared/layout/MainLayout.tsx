import React, { useMemo } from "react";
import { Outlet, useNavigate, useLocation } from "react-router-dom";
import { ProLayout } from "@ant-design/pro-components";
import {
	LogoutOutlined,
	UserOutlined,
} from "@ant-design/icons";
import { Dropdown, App as AntdApp } from "antd";
import { useAuthStore } from "../stores/useAuthStore";
import ThemeToggle from "./components/ThemeToggle";
import HealthIndicator from "./components/HealthIndicator";
import { menuConfig, filterMenus } from "./menuConfig";

/**
 * SFMS 메인 레이아웃 컴포넌트
 * 
 * @description ProLayout을 기반으로 상단 헤더, 사이드바 메뉴 및 사용자 프로필을 관리합니다.
 * 사용자의 권한에 따라 메뉴 목록을 동적으로 필터링하여 표시하며, 시스템 통신 상태를 상시 노출합니다.
 */
const MainLayout: React.FC = () => {
	const navigate = useNavigate();
	const location = useLocation();
	const { message } = AntdApp.useApp();
	
	// 전역 상태에서 사용자 정보 및 로그아웃 액션 추출
	const { user, clearAuth } = useAuthStore();

	/**
	 * 사용자의 권한에 따라 필터링된 메뉴 목록 (메모이제이션 적용)
	 */
	const dynamicMenuData = useMemo(() => {
		return {
			path: "/",
			routes: filterMenus(menuConfig, user?.permissions, user?.is_superuser),
		};
	}, [user]);

	/**
	 * 로그아웃 핸들러
	 */
	const handleLogout = () => {
		clearAuth();
		message.success("안전하게 로그아웃되었습니다.");
		navigate("/login");
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
					title: user?.name || "사용자",
					render: (_props, dom) => (
						<Dropdown
							menu={{
								items: [
									{
										key: "profile",
										icon: <UserOutlined />,
										label: "내 정보 수정",
										onClick: () => navigate("/usr/me"),
									},
									{
										type: "divider",
									},
									{
										key: "logout",
										icon: <LogoutOutlined />,
										label: "로그아웃",
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
