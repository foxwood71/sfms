import {
	AppstoreOutlined,
	AuditOutlined,
	BuildOutlined,
	DashboardOutlined,
	EnvironmentOutlined,
	SafetyCertificateOutlined,
	SettingOutlined,
	TeamOutlined,
	UserOutlined,
} from "@ant-design/icons";
import type { MenuProps } from "antd";

/**
 * 메뉴 아이템 확장 타입 정의
 */
export type MenuItem = Required<MenuProps>["items"][number] & {
	name?: string; // ProLayout 필수 속성
	resource?: string;
	action?: string;
	children?: MenuItem[];
	routes?: MenuItem[];
	path?: string;
};

/**
 * 시스템 전체 메뉴 구성 정의
 * name과 label은 MainLayout에서 key를 기반으로 다국어(i18n) 번역되어 표시됩니다.
 */
export const menuConfig: MenuItem[] = [
	{
		key: "dashboard",
		path: "/dashboard",
		icon: <DashboardOutlined />,
		resource: "ALL",
	},
	{
		key: "usr",
		icon: <TeamOutlined />,
		resource: "USR",
		children: [
			{
				key: "usr/organizations",
				path: "/usr/organizations",
				icon: <EnvironmentOutlined />,
				resource: "ORG",
				action: "READ",
			},
			{
				key: "usr/users",
				path: "/usr/users",
				icon: <UserOutlined />,
				resource: "USR",
				action: "READ",
			},
		],
	},
	{
		key: "iam",
		icon: <SafetyCertificateOutlined />,
		resource: "IAM",
		children: [
			{
				key: "iam/roles",
				path: "/iam/roles",
				icon: <AppstoreOutlined />,
				resource: "IAM",
				action: "READ",
			},
		],
	},
	{
		key: "fac",
		icon: <BuildOutlined />,
		resource: "FAC",
		children: [
			{
				key: "fac/spaces",
				path: "/fac/spaces",
				resource: "FAC",
				action: "READ",
			},
			{
				key: "fac/facilities",
				path: "/fac/facilities",
				resource: "FAC",
				action: "READ",
			},
		],
	},
	{
		key: "cmm",
		icon: <AppstoreOutlined />,
		resource: "CMM",
		children: [
			{
				key: "cmm/codes",
				path: "/cmm/codes",
				resource: "CMM",
				action: "READ",
			},
		],
	},
	{
		key: "sys",
		icon: <SettingOutlined />,
		resource: "SYS",
		children: [
			{
				key: "sys/audit-logs",
				path: "/sys/audit-logs",
				icon: <AuditOutlined />,
				resource: "SYS",
				action: "READ",
			},
			{
				key: "sys/api-tester",
				path: "/sys/api-tester",
				resource: "SYS",
				action: "ADMIN",
			},
		],
	},
];

/**
 * 사용자의 권한 및 관리자 여부에 따라 메뉴 목록을 필터링합니다.
 */
export const filterMenus = (
	menus: MenuItem[],
	permissions: Record<string, string[]> | undefined,
	isSuperuser?: boolean,
): MenuItem[] => {
	const superUser = !!isSuperuser;

	// 1. 슈퍼유저는 모든 메뉴 노출 (하위 메뉴까지 재귀적으로 처리)
	if (superUser) {
		return menus.map((m) => {
			const newItem = { ...m };
			if (newItem.children) {
				newItem.children = filterMenus(newItem.children, permissions, true);
				newItem.routes = newItem.children;
			}
			return newItem;
		});
	}

	// 2. 일반 사용자 필터링
	return menus
		.map((item) => {
			// 대시보드(ALL)는 항상 허용
			if (item.resource === "ALL" || !item.resource) {
				const newItem = { ...item };
				if (newItem.children) {
					const filtered = filterMenus(
						newItem.children,
						permissions,
						superUser,
					);
					newItem.children = filtered;
					newItem.routes = filtered;
				}
				return newItem;
			}

			if (!permissions) return null;

			const userActions = permissions[item.resource.toUpperCase()];
			const requiredAction = (item.action || "READ").toUpperCase();
			const isAllowed =
				!!userActions &&
				(userActions.includes("*") || userActions.includes(requiredAction));

			if (!isAllowed) return null;

			const newItem = { ...item };
			if (newItem.children) {
				const filteredChildren = filterMenus(
					newItem.children,
					permissions,
					superUser,
				);
				// 자식이 있던 메뉴인데 자식이 모두 필터링되었다면 본인도 숨김 (단, path가 있는 경우는 예외)
				if (filteredChildren.length === 0 && !item.path) {
					return null;
				}
				newItem.children = filteredChildren;
				newItem.routes = filteredChildren;
			}

			return newItem;
		})
		.filter((item): item is MenuItem => item !== null);
};
