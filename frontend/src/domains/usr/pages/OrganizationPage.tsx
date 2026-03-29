import {
	ApartmentOutlined,
	ClusterOutlined,
	CompressOutlined,
	EditOutlined,
	ExpandOutlined,
	FilterOutlined,
	LineHeightOutlined,
	PartitionOutlined,
	PlusOutlined,
	ReloadOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import type { ActionType, ProColumns } from "@ant-design/pro-components";
import {
	DrawerForm,
	PageContainer,
	ProCard,
	ProFormSwitch,
	ProFormText,
	ProFormTextArea,
	ProTable,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Dropdown,
	Form,
	Input,
	Select,
	Space,
	Splitter,
	Switch,
	Tag,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getCodeDetails } from "@/domains/cmm/api";
import {
	createOrganizationApi,
	getOrganizationsApi,
	getUsersApi,
	updateOrganizationApi,
} from "@/domains/usr/api";
import type {
	CreateOrgParams,
	Organization,
	UpdateOrgParams,
	User,
} from "@/domains/usr/types";
import { getStandardTableStyle } from "@/shared/constants/layout";
import OrgTreeSelect from "../components/OrgTreeSelect";
import UserFormDrawer from "../components/UserFormDrawer";
import { getUserTableColumns } from "./UserTableColumns";

/**
 * 조직 및 사용자 통합 관리 페이지 (Integrated Workspace)
 * [좌측 트리 - 우측 하위부서/사용자 테이블] 구조로 일관성 확보
 */
const OrganizationPage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	const orgTableActionRef = useRef<ActionType>(null);
	const userTableActionRef = useRef<ActionType>(null);
	const [orgForm] = Form.useForm();

	// --- 상태 관리 ---
	const [selectedKey, setSelectedKey] = useState<React.Key>("root");
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);
	const [activeTab, setActiveTab] = useState<string>("suborgs");

	const [orgDrawerOpen, setOrgDrawerOpen] = useState(false);
	const [isOrgAdding, setIsOrgAdding] = useState(false);
	const [userDrawerOpen, setUserDrawerOpen] = useState(false);
	const [editingUser, setEditingUser] = useState<User | null>(null);
	const [editingOrg, setEditingOrg] = useState<Organization | null>(null);

	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);
	const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

	// --- 트리 제어 상태 ---
	const [showOrgFilter, setShowOrgFilter] = useState(false);
	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [orgSearchValue, setOrgSearchValue] = useState("");
	const [isAllExpanded, setIsAllExpanded] = useState(true);
	const [isInitialLoad, setIsInitialLoad] = useState(true);

	// --- 데이터 조회 ---
	const { data: orgResponse, isFetching: isOrgFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactiveOrg],
		queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
	});

	const { data: posCodes } = useQuery({ queryKey: ["codeDetails", "POS_TYPE"], queryFn: () => getCodeDetails("POS_TYPE") });
	const { data: dutyCodes } = useQuery({ queryKey: ["codeDetails", "DUTY_TYPE"], queryFn: () => getCodeDetails("DUTY_TYPE") });

	const posMap = useMemo(() => {
		const map: Record<string, string> = {};
		posCodes?.forEach((c) => { map[c.detail_code] = c.detail_name; });
		return map;
	}, [posCodes]);

	const dutyMap = useMemo(() => {
		const map: Record<string, string> = {};
		dutyCodes?.forEach((c) => { map[c.detail_code] = c.detail_name; });
		return map;
	}, [dutyCodes]);

	const findOrgInTree = useCallback(
		(items: Organization[], idStr: string): Organization | null => {
			for (const item of items) {
				if (String(item.id) === idStr) return item;
				if (item.children) {
					const found = findOrgInTree(item.children, idStr);
					if (found) return found;
				}
			}
			return null;
		},
		[],
	);

	const selectedOrg = useMemo(() => {
		if (!selectedKey || selectedKey === "root" || !orgResponse?.data) return null;
		return findOrgInTree(orgResponse.data, String(selectedKey));
	}, [selectedKey, orgResponse, findOrgInTree]);

	const subOrgData = useMemo(() => {
		if (!orgResponse?.data) return [];
		if (selectedKey === "root") return orgResponse.data;
		return selectedOrg?.children || [];
	}, [orgResponse, selectedKey, selectedOrg]);

	// --- 트리 제어 유틸리티 ---
	const getAllKeys = useCallback((items: Organization[]): React.Key[] => {
		const keys: React.Key[] = ["root"];
		const collect = (list: Organization[]) => {
			for (const item of list) {
				keys.push(String(item.id));
				if (item.children) collect(item.children);
			}
		};
		collect(items);
		return keys;
	}, []);

	const toggleExpandAll = () => {
		if (isAllExpanded) {
			setExpandedKeys(["root"]);
			setIsAllExpanded(false);
		} else {
			if (orgResponse?.data) {
				setExpandedKeys(getAllKeys(orgResponse.data));
				setIsAllExpanded(true);
			}
		}
	};

	// --- Mutation ---
	const saveOrgMutation = useMutation({
		mutationFn: (values: CreateOrgParams | UpdateOrgParams) => {
			const payload = { ...values, parent_id: values.parent_id ? Number(values.parent_id) : null };
			return isOrgAdding ? createOrganizationApi(payload as CreateOrgParams) : updateOrganizationApi(Number(editingOrg?.id), payload as UpdateOrgParams);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setOrgDrawerOpen(false);
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
	});

	// --- 컬럼 정의 ---
	const orgColumns: ProColumns<Organization>[] = [
		{
			title: t("org.name"),
			dataIndex: "name",
			render: (text, record) => (
				<Button
					type="link"
					style={{ padding: 0, height: "auto" }}
					onClick={() => setSelectedKey(String(record.id))}
				>
					{text}
				</Button>
			)
		},
		{ title: t("org.code"), dataIndex: "code", width: 100 },
		{ title: t("common.status"), dataIndex: "is_active", width: 80, render: (active) => <Tag color={active ? "green" : "default"}>{active ? t("common.active") : t("common.inactive")}</Tag> },
		{
			title: t("common.action"),
			valueType: "option",
			width: 80,
			render: (_, record) => [
				<Button key="edit" type="text" size="small" icon={<EditOutlined />} onClick={() => { setEditingOrg(record); setIsOrgAdding(false); setOrgDrawerOpen(true); orgForm.setFieldsValue(record); }} />,
			],
		},
	];

	const userColumns = useMemo(() => getUserTableColumns({
		t, posMap, dutyMap,
		onViewDetail: (user) => { setEditingUser(user); setUserDrawerOpen(true); },
		onToggleStatus: () => {}, onDelete: () => {},
	}), [t, posMap, dutyMap]);

	const treeData: DataNode[] = useMemo(() => {
		const mapToTree = (items: Organization[], parentMatched = false): DataNode[] => {
			if (!items) return [];
			return items.map((item) => {
				const isMatched = !orgSearchValue || item.name.toLowerCase().includes(orgSearchValue.toLowerCase());
				const childrenNodes = item.children ? mapToTree(item.children, parentMatched || isMatched) : [];

				if (!parentMatched && !isMatched && childrenNodes.length === 0) return null;

				return {
					key: String(item.id),
					title: item.is_active ? item.name : <span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>{item.name}</span>,
					icon: <ClusterOutlined />,
					children: childrenNodes,
				} as DataNode;
			}).filter((node): node is DataNode => node !== null);
		};
		return [{ key: "root", title: t("user.root_org"), icon: <ApartmentOutlined />, children: mapToTree(orgResponse?.data || []) }];
	}, [orgResponse, orgSearchValue, token, t]);

	useEffect(() => {
		if (orgResponse?.data && isInitialLoad) {
			setExpandedKeys(getAllKeys(orgResponse.data));
			setIsInitialLoad(false);
		}
	}, [orgResponse, isInitialLoad, getAllKeys]);

	return (
		<PageContainer
			header={{ title: t("menu.usr") }}
			childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
		>
			<style>{`
                ${getStandardTableStyle(token)}
				.ant-pro-card { height: 100% !important; display: flex !important; flex-direction: column !important; }
				.ant-pro-card-body { flex: 1 !important; display: flex !important; flex-direction: column !important; padding: 0 !important; overflow: hidden !important; }
                .ant-pro-card-header {
                    padding: 0 20px !important;
                    background: ${token.colorFillAlter} !important;
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    min-height: 56px !important;
                }
                .ant-pro-card-title { font-weight: 600 !important; }
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }

                /* 풍선 형태의 Bulk Action Bar 스타일 */
                .bulk-action-balloon {
                    position: absolute;
                    bottom: 30px;
                    left: 50%;
                    transform: translateX(-50%);
                    background: ${token.colorBgElevated};
                    padding: 8px 24px;
                    border-radius: 50px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.15);
                    border: 1px solid ${token.colorBorderSecondary};
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    z-index: 1000;
                    animation: slideUp 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
                }
                @keyframes slideUp {
                    from { opacity: 0; transform: translate(-50%, 30px); }
                    to { opacity: 1; transform: translate(-50%, 0); }
                }
			`}</style>

			<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: "12px", border: `1px solid ${token.colorBorderSecondary}`, overflow: "hidden", display: "flex", flexDirection: "column", boxShadow: "0 4px 12px rgba(0,0,0,0.05)" }}>
				<Splitter style={{ height: "100%", background: "transparent" }}>

					{/* 좌측 네비게이터 */}
					<Splitter.Panel defaultSize="25%" min="15%" max="40%">
						<ProCard title={t("org.tree_title")} bordered={false} extra={
                            <Space size={2}>
								<Tooltip title={isAllExpanded ? t("common.collapse_all") : t("common.expand_all")}>
									<Button type="text" size="small" icon={isAllExpanded ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} />
								</Tooltip>
								<Button type="text" size="small" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} />
								<Button type="text" size="small" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isOrgFetching} />
							</Space>
                        }>
							{showOrgFilter && (
								<div style={{ padding: "12px 20px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
									<Input.Search placeholder={t("user.search_placeholder")} size="small" allowClear onChange={(e) => setOrgSearchValue(e.target.value)} style={{ marginBottom: 4 }} />
									<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
										<span style={{ fontSize: "11px", color: token.colorTextSecondary }}>{t("user.include_inactive_org")}</span>
										<Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} />
									</div>
								</div>
							)}
							<div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
								<Tree
									showIcon blockNode showLine={{ showLeafIcon: false }}
									treeData={treeData}
									expandedKeys={expandedKeys}
									onExpand={(keys) => { setExpandedKeys(keys); setIsAllExpanded(keys.length > 1); }}
									selectedKeys={[String(selectedKey)]}
									onSelect={(keys) => { if (keys.length > 0) setSelectedKey(keys[0]); }}
								/>
							</div>
						</ProCard>
					</Splitter.Panel>

					{/* 우측 워크스페이스 */}
					<Splitter.Panel min="50%">
						<ProCard
							tabs={{
								activeKey: activeTab,
								onChange: setActiveTab,
								items: [
									{
										key: "suborgs",
										label: <Space><PartitionOutlined />{t("org.title")}</Space>,
										children: (
											<div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
												<ProTable<Organization>
													actionRef={orgTableActionRef}
													columns={orgColumns}
													dataSource={subOrgData}
													rowKey="id"
													search={false}
													options={{ setting: true, density: false }}
													size={tableSize}
													pagination={{ pageSize, onChange: (_, size) => setPageSize(size || 10) }}
													toolBarRender={() => [
														<Select key="pz" size="small" value={pageSize} onChange={setPageSize} options={[{ value: 10, label: t("user.page_size", { count: 10 }) }, { value: 20, label: t("user.page_size", { count: 20 }) }]} style={{ width: 80 }} />,
														<Dropdown key="ds" menu={{ items: [ { key: "large", label: t("user.density_default"), onClick: () => setTableSize("large") }, { key: "middle", label: t("user.density_middle"), onClick: () => setTableSize("middle") }, { key: "small", label: t("user.density_small"), onClick: () => setTableSize("small") } ] }}><Button type="text" size="small" icon={<LineHeightOutlined />} /></Dropdown>,
													]}
												/>
											</div>
										),
									},
									{
										key: "users",
										label: <Space><TeamOutlined />{t("user.list_title")}</Space>,
										children: (
											<div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
												<ProTable<User>
													actionRef={userTableActionRef}
													columns={userColumns}
													size={tableSize}
													rowKey="id"
													search={false}
													options={{ setting: true, density: false }}
													params={{ org_id: selectedKey === "root" ? undefined : Number(selectedKey) }}
													rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
													tableAlertRender={({ selectedRowKeys, onCleanSelected }) => (
														<Space size={24}>
															<span>{t("common.selected_count", { count: selectedRowKeys.length })}</span>
															<Button type="link" size="small" onClick={onCleanSelected}>{t("common.clear_selection")}</Button>
														</Space>
													)}
													tableAlertOptionRender={() => (
														<Space size={16}>
															<Button danger type="link" onClick={() => {}}>{t("common.bulk_delete")}</Button>
														</Space>
													)}
													request={async (params) => {
														const res = await getUsersApi({ org_id: params.org_id, page: params.current, size: params.pageSize });
														return { data: res.data.items, success: true, total: res.data.total };
													}}
													toolBarRender={() => [
														<Select key="pz" size="small" value={pageSize} onChange={setPageSize} options={[{ value: 10, label: t("user.page_size", { count: 10 }) }, { value: 20, label: t("user.page_size", { count: 20 }) }]} style={{ width: 80 }} />,
														<Dropdown key="ds" menu={{ items: [ { key: "large", label: t("user.density_default"), onClick: () => setTableSize("large") }, { key: "middle", label: t("user.density_middle"), onClick: () => setTableSize("middle") }, { key: "small", label: t("user.density_small"), onClick: () => setTableSize("small") } ] }}><Button type="text" size="small" icon={<LineHeightOutlined />} /></Dropdown>,
													]}
													pagination={{ pageSize, onChange: (_, size) => setPageSize(size || 10) }}
												/>
												{/* 풍선 형태의 Bulk Action Bar */}
												{selectedRowKeys.length > 0 && (
													<div className="bulk-action-balloon">
														<Space size={16}>
															<span style={{ fontWeight: 600, color: token.colorPrimary }}>
																{t("common.selected_count", { count: selectedRowKeys.length })}
															</span>
															<div style={{ width: "1px", height: "16px", background: token.colorBorderSecondary }} />
															<Button type="text" danger size="small" onClick={() => {}}>
																{t("common.bulk_delete")}
															</Button>
															<Button type="link" size="small" onClick={() => setSelectedRowKeys([])}>
																{t("common.clear_selection")}
															</Button>
														</Space>
													</div>
												)}
											</div>
										),
									},
								],
							}}
							extra={
								<Space>
									{activeTab === "suborgs" ? (
										<Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => {
											setIsOrgAdding(true); setOrgDrawerOpen(true); setEditingOrg(null);
											orgForm.resetFields();
											orgForm.setFieldsValue({ parent_id: selectedKey === "root" ? null : String(selectedKey), is_active: true });
										}}>{t("common.create")}</Button>
									) : (
										<Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => { setEditingUser(null); setUserDrawerOpen(true); }}>{t("common.create")}</Button>
									)}
								</Space>
							}
						/>
					</Splitter.Panel>
				</Splitter>
			</div>

			<DrawerForm<CreateOrgParams>
				title={isOrgAdding ? t("org.new_org") : t("org.edit_group")}
				open={orgDrawerOpen} onOpenChange={setOrgDrawerOpen}
				form={orgForm} onFinish={async (v) => { await saveOrgMutation.mutateAsync(v); return true; }}
				drawerProps={{ destroyOnClose: true, width: 500 }}
			>
				<Form.Item name="parent_id" label={t("org.parent")}>
					<OrgTreeSelect />
				</Form.Item>
				<ProFormText name="name" label={t("org.name")} rules={[{ required: true }]} />
				<ProFormText name="code" label={t("org.code")} rules={[{ required: true }]} disabled={!isOrgAdding} />
				<ProFormTextArea name="description" label={t("common.description")} />
				<ProFormSwitch name="is_active" label={t("common.status")} />
			</DrawerForm>

			<UserFormDrawer open={userDrawerOpen} onOpenChange={setUserDrawerOpen} editingUser={editingUser} initialOrgId={selectedKey === "root" ? undefined : Number(selectedKey)} onFinish={async () => { userTableActionRef.current?.reload(); queryClient.invalidateQueries({ queryKey: ["users"] }); return true; }} />
		</PageContainer>
	);
};

export default OrganizationPage;
