import {
	ApartmentOutlined,
	ClusterOutlined,
	CompressOutlined,
	DeleteOutlined,
	EditOutlined,
	ExpandOutlined,
	FilterOutlined,
	PlusOutlined,
	SearchOutlined,
	TeamOutlined,
	LineHeightOutlined,
	ShrinkOutlined,
	ColumnHeightOutlined,
	LockOutlined,
	UnlockOutlined,
} from "@ant-design/icons";
import type { ActionType, ProColumns, ColumnsState } from "@ant-design/pro-components";
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
import {
	createUserApi,
	deleteUserApi,
	getOrganizationsApi,
	getUsersApi,
	updateUserApi,
	toggleUserStatusApi,
} from "../api";
import { getCodeDetails } from "../../cmm/api";
import UserFormDrawer from "../components/UserFormDrawer";
import type {
	CreateUserParams,
	Organization,
	UpdateUserParams,
	User,
} from "../types";

/**
 * 초기 컬럼 표시 상태 (직위, 직책, 전화번호 숨김)
 */
const INITIAL_COLUMNS_STATE: Record<string, ColumnsState> = {
	pos: { show: false },
	duty: { show: false },
	phone: { show: false },
};

const UserListPage: React.FC = () => {
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const actionRef = useRef<ActionType>();

	const [drawerVisible, setDrawerVisible] = useState(false);
	const [editingUser, setEditingUser] = useState<User | null>(null);
	const [selectedOrgId, setSelectedOrgId] = useState<number | undefined>(undefined);

	// 테이블 제어 상태
	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);

	// 컬럼 표시 상태 관리
	const [columnsStateMap, setColumnsStateMap] = useState<Record<string, ColumnsState>>(INITIAL_COLUMNS_STATE);

	// 필터 및 트리 제어 상태
	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);
	const [searchValue, setSearchValue] = useState("");
	const [showSearch, setShowSearch] = useState(false);
	const [showOrgFilter, setShowOrgFilter] = useState(false);

	// 사용자 목록 검색 상태
	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	const CONTENT_HEIGHT = "calc(100vh - 220px)";
	const HEADER_HEIGHT = "56px";

	// 1. 공통 코드 조회 및 매핑 (직급/직책 한글화용)
	const { data: posCodes } = useQuery({
		queryKey: ["codeDetails", "POS_TYPE"],
		queryFn: () => getCodeDetails("POS_TYPE"),
	});
	const { data: dutyCodes } = useQuery({
		queryKey: ["codeDetails", "DUTY_TYPE"],
		queryFn: () => getCodeDetails("DUTY_TYPE"),
	});

	const posMap = useMemo(() => {
		const map: Record<string, string> = {};
		posCodes?.forEach(c => map[c.detail_code] = c.detail_name);
		return map;
	}, [posCodes]);

	const dutyMap = useMemo(() => {
		const map: Record<string, string> = {};
		dutyCodes?.forEach(c => map[c.detail_code] = c.detail_name);
		return map;
	}, [dutyCodes]);

	// 2. 조직 데이터 조회
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
	const allOrgKeys = useMemo(() => ["root", ...(orgResponse?.data ? getAllKeys(orgResponse.data) : [])], [orgResponse]);

	useEffect(() => {
		if (searchValue && orgResponse?.data) setExpandedKeys(allOrgKeys);
		else setExpandedKeys(["root"]);
	}, [searchValue, allOrgKeys]);

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
							<span style={{ whiteSpace: 'nowrap', display: 'inline-block' }}>
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

	// 3. 뮤테이션 로직
	const saveMutation = useMutation({
		mutationFn: (values: any) => {
			const { pos, duty, ...rest } = values;
			const payload = { ...rest, metadata: { ...(editingUser?.metadata || {}), pos, duty } };
			if (editingUser) return updateUserApi(editingUser.id, payload as UpdateUserParams);
			return createUserApi(payload as CreateUserParams);
		},
		onSuccess: () => {
			message.success("저장 완료");
			setDrawerVisible(false);
			actionRef.current?.reload();
			queryClient.invalidateQueries({ queryKey: ["users"] });
		},
		onError: (error: any) => {
			const errorMsg = error.response?.data?.message || "저장 실패";
			message.error(errorMsg);
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteUserApi(id),
		onSuccess: () => {
			message.success("퇴직 처리가 완료되었습니다.");
			actionRef.current?.reload();
			queryClient.invalidateQueries({ queryKey: ["users"] });
		},
		onError: () => message.error("퇴직 처리 실패"),
	});

	const toggleStatusMutation = useMutation({
		mutationFn: (id: number) => toggleUserStatusApi(id),
		onSuccess: (res) => {
			const status = res.data?.account_status === "ACTIVE" ? "해제" : "차단";
			message.success(`계정 ${status} 완료`);
			actionRef.current?.reload();
		},
		onError: () => message.error("계정 상태 변경 실패"),
	});

	// 4. 테이블 컬럼 정의
	const columns: ProColumns<User>[] = [
		{ title: "로그인 ID", dataIndex: "login_id", key: "login_id", copyable: true, width: 120, ellipsis: true, sorter: true },
		{ title: "성명", dataIndex: "name", key: "name", width: 100, ellipsis: true, sorter: true },
		{ title: "사번", dataIndex: "emp_code", key: "emp_code", width: 100, ellipsis: true, sorter: true },
		{ title: "소속 부서", dataIndex: "org_name", key: "org_name", hideInSearch: true, width: 150, ellipsis: true, sorter: true },
		{ 
			title: "직위", 
			dataIndex: ["metadata", "pos"], 
			key: "pos", 
			width: 100, 
			ellipsis: true,
			render: (text) => posMap[text as string] || text || "-"
		},
		{ 
			title: "직책", 
			dataIndex: ["metadata", "duty"], 
			key: "duty", 
			width: 100, 
			ellipsis: true,
			render: (text) => dutyMap[text as string] || text || "-"
		},
		{ title: "전화번호", dataIndex: "phone", key: "phone", width: 130, ellipsis: true },
		{ title: "이메일", dataIndex: "email", key: "email", width: 180, ellipsis: true, hideInSearch: true },
		{
			title: "재직 상태",
			dataIndex: "is_active",
			key: "is_active",
			width: 100,
			sorter: true,
			render: (dom, record) => <Tag color={record.is_active ? "green" : "default"}>{record.is_active ? "재직" : "퇴사"}</Tag>,
		},
		{
			title: "계정 상태",
			dataIndex: "account_status",
			key: "account_status",
			width: 100,
			sorter: true,
			render: (text) => (
				<Tag color={text === "ACTIVE" ? "blue" : "error"}>
					{text === "ACTIVE" ? "정상" : "차단"}
				</Tag>
			),
		},
		{
			title: "관리",
			valueType: "option",
			key: "option",
			width: 120,
			fixed: "right",
			hideInSetting: true,
			render: (_, record) => [
				<Tooltip key="edit-tip" title="수정"><a onClick={() => { setEditingUser({ ...record, org_id: Number(record.org_id) }); setDrawerVisible(true); }}><EditOutlined /></a></Tooltip>,
				<Tooltip key="lock-tip" title={record.account_status === "ACTIVE" ? "계정 차단" : "차단 해제"}>
					<a style={{ marginLeft: 8 }} onClick={() => toggleStatusMutation.mutate(record.id)}>
						{record.account_status === "ACTIVE" ? <LockOutlined style={{ color: '#faad14' }} /> : <UnlockOutlined style={{ color: '#52c41a' }} />}
					</a>
				</Tooltip>,
				<Popconfirm 
					key="delete" 
					title="퇴직 처리"
					description="해당 사용자를 퇴직 처리하시겠습니까? (계정도 자동 차단됩니다)"
					onConfirm={() => deleteMutation.mutate(record.id)}
					okText="처리"
					cancelText="취소"
				>
					<Tooltip key="del-tip" title="퇴직 처리">
						<a style={{ color: "#ff4d4f", marginLeft: 8 }}><DeleteOutlined /></a>
					</Tooltip>
				</Popconfirm>,
			],
		},
	];

	const toggleExpandAll = () => expandedKeys.length > 1 ? setExpandedKeys(["root"]) : setExpandedKeys(allOrgKeys);
	const closeSearch = () => { setShowSearch(false); setSearchValue(""); };

	// 커스텀 여백 제어 메뉴
	const densityItems = [
		{ key: 'default', label: '넓게', icon: <ExpandOutlined />, onClick: () => setTableSize('default') },
		{ key: 'middle', label: '중간', icon: <ColumnHeightOutlined />, onClick: () => setTableSize('middle') },
		{ key: 'small', label: '좁게', icon: <ShrinkOutlined />, onClick: () => setTableSize('small') },
	];

	return (
		<PageContainer
			header={{ title: "사용자 관리" }}
			childrenContentStyle={{ padding: 0, height: CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<Splitter
				style={{
					height: "100%",
					background: token.colorBgContainer,
					borderRadius: token.borderRadiusLG,
					border: `1px solid ${token.colorBorderSecondary}`,
					overflow: "hidden",
				}}
			>
				<Splitter.Panel defaultSize="25%" min="15%" max="40%">
					<ProCard
						title={showSearch ? (<div style={{ display: 'flex', alignItems: 'center', width: '100%' }}><Input placeholder="부서 검색..." variant="borderless" autoFocus value={searchValue} onChange={(e) => setSearchValue(e.target.value)} onKeyDown={(e) => { if (e.key === "Escape") closeSearch(); }} style={{ padding: 0, width: '100%' }} /></div>) : ( "조직도" )}
						headerBordered
						headerStyle={{ height: HEADER_HEIGHT, display: 'flex', alignItems: 'center' }}
						extra={<Space size={2}><Tooltip title="조직 검색"><Button type="text" size="middle" icon={<SearchOutlined style={{ color: showSearch ? token.colorPrimary : undefined }} />} onClick={() => showSearch ? closeSearch() : setShowSearch(true)} /></Tooltip><Tooltip title="필터"><Button type="text" size="middle" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} /></Tooltip><Tooltip title={expandedKeys.length > 1 ? "전체 접기" : "전체 펼치기"}><Button type="text" size="middle" icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} /></Tooltip></Space>}
						style={{ height: "100%" }}
						bodyStyle={{ height: `calc(100% - ${HEADER_HEIGHT})`, display: "flex", flexDirection: "column", padding: 0, overflowX: 'auto' }}
					>
						{showOrgFilter && (<div style={{ padding: "16px 24px 8px 24px", flexShrink: 0 }}><div style={{ padding: "8px 12px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "11px", color: token.colorTextSecondary, fontWeight: 500 }}>조직 필터</span><Space size={4}><span style={{ fontSize: "11px", color: showInactiveOrg ? token.colorError : token.colorSuccess, fontWeight: 500 }}>{showInactiveOrg ? "비활성 포함" : "활성 부서만"}</span><Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} loading={isOrgFetching} tabIndex={-1} /></Space></div></div>)}
						<div style={{ flex: 1, overflow: "auto", padding: "16px 24px" }}>
							{isOrgLoading && !isOrgFetching ? (<div style={{ textAlign: "center", padding: 24 }}><Spin tip="로딩..." /></div>) : (<Tree showLine={{ showLeafIcon: false }} showIcon treeData={treeData} expandedKeys={expandedKeys} onExpand={setExpandedKeys} selectedKeys={selectedOrgId ? [selectedOrgId] : ["root"]} onSelect={(keys) => { if (keys.length > 0) { const key = keys[0]; setSelectedOrgId(key === "root" ? undefined : Number(key)); } else { setSelectedOrgId(undefined); } }} />)}
						</div>
					</ProCard>
				</Splitter.Panel>

				<Splitter.Panel>
					<ProCard
						title="사용자 목록"
						headerBordered
						headerStyle={{ height: HEADER_HEIGHT, display: 'flex', alignItems: 'center' }}
						extra={
							<Space size={2}>
								<Tooltip title="필터">
									<Button type="text" size="middle" icon={<FilterOutlined style={{ color: showUserFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowUserFilter(!showUserFilter)} />
								</Tooltip>
								<Button key="add" icon={<PlusOutlined />} type="primary" size="small" onClick={() => { setEditingUser(null); setDrawerVisible(true); }}>사용자 등록</Button>
							</Space>
						}
						style={{ height: "100%" }}
						bodyStyle={{ padding: 0, height: `calc(100% - ${HEADER_HEIGHT})`, overflow: "hidden", display: "flex", flexDirection: "column" }}
					>
						{showUserFilter && (<div style={{ padding: "16px 12px 8px 12px", flexShrink: 0 }}><div style={{ padding: "12px 16px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}` }}><Row gutter={[16, 12]} align="middle"><Col span={12}><span style={{ fontSize: '12px', color: token.colorTextSecondary, display: 'block', marginBottom: 4 }}>통합 검색 (성명/ID/사번/연락처/이메일)</span><Input placeholder="검색어 입력..." allowClear size="small" value={userSearchText} onChange={e => setUserSearchText(e.target.value)} /></Col><Col span={12}><span style={{ fontSize: '12px', color: token.colorTextSecondary, display: 'block', marginBottom: 4 }}>재직 상태</span><div style={{ display: 'flex', alignItems: 'center', height: '24px' }}><Switch size="small" checked={showInactiveUser} onChange={setShowInactiveUser} /><span style={{ marginLeft: 8, fontSize: '12px', color: showInactiveUser ? token.colorError : token.colorSuccess }}>{showInactiveUser ? "퇴사자 포함" : "재직자만"}</span></div></Col></Row></div></div>)}
						<div style={{ flex: 1, overflow: 'hidden' }}>
							<ProTable<User>
								actionRef={actionRef}
								size={tableSize}
								scroll={{ x: 'max-content', y: 480 }}
								sticky={true}
								style={{ height: "100%" }}
								rowKey="id"
								params={{ org_id: selectedOrgId, keyword: userSearchText, is_active: showInactiveUser ? undefined : true, pageSize }}
								search={false} 
								options={{ 
									setting: true, 
									density: false, 
									fullScreen: false 
								}}
								locale={{ tableList: { density: '여백' } as any }}
								toolBarRender={() => [
									<Select
										key="pageSize"
										size="small"
										value={pageSize}
										onChange={setPageSize}
										options={[
											{ value: 10, label: '10개씩 보기' },
											{ value: 20, label: '20개씩 보기' },
											{ value: 50, label: '50개씩 보기' },
											{ value: 100, label: '100개씩 보기' },
										]}
										style={{ width: 110, marginRight: 8 }}
									/>,
									<Dropdown key="density" menu={{ items: densityItems }} placement="bottomRight" trigger={['click']}>
										<Tooltip title="여백 제어">
											<Button type="text" icon={<LineHeightOutlined />} />
										</Tooltip>
									</Dropdown>
								]}
								columnsState={{
									value: columnsStateMap,
									onChange: (map) => setColumnsStateMap(map),
								}}
								request={async (params, sort) => {
									const { org_id, keyword, is_active, current, pageSize: pSize } = params;
									
									let sortParam: string | undefined = undefined;
									if (sort && Object.keys(sort).length > 0) {
										const field = Object.keys(sort)[0];
										const order = sort[field] === 'ascend' ? 'asc' : 'desc';
										sortParam = `${field}_${order}`;
									}

									try {
										const response = await getUsersApi({ 
											keyword, 
											org_id: org_id !== undefined ? Number(org_id) : undefined, 
											include_children: true, 
											is_active, 
											page: current, 
											size: pSize,
											sort: sortParam 
										});
										return { data: response.data?.items || [], success: true, total: response.data?.total || 0 };
									} catch (error) { return { data: [], success: false }; }
								}}
								columns={columns}
								pagination={{ 
									pageSize, 
									showSizeChanger: false,
								}}
							/>
						</div>
					</ProCard>
				</Splitter.Panel>
			</Splitter>
			<UserFormDrawer open={drawerVisible} onOpenChange={setDrawerVisible} editingUser={editingUser} initialOrgId={selectedOrgId} onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }} />
		</PageContainer>
	);
};

export default UserListPage;
