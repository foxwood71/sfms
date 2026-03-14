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
 * 사용자 목록 관리 페이지
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
	const [totalCount, setTotalCount] = useState(0);
	
	const [showOrgFilter, setShowOrgFilter] = useState(false);
	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [orgSearchValue, setOrgSearchValue] = useState("");
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);

	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	// Splitter 초기 크기 결정 (비제어 모드)
	const initialSplitterSize = useMemo(() => {
		const saved = localStorage.getItem("sfms_user_splitter_size");
		return saved && !isNaN(Number(saved)) ? Number(saved) : "20%";
	}, []);

	const handleSplitterChange = (sizes: number[]) => {
		if (sizes.length > 0) {
			localStorage.setItem("sfms_user_splitter_size", String(sizes[0]));
		}
	};

	// 필터 박스 활성화 시 테이블 밀도를 자동으로 'small'로 전환하여 화면 표시 영역 초과 방지
	useEffect(() => {
		setTableSize(showUserFilter ? "small" : "middle");
	}, [showUserFilter]);

	// 코드 및 조직 데이터 조회
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

	// Mutation 정의
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

	// 트리 데이터 가공
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
		return [{ key: "root", title: t("common.company_name"), icon: <TeamOutlined />, children: mapToTree(orgResponse?.data || []) }];
	}, [orgResponse, orgSearchValue, token, t]);

	// 트리 전체 확장/축소
	const toggleExpandAll = () => {
		if (expandedKeys.length > 1) {
			setExpandedKeys(["root"]);
		} else {
			const getAllKeys = (items: any[]): React.Key[] => {
				let keys: React.Key[] = [];
				for (const item of items) {
					keys.push(item.key);
					if (item.children) keys = [...keys, ...getAllKeys(item.children)];
				}
				return keys;
			};
			setExpandedKeys(getAllKeys(treeData));
		}
	};

	return (
		<PageContainer 
			header={{ title: t("user.title") }} 
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				/* 1. 카드 바디 자체의 스크롤을 원천 차단 (Zero-Card-Scroll Policy) */
				.ant-pro-card-body { 
					overflow: hidden !important; 
					display: flex; 
					flex-direction: column; 
					height: 100%; 
					padding: 0 !important;
				}
				
				.ant-pro-table-list-toolbar { padding: 4px 16px !important; }
				
				/* 2. 테이블 래퍼 레이아웃 고정 */
				.ant-table-wrapper { 
					height: 100%; 
					display: flex; 
					flex-direction: column; 
					overflow: hidden; 
				}
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { 
					flex: 1; 
					display: flex; 
					flex-direction: column; 
					overflow: hidden; 
				}
				
				/* 3. 테이블 본문 영역만 정책에 따라 스크롤 제어 */
				.ant-table-container {
					flex: 1;
					display: flex;
					flex-direction: column;
					overflow: hidden;
				}
				.ant-table-body {
					flex: 1 !important;
					overflow-y: ${totalCount > 10 ? "auto" : "hidden"} !important;
				}

				/* 4. 트리 래퍼 스크롤 제어 */
				.sfms-tree-wrapper {
					flex: 1;
					overflow-y: auto;
					padding: 8px 16px;
				}
				
				/* 슬림 스크롤바 디자인 */
				.sfms-tree-wrapper::-webkit-scrollbar, .ant-table-body::-webkit-scrollbar {
					width: 6px;
				}
				.sfms-tree-wrapper::-webkit-scrollbar-thumb, .ant-table-body::-webkit-scrollbar-thumb {
					background: transparent;
					border-radius: 3px;
				}
				.sfms-tree-wrapper:hover::-webkit-scrollbar-thumb, .ant-table-body:hover::-webkit-scrollbar-thumb {
					background: rgba(0, 0, 0, 0.15);
				}
			`}</style>

			<Splitter 
				style={{ height: "100%", background: "transparent", overflow: "hidden", gap: 2 }}
				onResizeEnd={handleSplitterChange}
			>
				{/* 좌측: 조직 트리 (Bento Box 1) */}
				<Splitter.Panel defaultSize={initialSplitterSize} min="15%" max="40%">
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard title={t("user.tree_title")} headerBordered headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }} extra={
							<Space size={2}>
								<Tooltip title={expandedKeys.length > 1 ? t("common.collapse_all") : t("common.expand_all")}>
									<Button type="text" icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} />
								</Tooltip>
								<Button type="text" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} />
								<Button type="text" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isOrgFetching} />
							</Space>
						}>
							{showOrgFilter && (
								<div style={{ padding: "8px 16px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}`, borderRadius: 8, margin: "8px 8px 0 8px" }}>
									<Input.Search placeholder={t("user.search_placeholder")} size="small" allowClear onChange={(e) => setOrgSearchValue(e.target.value)} style={{ marginBottom: 4 }} />									<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
										<span style={{ fontSize: "11px", color: token.colorTextSecondary }}>{t("user.include_inactive_org")}</span>
										<Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} />
									</div>
								</div>
							)}
							<div className="sfms-tree-wrapper">
								<Tree 
									showLine={{ showLeafIcon: false }}
									blockNode 
									treeData={treeData} 
									expandedKeys={expandedKeys} 
									onExpand={setExpandedKeys as any} 
									selectedKeys={[selectedKey]} 
									onSelect={(keys) => { 
										const key = keys.length > 0 ? keys[0] : "root"; 
										setSelectedKey(key); 
										setTimeout(() => actionRef.current?.reload(), 0); 
									}} 
								/>
							</div>
						</ProCard>
					</div>
				</Splitter.Panel>

				{/* 우측: 사용자 목록 (Bento Box 2) */}
				<Splitter.Panel>
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard title={t("user.list_title")} headerBordered headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }} extra={
							<Space size={8}>
								<Button type="text" icon={<FilterOutlined style={{ color: showUserFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowUserFilter(!showUserFilter)} />
								<Button key="add" icon={<PlusOutlined />} type="primary" size="small" onClick={() => { setEditingUser(null); setDrawerVisible(true); }}>{t("user.new_user")}</Button>
							</Space>
						}>
							<div style={{ height: "100%", display: "flex", flexDirection: "column", overflow: "hidden" }}>
								{showUserFilter && (
									<div style={{ padding: "12px 16px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}`, borderRadius: 8, margin: "8px 16px 0 16px" }}>
										<Row gutter={16} align="middle">											<Col span={14}><Input.Search placeholder={t("common.search_placeholder")} allowClear size="small" value={userSearchText} onChange={(e) => setUserSearchText(e.target.value)} onSearch={setUserSearchText} /></Col>
											<Col span={10}><div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("user.include_inactive_user")}</span><Switch size="small" checked={showInactiveUser} onChange={setShowInactiveUser} /></div></Col>
										</Row>
									</div>
								)}
								<div style={{ flex: 1, overflow: "hidden", padding: "0 16px", display: "flex", flexDirection: "column" }}>
									<ProTable<User> 
										actionRef={actionRef} 
										size={tableSize} 
										// [정책] 헤더/푸터 고정 및 본문 스크롤 보장
										// CONTENT_HEIGHT가 calc(100vh - 180px)로 변경됨에 따라 오프셋 재조정
										scroll={{ 
											x: "max-content", 
											y: totalCount <= 10 ? undefined : (showUserFilter ? "calc(100vh - 500px)" : "calc(100vh - 440px)")
										}} 
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
											const total = res.data?.total || 0;
											setTotalCount(total);
											return { data: res.data?.items || [], success: true, total };
										}} 
										columns={columns} 
										pagination={{ 
											pageSize, 
											showSizeChanger: false,
											style: { marginBottom: 0, padding: '12px 0' }
										}} 
									/>
								</div>
							</div>
						</ProCard>
					</div>
				</Splitter.Panel>
			</Splitter>

			<UserFormDrawer open={drawerVisible} onOpenChange={setDrawerVisible} editingUser={editingUser} initialOrgId={selectedKey === "root" ? undefined : Number(selectedKey)} onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }} />
		</PageContainer>
	);
};

export default UserListPage;
