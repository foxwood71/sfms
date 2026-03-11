import {
	ApartmentOutlined,
	ClusterOutlined,
	ColumnHeightOutlined,
	CompressOutlined,
	DeleteOutlined,
	EditOutlined,
	ExpandOutlined,
	FilterOutlined,
	LineHeightOutlined,
	LockOutlined,
	PlusOutlined,
	ReloadOutlined,
	SearchOutlined,
	ShrinkOutlined,
	TeamOutlined,
	UnlockOutlined,
	SafetyOutlined,
	IdcardOutlined,
} from "@ant-design/icons";
import type { ActionType, ColumnsState, ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Col,
	Dropdown,
	Input,
	Popconfirm,
	Row,
	Select,
	Space,
	Spin,
	Splitter,
	Switch,
	Tag,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import { getCodeDetails } from "../../cmm/api";
import {
	createUserApi,
	deleteUserApi,
	getOrganizationsApi,
	getUsersApi,
	toggleUserStatusApi,
	updateUserApi,
} from "../api";
import UserFormDrawer from "../components/UserFormDrawer";
import type { CreateUserParams, Organization, UpdateUserParams, User } from "../types";

const INITIAL_COLUMNS_STATE: Record<string, ColumnsState> = {
	pos: { show: true },
	duty: { show: true },
	phone: { show: false },
};

const UserListPage: React.FC = () => {
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const actionRef = useRef<ActionType>();

	const [drawerVisible, setDrawerVisible] = useState(false);
	const [editingUser, setEditingUser] = useState<User | null>(null);
	
	// 부서관리와 동일하게 Key 기반 상태 관리로 변경 (선택 표시 버그 해결)
	const [selectedKey, setSelectedKey] = useState<React.Key>("root");

	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);
	const [columnsStateMap, setColumnsStateMap] = useState<Record<string, ColumnsState>>(INITIAL_COLUMNS_STATE);

	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);
	const [searchValue, setSearchValue] = useState("");
	const [showOrgFilter, setShowOrgFilter] = useState(false);
	
	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	// 필터 상태에 따라 테이블 크기 자동 조절
	useEffect(() => {
		setTableSize(showUserFilter ? "small" : "middle");
	}, [showUserFilter]);

	const CONTENT_HEIGHT = "calc(100vh - 220px)"; 
	const HEADER_HEIGHT = "56px";

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

	const { data: orgResponse, isLoading: isOrgLoading, isFetching: isOrgFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactiveOrg],
		queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
	});

	const getAllKeys = (items: Organization[]): React.Key[] => {
		let keys: React.Key[] = [];
		if (!items) return keys;
		for (const item of items) {
			keys.push(item.id);
			if (item.children) keys = [...keys, ...getAllKeys(item.children)];
		}
		return keys;
	};

	useEffect(() => {
		if (orgResponse?.data && !expandedKeys.includes("root")) {
			setExpandedKeys((prev) => Array.from(new Set([...prev, "root"])));
		}
	}, [orgResponse, expandedKeys]);

	const treeData = useMemo(() => {
		const mapToTree = (items: Organization[], parentMatched = false): any[] => {
			if (!items) return [];
			return items.map((item) => {
				const isMatched = !searchValue || item.name.toLowerCase().includes(searchValue.toLowerCase());
				const childrenNodes = item.children ? mapToTree(item.children, parentMatched || isMatched) : [];
				const hasVisibleChildren = childrenNodes.length > 0;
				if (!parentMatched && !isMatched && !hasVisibleChildren) return null;
				return {
					key: item.id,
					title: (
						<Tooltip title={item.name} placement="right" mouseEnterDelay={0.5}>
							<span style={{ whiteSpace: "nowrap", display: "inline-block" }}>
								{item.is_active ? item.name : <span style={{ textDecoration: "line-through", color: token.colorTextDisabled, opacity: 0.6, fontStyle: "italic" }}>{item.name} (비활성)</span>}
							</span>
						</Tooltip>
					),
					icon: item.children && item.children.length > 0 ? <ClusterOutlined /> : <ApartmentOutlined />,
					children: childrenNodes,
				};
			}).filter(Boolean);
		};
		return [{ key: "root", title: "전체 조직도", icon: <TeamOutlined />, children: mapToTree(orgResponse?.data || []) }];
	}, [orgResponse, searchValue, token]);

	const saveMutation = useMutation({
		mutationFn: (values: any) => {
			const { pos, duty, ...rest } = values;
			const payload = { ...rest, metadata: { ...(editingUser?.metadata || {}), pos, duty } };
			if (editingUser) return updateUserApi(editingUser.id, payload as UpdateUserParams);
			return createUserApi(payload as CreateUserParams);
		},
		onSuccess: () => { message.success("저장 완료"); setDrawerVisible(false); actionRef.current?.reload(); queryClient.invalidateQueries({ queryKey: ["users"] }); },
		onError: (err: any) => message.error(err.response?.data?.message || "저장 실패"),
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteUserApi(id),
		onSuccess: () => { message.success("퇴직 처리 완료"); actionRef.current?.reload(); queryClient.invalidateQueries({ queryKey: ["users"] }); },
	});

	const toggleStatusMutation = useMutation({
		mutationFn: (id: number) => toggleUserStatusApi(id),
		onSuccess: () => { message.success("상태 변경 완료"); actionRef.current?.reload(); },
	});

	const getRoleColor = (code: string) => {
		const upperCode = code.toUpperCase();
		if (upperCode.includes("ADMIN")) return "magenta";
		if (upperCode.includes("MANAGER")) return "blue";
		if (upperCode.includes("USER")) return "green";
		if (upperCode.includes("SYS")) return "purple";
		if (upperCode.includes("DEV")) return "cyan";
		const presetColors = ["orange", "gold", "lime", "geekblue", "volcano"];
		const index = code.split("").reduce((acc, char) => acc + char.charCodeAt(0), 0) % presetColors.length;
		return presetColors[index];
	};

	const columns: ProColumns<User>[] = [
		{ title: "로그인 ID", dataIndex: "login_id", width: 120, ellipsis: true, sorter: true },
		{ title: "성명", dataIndex: "name", width: 100, ellipsis: true, sorter: true, render: (text, record) => (
			<a style={{ fontWeight: 500 }} onClick={() => { setEditingUser({ ...record, org_id: Number(record.org_id) }); setDrawerVisible(true); }}>{text}</a>
		)},
		{ title: "사번", dataIndex: "emp_code", width: 100, ellipsis: true, sorter: true },
		{ title: "부서", dataIndex: "org_name", width: 140, ellipsis: true },
		{ title: "역할", key: "roles", width: 160, render: (_, r) => (
			<div style={{ display: "flex", flexWrap: "wrap", gap: "2px" }}>
				{r.roles?.map((role) => <Tag key={role.id} color={getRoleColor(role.code || role.name)} size="small" style={{ fontSize: "10px", borderRadius: "10px", border: "none" }}>{role.name}</Tag>) || "-"}
			</div>
		)},
		{ title: "직위", key: "pos", width: 90, render: (_, r) => posMap[r.metadata?.pos] || r.metadata?.pos || "-" },
		{ title: "직책", key: "duty", width: 90, render: (_, r) => dutyMap[r.metadata?.duty] || r.metadata?.duty || "-" },
		{ title: "상태", dataIndex: "is_active", width: 80, render: (active) => <Tag color={active ? "green" : "default"}>{active ? "재직" : "퇴사"}</Tag> },
		{ title: "계정", dataIndex: "account_status", width: 80, render: (s) => <Tag color={s === "ACTIVE" ? "blue" : "error"}>{s === "ACTIVE" ? "정상" : "차단"}</Tag> },
		{
			title: "관리", valueType: "option", width: 120, fixed: "right", render: (_, record) => [
				<Tooltip key="v" title="상세 정보"><a onClick={() => { setEditingUser({ ...record, org_id: Number(record.org_id) }); setDrawerVisible(true); }}><IdcardOutlined /></a></Tooltip>,
				<Tooltip key="l" title="계정 관리"><a style={{ marginLeft: 12 }} onClick={() => toggleStatusMutation.mutate(record.id)}>{record.account_status === "ACTIVE" ? <LockOutlined style={{ color: "#faad14" }} /> : <UnlockOutlined style={{ color: "#52c41a" }} />}</a></Tooltip>,
				<Popconfirm key="d" title="퇴직 처리" description="해당 사용자를 퇴직 처리하시겠습니까?" onConfirm={() => deleteMutation.mutate(record.id)} okText="처리" cancelText="취소"><Tooltip title="퇴직 처리"><a style={{ color: "#ff4d4f", marginLeft: 12 }}><DeleteOutlined /></a></Tooltip></Popconfirm>
			],
		},
	];

	const densityItems = [
		{ key: "default", label: "넓게", icon: <ExpandOutlined style={{ color: tableSize === "default" ? token.colorWhite : undefined }} />, onClick: () => setTableSize("default"), style: tableSize === "default" ? { background: token.colorPrimary, color: token.colorWhite } : {} },
		{ key: "middle", label: "중간", icon: <ColumnHeightOutlined style={{ color: tableSize === "middle" ? token.colorWhite : undefined }} />, onClick: () => setTableSize("middle"), style: tableSize === "middle" ? { background: token.colorPrimary, color: token.colorWhite } : {} },
		{ key: "small", label: "좁게", icon: <ShrinkOutlined style={{ color: tableSize === "small" ? token.colorWhite : undefined }} />, onClick: () => setTableSize("small"), style: tableSize === "small" ? { background: token.colorPrimary, color: token.colorWhite } : {} },
	];

	return (
		<PageContainer 
			header={{ title: "사용자 관리" }} 
			childrenContentStyle={{ padding: 0, height: CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-table-list-toolbar { padding: 4px 0 !important; margin-bottom: 0 !important; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; }
				.ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
				.ant-table-container { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
				${pageSize <= 10 ? '.ant-table-body { overflow-y: hidden !important; }' : '.ant-table-body { flex: 1; overflow-y: auto !important; }'}
			`}</style>
			<Splitter style={{ height: "100%", background: token.colorBgContainer, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, overflow: "hidden" }}>
				<Splitter.Panel defaultSize="25%" min="15%" max="40%">
					<ProCard title={<div style={{ height: "32px", display: "flex", alignItems: "center" }}><span style={{ fontWeight: 600 }}>조직도</span></div>} headerBordered headerStyle={{ height: HEADER_HEIGHT, padding: "0 16px" }} extra={
						<Space size={2}>
							<Button type="text" size="middle" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} />
							<Button type="text" size="middle" icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />} onClick={() => (expandedKeys.length > 1 ? setExpandedKeys(["root"]) : setExpandedKeys(["root", ...getAllKeys(orgResponse?.data || [])]))} />
							<Button type="text" size="middle" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isOrgFetching} />
						</Space>
					} style={{ height: "100%" }} bodyStyle={{ height: `calc(100% - ${HEADER_HEIGHT})`, padding: 0 }}>
						{showOrgFilter && (
							<div style={{ padding: "16px", flexShrink: 0 }}><div style={{ padding: "12px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}` }}>
								<Input.Search placeholder="부서명..." size="small" allowClear value={searchValue} onChange={(e) => setSearchValue(e.target.value)} onSearch={(val) => setSearchValue(val)} style={{ marginBottom: 8 }} />
								<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "11px", color: token.colorTextSecondary }}>비활성 포함</span><Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} /></div>
							</div></div>
						)}
						<div style={{ flex: 1, overflowY: "auto", padding: "16px 24px" }}>
							<Tree 
								showLine={{ showLeafIcon: false }} 
								showIcon 
								blockNode 
								treeData={treeData} 
								expandedKeys={expandedKeys} 
								onExpand={(keys) => setExpandedKeys(keys as any)} 
								selectedKeys={[selectedKey]} 
								onSelect={(keys) => {
									const key = keys.length > 0 ? keys[0] : "root";
									setSelectedKey(key);
									setTimeout(() => actionRef.current?.reload(), 0);
								}} 
							/>
						</div>
					</ProCard>
				</Splitter.Panel>
				<Splitter.Panel>
					<ProCard title={<div style={{ height: "32px", display: "flex", alignItems: "center" }}><span style={{ fontWeight: 600 }}>사용자 목록</span></div>} headerBordered headerStyle={{ height: HEADER_HEIGHT, padding: "0 16px" }} extra={
						<Space size={2}>
							<Button 
								type="text" 
								size="middle" 
								icon={<FilterOutlined style={{ color: showUserFilter ? token.colorPrimary : undefined }} />} 
								onClick={() => setShowUserFilter(!showUserFilter)} 
							/>
							<Button key="add" icon={<PlusOutlined />} type="primary" size="small" onClick={() => { setEditingUser(null); setDrawerVisible(true); }}>사용자 등록</Button>
						</Space>
					} style={{ height: "100%" }} bodyStyle={{ padding: 0, height: `calc(100% - ${HEADER_HEIGHT})` }}>
						<div style={{ height: "100%", display: "flex", flexDirection: "column", padding: "0 16px" }}>
							{showUserFilter && (
								<div style={{ padding: "16px 0 8px 0", flexShrink: 0 }}>
									<div style={{ padding: "12px 16px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}` }}>
										<Row gutter={16} align="middle">
											<Col span={14}><Input.Search placeholder="성명/ID/사번/연락처..." allowClear size="small" value={userSearchText} onChange={(e) => setUserSearchText(e.target.value)} onSearch={(val) => setUserSearchText(val)} /></Col>
											<Col span={10}><div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>퇴사자 포함</span><Switch size="small" checked={showInactiveUser} onChange={setShowInactiveUser} /></div></Col>
										</Row>
									</div>
								</div>
							)}
							<div style={{ flex: 1, minHeight: 0, marginTop: 8 }}>
								<ProTable<User> 
									actionRef={actionRef} 
									size={tableSize} 
									scroll={{ 
										x: "max-content", 
										y: pageSize <= 10 ? undefined : (showUserFilter ? "calc(100vh - 460px)" : "calc(100vh - 400px)")
									}} 
									rowKey="id" 
									params={{ 
										org_id: selectedKey === "root" ? undefined : Number(selectedKey), 
										keyword: userSearchText, 
										is_active: showInactiveUser ? undefined : true, 
										pageSize 
									}} 
									search={false} 
									options={{ setting: true, density: false, fullScreen: false }} 
									toolBarRender={() => [
										<Select key="pz" size="small" value={pageSize} onChange={setPageSize} options={[{ value: 10, label: "10개씩" }, { value: 20, label: "20개씩" }, { value: 50, label: "50개씩" }]} style={{ width: 80, marginRight: 8 }} />,
										<Dropdown key="ds" menu={{ items: densityItems }} placement="bottomRight" trigger={["click"]}>
											<Tooltip title="여백 제어">
												<Button type="text" icon={<LineHeightOutlined />} />
											</Tooltip>
										</Dropdown>
									]} 
									request={async (params) => {
										try {
											const res = await getUsersApi({ keyword: params.keyword, org_id: params.org_id, include_children: true, is_active: params.is_active, page: params.current, size: params.pageSize });
											return { data: res.data?.items || [], success: true, total: res.data?.total || 0 };
										} catch { return { data: [], success: false }; }
									}} 
									columns={columns} 
									pagination={{ pageSize, showSizeChanger: false, style: { marginBottom: 16 } }} 
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
