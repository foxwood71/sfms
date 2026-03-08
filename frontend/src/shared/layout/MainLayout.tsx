import React from "react";
import { Outlet, useNavigate, useLocation } from "react-router-dom";
import { ProLayout } from "@ant-design/pro-components";
import {
	DashboardOutlined,
	BankOutlined,
	ToolOutlined,
	SettingOutlined,
	LogoutOutlined,
	UserOutlined,
	ApartmentOutlined,
} from "@ant-design/icons";
import { Dropdown, App as AntdApp } from "antd";
import { useAuthStore } from "../stores/useAuthStore";

/**
 * SFMS 메인 레이아웃 컴포넌트
 * 
 * @description ProLayout을 기반으로 상단 헤더, 사이드바 메뉴 및 사용자 프로필을 관리합니다.
 */
const MainLayout: React.FC = () => {
	const navigate = useNavigate();
	const location = useLocation();
	const { message } = AntdApp.useApp();
	
	// 전역 상태에서 사용자 정보 및 로그아웃 액션 추출
	const { user, clearAuth } = useAuthStore();

	/**
	 * 로그아웃 핸들러
	 */
	const handleLogout = () => {
		clearAuth();
		message.success("안전하게 로그아웃되었습니다.");
		navigate("/login");
	};

	/**
	 * 사이드바 메뉴 정의 (DDD 구조 반영)
	 */
	const menuData = {
		path: "/",
		routes: [
			{
				path: "/dashboard",
				name: "대시보드",
				icon: <DashboardOutlined />,
			},
			{
				path: "/fac",
				name: "시설 및 공간",
				icon: <BankOutlined />,
				routes: [
					{ path: "/fac/list", name: "시설 목록" },
					{ path: "/fac/register", name: "시설 등록" },
				],
			},
			{
				path: "/usr",
				name: "조직 및 사용자",
				icon: <UserOutlined />,
				routes: [
					{ path: "/usr/organizations", name: "조직도 관리", icon: <ApartmentOutlined /> },
					{ path: "/usr/users", name: "사용자 관리" },
				],
			},
			{
				path: "/cmm",
				name: "시스템 설정",
				icon: <SettingOutlined />,
				routes: [
					{ path: "/cmm/codes", name: "공통 코드 관리" },
					{ path: "/sys/audit-logs", name: "감사 로그 조회" },
				],
			},
		],
	};

	return (
		<div style={{ height: "100vh" }}>
			<ProLayout
				title="SFMS"
				logo="/vite.svg"
				layout="mix"
				fixedHeader
				fixSiderbar
				route={menuData}
				location={location}
				menuItemRender={(item, dom) => (
					<div
						onClick={() => navigate(item.path || "/")}
						style={{ display: "flex", alignItems: "center", gap: 8 }}
					>
						{dom}
					</div>
				)}
				avatarProps={{
					// 사용자 이름의 첫 글자를 아바타로 사용하거나 기본 아이콘 표시
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
