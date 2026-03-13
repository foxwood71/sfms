import {
	ClusterOutlined,
	CompressOutlined,
	ExpandOutlined,
	FilterOutlined,
	LineHeightOutlined,
	PlusOutlined,
	ReloadOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import type { ActionType } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Col,
	Dropdown,
	Input,
	Row,
	Select,
	Space,
	Splitter,
	Switch,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { getCodeDetails } from "@/domains/cmm/api";
import {
	createUserApi,
	deleteUserApi,
	getOrganizationsApi,
	getUsersApi,
	toggleUserStatusApi,
	updateUserApi,
} from "../api";
import UserFormDrawer from "../components/UserFormDrawer";
import type { CreateUserParams, Organization, UpdateUserParams, User, UserFormValues } from "../types";
import { getUserTableColumns } from "./UserTableColumns";

/**
 * 사용자 목록 관리 페이지 (react-i18next 적용)
 */
const UserListPage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const actionRef = useRef<ActionType>();

	const [drawerVisible, setDrawerVisible] = useState(false);
	const [editingUser, setEditingUser] = useState<User | null>(null);
	const [selectedKey, setSelectedKey] = useState<React.Key>("root");
	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);
	
	const [showOrgFilter, setShowOrgFilter] = useState(false);
	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [orgSearchValue, setOrgSearchValue] = useState("");
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);

	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	useEffect(() => {
		setTableSize(showUserFilter ? "small" : "middle");
	}, [showUserFilter]);

	const { data: posCodes } = useQuery({ queryKey: ["codeDetails", "POS_TYPE"], queryFn: () => getCodeDetails("POS_TYPE") });
	const { data: dutyCodes } = useQuery({ queryKey: ["codeDetails", "DUTY_TYPE"], queryFn: () => getCodeDetails("DUTY_TYPE") });

	const posMap = useMemo(() => {
		const map: Record<string, string> = {};
		posCodes?.forEach((c) => (map[c.detail_code] = c.detail_name));
		return map;
	}, [posCodes]);

	const dutyMap = useMemo(() => {
		const map: Record<string, string> = {};
		dutyCodes?.forEach((c) => (map[c.detail_code] = c.detail_name));
		return map;
	}, [dutyCodes]);

	const { data: orgResponse, isFetching: isOrgFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactiveOrg],
		queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
	});

	const saveMutation = useMutation({
		mutationFn: (values: UserFormValues) => {
			const { pos, duty, role_ids, ...rest } = values;
			const payload = { ...rest, role_ids, metadata: { ...(editingUser?.metadata || {}), pos, duty } };
			if (editingUser) return updateUserApi(editingUser.id, payload as UpdateUserParams);
			return createUserApi(payload as CreateUserParams);
		},
		onSuccess: () => { 
			message.success(t("common.save_success")); 
			setDrawerVisible(false); 
			actionRef.current?.reload(); 
			queryClient.invalidateQueries({ queryKey: ["users"] }); 
		},
		onError: (err: any) => message.error(err.response?.data?.message || t("common.save_failure")),
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteUserApi(id),
		onSuccess: () => { message.success(t("common.delete_success")); actionRef.current?.reload(); },
	});

	const toggleStatusMutation = useMutation({
		mutationFn: (id: number) => toggleUserStatusApi(id),
		onSuccess: () => { message.success(t("common.save_success")); actionRef.current?.reload(); },
	});

	const columns = useMemo(() => getUserTableColumns({
		posMap,
		dutyMap,
		onViewDetail: (user) => { setEditingUser(user); setDrawerVisible(true); },
		onToggleStatus: (id) => toggleStatusMutation.mutate(id),
		onDelete: (id) => deleteMutation.mutate(id),
	}), [posMap, dutyMap, toggleStatusMutation, deleteMutation]);

	const treeData = useMemo(() => {
		const mapToTree = (items: Organization[], parentMatched = false): any[] => {
			if (!items) return [];
			return items.map((item) => {
				const isMatched = !orgSearchValue || item.name.toLowerCase().includes(orgSearchValue.toLowerCase());
				const childrenNodes = item.children ? mapToTree(item.children, parentMatched || isMatched) : [];
				if (!parentMatched && !isMatched && childrenNodes.length === 0) return null;
				return {
					key: item.id,
					title: item.is_active ? item.name : <span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>{item.name}</span>,
					icon: item.children && item.children.length > 0 ? <ClusterOutlined /> : undefined,
					children: childrenNodes,
				};
			}).filter(Boolean);
		};
		return [{ key: "root", title: t("user.root_org"), icon: <TeamOutlined />, children: mapToTree(orgResponse?.data || []) }];
	}, [orgResponse, orgSearchValue, token, t]);

	return (
		<PageContainer 
			header={{ title: t("user.title") }} 
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-table-list-toolbar { padding: 4px 0 !important; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; }
				.ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
				${pageSize <= 10 ? '.ant-table-body { overflow-y: hidden !important; }' : '.ant-table-body { flex: 1; overflow-y: auto !important; }'}
			`}</style>

			<Splitter style={{ height: "100%", background: token.colorBgContainer, overflow: "hidden" }}>
				<Splitter.Panel defaultSize="25%" min="15%">
					<ProCard title={t("user.tree_title")} headerBordered headerStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }} extra={
						<Space size={2}>
							<Button type="text" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} />
							<Button type="text" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isOrgFetching} />
						</Space>
					}>
						{showOrgFilter && (
							<div style={{ padding: "8px 16px", background: token.colorFillAlter, marginBottom: 8, borderRadius: token.borderRadius }}>
								<Input.Search placeholder={t("user.search_placeholder")} size="small" allowClear onChange={(e) => setOrgSearchValue(e.target.value)} style={{ marginBottom: 4 }} />
								<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
									<span style={{ fontSize: "11px" }}>{t("user.include_inactive_org")}</span>
									<Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} />
								</div>
							</div>
						)}
						<div style={{ flex: 1, overflowY: "auto" }}>
							<Tree blockNode treeData={treeData} expandedKeys={expandedKeys} onExpand={setExpandedKeys as any} selectedKeys={[selectedKey]} onSelect={(keys) => { const key = keys.length > 0 ? keys[0] : "root"; setSelectedKey(key); setTimeout(() => actionRef.current?.reload(), 0); }} />
						</div>
					</ProCard>
				</Splitter.Panel>

				<Splitter.Panel>
					<ProCard title={t("user.list_title")} headerBordered headerStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }} extra={
						<Space size={8}>
							<Button type="text" icon={<FilterOutlined style={{ color: showUserFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowUserFilter(!showUserFilter)} />
							<Button key="add" icon={<PlusOutlined />} type="primary" size="small" onClick={() => { setEditingUser(null); setDrawerVisible(true); }}>{t("user.new_user")}</Button>
						</Space>
					}>
						<div style={{ height: "100%", display: "flex", flexDirection: "column", padding: "0 16px" }}>
							{showUserFilter && (
								<div style={{ padding: "12px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, marginBottom: 8 }}>
									<Row gutter={16} align="middle">
										<Col span={14}><Input.Search placeholder={t("common.search_placeholder")} allowClear size="small" value={userSearchText} onChange={(e) => setUserSearchText(e.target.value)} onSearch={setUserSearchText} /></Col>
										<Col span={10}><div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "12px" }}>{t("user.include_inactive_user")}</span><Switch size="small" checked={showInactiveUser} onChange={setShowInactiveUser} /></div></Col>
									</Row>
								</div>
							)}
							<div style={{ flex: 1, overflow: "hidden" }}>
								<ProTable<User> 
									actionRef={actionRef} 
									size={tableSize} 
									scroll={{ x: "max-content", y: pageSize <= 10 ? undefined : (showUserFilter ? LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT_WITH_FILTER : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT) }} 
									rowKey="id" 
									params={{ org_id: selectedKey === "root" ? undefined : Number(selectedKey), keyword: userSearchText, is_active: showInactiveUser ? undefined : true, pageSize }} 
									search={false} 
									options={{ setting: true, density: false }} 
									toolBarRender={() => [
										<Select key="pz" size="small" value={pageSize} onChange={setPageSize} options={[{ value: 10, label: t("user.page_size", { count: 10 }) }, { value: 20, label: t("user.page_size", { count: 20 }) }, { value: 50, label: t("user.page_size", { count: 50 }) }]} style={{ width: 80 }} />,
										<Dropdown key="ds" menu={{ items: [ { key: "default", label: t("user.density_default"), onClick: () => setTableSize("default"), style: tableSize === "default" ? { background: token.colorPrimary, color: token.colorWhite } : {} }, { key: "middle", label: t("user.density_middle"), onClick: () => setTableSize("middle"), style: tableSize === "middle" ? { background: token.colorPrimary, color: token.colorWhite } : {} }, { key: "small", label: t("user.density_small"), onClick: () => setTableSize("small"), style: tableSize === "small" ? { background: token.colorPrimary, color: token.colorWhite } : {} } ] }} placement="bottomRight"><Tooltip title={t("user.density")}><Button type="text" icon={<LineHeightOutlined />} /></Tooltip></Dropdown>
									]} 
									request={async (params) => {
										const res = await getUsersApi({ keyword: params.keyword, org_id: params.org_id, include_children: true, is_active: params.is_active, page: params.current, size: params.pageSize });
										return { data: res.data?.items || [], success: true, total: res.data?.total || 0 };
									}} 
									columns={columns} 
									pagination={{ pageSize, showSizeChanger: false }} 
								/>
							</div>
						</div>
					</ProCard>
				</Splitter.Panel>
			</Splitter>

			<UserFormDrawer open={drawerVisible} onOpenChange={setDrawerVisible} editingUser={editingUser} initialOrgId={selectedKey === "root" ? undefined : Number(selectedKey)} onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }} />
		</PageContainer>
	);
};

export default UserListPage;
