import {
	ApartmentOutlined,
	AuditOutlined,
	BankOutlined,
	CodeOutlined,
	DashboardOutlined,
	SettingOutlined,
	UserOutlined,
} from "@ant-design/icons";
import type React from "react";

/**
 * 메뉴 아이템 정의 인터페이스
 */
export interface MenuItem {
	path: string;
	name: string;
	icon?: React.ReactNode;
	/** 접근에 필요한 리소스 권한 코드 (예: 'USR', 'FAC') */
	resource?: string;
	/** 접근에 필요한 액션 (예: 'READ', 'ADMIN') */
	action?: string;
	/** 하위 메뉴 */
	routes?: MenuItem[];
	/** 숨김 여부 */
	hideInMenu?: boolean;
}

/**
 * SFMS 전체 메뉴 구성 설정
 *
 * @description 도메인별 메뉴 구조와 각 메뉴 접근에 필요한 권한(Resource)을 정의합니다.
 */
export const menuConfig: MenuItem[] = [
	{
		path: "/dashboard",
		name: "대시보드",
		icon: <DashboardOutlined />,
	},
	{
		path: "/fac",
		name: "시설 및 공간",
		icon: <BankOutlined />,
		resource: "FAC",
		action: "READ",
		routes: [
			{ path: "/fac/list", name: "시설 목록" },
			{ path: "/fac/register", name: "시설 등록", action: "CREATE" },
		],
	},
	{
		path: "/usr",
		name: "부서 및 사용자",
		icon: <UserOutlined />,
		resource: "USR",
		action: "READ",
		routes: [
			{
				path: "/usr/organizations",
				name: "부서 관리",
				icon: <ApartmentOutlined />,
				resource: "ORG",
			},
			{ path: "/usr/users", name: "사용자 관리" },
		],
	},
	{
		path: "/sys",
		name: "시스템 설정",
		icon: <SettingOutlined />,
		resource: "SYS",
		routes: [
			{
				path: "/cmm/codes",
				name: "공통 코드 관리",
				icon: <CodeOutlined />,
				resource: "CMM",
			},
			{
				path: "/sys/audit-logs",
				name: "감사 로그 조회",
				icon: <AuditOutlined />,
				resource: "SYS",
				action: "READ_LOG",
			},
		],
	},
];

/**
 * 사용자의 권한에 따라 메뉴를 필터링하는 함수
 */
export const filterMenus = (
	menus: MenuItem[],
	permissions: Record<string, string[]> = {},
	isSuperuser = false,
): MenuItem[] => {
	// 1. 슈퍼유저 여부 확인
	// - is_superuser 플래그가 true이거나
	// - permissions에 'all' 또는 'ALL' 리소스에 대한 '*' 권한이 있는 경우
	const hasGlobalAdmin =
		isSuperuser ||
		(permissions["all"] && permissions["all"].includes("*")) ||
		(permissions["ALL"] && permissions["ALL"].includes("*"));

	if (hasGlobalAdmin) return menus;

	const filtered = menus
		.filter((menu) => {
			// 2. 권한 설정이 없는 메뉴는 누구나 접근 가능
			if (!menu.resource) return true;

			// 3. 해당 리소스에 대한 사용자의 권한 확인
			// 리소스 코드는 관례상 대문자로 처리하므로 둘 다 확인
			const userActions =
				permissions[menu.resource] ||
				permissions[menu.resource.toLowerCase()] ||
				[];

			// 해당 도메인의 모든 권한('*')이 있거나, 특정 액션 권한이 있는지 확인
			if (userActions.includes("*")) return true;

			const requiredAction = menu.action || "READ";
			return userActions.includes(requiredAction);
		})
		.map((menu) => {
			if (menu.routes) {
				return {
					...menu,
					routes: filterMenus(menu.routes, permissions, hasGlobalAdmin),
				};
			}
			return menu;
		});

	// 자식이 있는 메뉴인데 필터링 후 자식이 하나도 없으면 대메뉴 제외 (대시보드 제외)
	return filtered.filter((menu) => {
		if (menu.path === "/dashboard") return true;
		if (menu.routes && menu.routes.length === 0) return false;
		return true;
	});
};
