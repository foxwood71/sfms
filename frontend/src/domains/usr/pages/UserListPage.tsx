import {
	ApartmentOutlined,
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
	Modal,
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
 * 사용자 목록 관리 페이지 (Refined Single Bento Standard - Sync with Org Page)
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
	const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

    // [SYNC] 트리 상태 관리
	const [showOrgFilter, setShowOrgFilter] = useState(false);
	const [showInactiveOrg, setShowInactiveOrg] = useState(false);
	const [orgSearchValue, setOrgSearchValue] = useState("");
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);
    const [isAllExpanded, setIsAllExpanded] = useState(true);
    const [isFirstLoad, setIsInitialLoad] = useState(true);

	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	useEffect(() => {
		setTableSize(showUserFilter ? "small" : "middle");
	}, [showUserFilter]);

    // 데이터 조회
	const { data: orgResponse, isFetching: isOrgFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactiveOrg],
		queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
	});

    // --- [SYNC] 트리 제어 유틸리티 ---
    const getAllKeys = (items: Organization[]): React.Key[] => {
        const keys: React.Key[] = ["root"];
        const collect = (list: Organization[]) => {
            for (const item of list) {
                keys.push(item.id);
                if (item.children) collect(item.children);
            }
        };
        collect(items);
        return keys;
    };

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

    useEffect(() => {
        if (orgResponse?.data && isFirstLoad) {
            setExpandedKeys(getAllKeys(orgResponse.data));
            setIsInitialLoad(false);
        }
    }, [orgResponse?.data, isFirstLoad]);

    // 기초 코드 조회 및 매핑 (생략 없이 유지)
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

	const saveMutation = useMutation({
		mutationFn: (values: UserFormValues) => {
			const { pos, duty, role_ids, ...rest } = values;
			const payload = { ...rest, role_ids, metadata: { ...(editingUser?.metadata || {}), pos, duty } };
			if (editingUser) return updateUserApi(editingUser.id, payload as UpdateUserParams);
			return createUserApi(payload as CreateUserParams);
		},
		onSuccess: () => { message.success(t("common.save_success")); setDrawerVisible(false); actionRef.current?.reload(); queryClient.invalidateQueries({ queryKey: ["users"] }); },
		onError: (err: any) => message.error(err.response?.data?.message || t("common.save_failure")),
	});

	const columns = useMemo(() => getUserTableColumns({
		posMap,
		dutyMap,
		onViewDetail: (user) => { setEditingUser(user); setDrawerVisible(true); },
		onToggleStatus: (id) => {}, // 기능 미구현 시 빈 함수
		onDelete: (id) => {}, // 기능 미구현 시 빈 함수
	}), [posMap, dutyMap]);

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
					icon: <ClusterOutlined />,
					children: childrenNodes,
				};
			}).filter(Boolean);
		};
		return [{ key: "root", title: t("user.root_org"), icon: <ApartmentOutlined />, children: mapToTree(orgResponse?.data || []) }];
	}, [orgResponse, orgSearchValue, token, t]);

	return (
		<PageContainer 
			header={{ title: t("user.title") }} 
			childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
		>
			<style>{`
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; padding: 0 !important; }
                .ant-pro-card-header { 
                    padding: 0 20px !important; 
                    background: ${token.colorFillAlter} !important; 
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    min-height: 56px !important;
                }
                .ant-pro-card-title { font-weight: 600 !important; }
				.ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
				${pageSize <= 10 ? '.ant-table-body { overflow-y: hidden !important; }' : '.ant-table-body { flex: 1; overflow-y: auto !important; }'}
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }
			`}</style>

            <div style={{ 
                height: "100%", 
                background: token.colorBgContainer, 
                borderRadius: "12px", 
                border: `1px solid ${token.colorBorderSecondary}`, 
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
                boxShadow: "0 4px 12px rgba(0,0,0,0.05)"
            }}>
                <Splitter style={{ height: "100%", background: "transparent" }}>
                    {/* [SYNC] 좌측 패널 범위 제한 15% ~ 40% */}
                    <Splitter.Panel defaultSize="25%" min="15%" max="40%">
                        <ProCard title={t("user.tree_title")} bordered={false} extra={
                            <Space size={2}>
                                {/* [SYNC] 통합 토글 버튼 추가 */}
                                <Tooltip title={isAllExpanded ? t("common.collapse_all") : t("common.expand_all")}>
                                    <Button type="text" size="small" icon={isAllExpanded ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} />
                                </Tooltip>
                                <Button type="text" size="small" icon={<FilterOutlined style={{ color: showOrgFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowOrgFilter(!showOrgFilter)} />
                                <Button type="text" size="small" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isOrgFetching} />
                            </Space>
                        }>
                            {showOrgFilter && (
                                <div style={{ padding: "12px 20px", background: token.colorBgSubtle, borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
                                    <Input.Search placeholder={t("user.search_placeholder")} size="small" allowClear onChange={(e) => setOrgSearchValue(e.target.value)} style={{ marginBottom: 4 }} />
                                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                                        <span style={{ fontSize: "11px", color: token.colorTextSecondary }}>{t("user.include_inactive_org")}</span>
                                        <Switch size="small" checked={showInactiveOrg} onChange={setShowInactiveOrg} />
                                    </div>
                                </div>
                            )}
                            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                                {/* [SYNC] Tree 속성 동기화 (showLine, expandedKeys 등) */}
                                <Tree 
                                    showIcon 
                                    blockNode 
                                    showLine={{ showLeafIcon: false }}
                                    treeData={treeData} 
                                    expandedKeys={expandedKeys} 
                                    onExpand={(keys) => { setExpandedKeys(keys); setIsAllExpanded(keys.length > 1); }}
                                    selectedKeys={[selectedKey]} 
                                    onSelect={(keys) => { const key = keys.length > 0 ? keys[0] : "root"; setSelectedKey(key); setTimeout(() => actionRef.current?.reload(), 0); }} 
                                />
                            </div>
                        </ProCard>
                    </Splitter.Panel>

                    <Splitter.Panel min="50%">
                        <ProCard title={t("user.list_title")} bordered={false} extra={
                            <Space size={8}>
                                <Button type="text" size="small" icon={<FilterOutlined style={{ color: showUserFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowUserFilter(!showUserFilter)} />
                                <Button key="add" icon={<PlusOutlined />} type="primary" size="small" onClick={() => { setEditingUser(null); setDrawerVisible(true); }}>{t("common.create")}</Button>
                            </Space>
                        }>
                            <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                                {showUserFilter && (
                                    <div style={{ padding: "12px 20px", background: token.colorBgSubtle, borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
                                        <Row gutter={16} align="middle">
                                            <Col span={14}><Input.Search placeholder={t("common.search_placeholder")} allowClear size="small" value={userSearchText} onChange={(e) => setUserSearchText(e.target.value)} onSearch={setUserSearchText} /></Col>
                                            <Col span={10}><div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("user.include_inactive_user")}</span><Switch size="small" checked={showInactiveUser} onChange={setShowInactiveUser} /></div></Col>
                                        </Row>
                                    </div>
                                )}
                                <div style={{ flex: 1, overflow: "hidden", padding: "0 16px" }}>
                                    <ProTable<User> 
                                        actionRef={actionRef} 
                                        size={tableSize} 
                                        scroll={{ x: "max-content", y: pageSize <= 10 ? undefined : (showUserFilter ? LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT_WITH_FILTER : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT) }} 
                                        rowKey="id" 
                                        params={{ org_id: selectedKey === "root" ? undefined : Number(selectedKey), keyword: userSearchText, is_active: showInactiveUser ? undefined : true, pageSize }} 
                                        search={false} 
                                        options={{ setting: true, density: false }} 
                                        rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
                                        tableAlertRender={({ selectedRowKeys, onCleanSelected }) => (
                                            <Space size={24}><span>{t("common.selected_count", { count: selectedRowKeys.length })}</span><a onClick={onCleanSelected}>{t("common.clear_selection")}</a></Space>
                                        )}
                                        tableAlertOptionRender={() => (
                                            <Space size={16}><Button danger type="link" onClick={() => {}}>{t("common.bulk_delete")}</Button></Space>
                                        )}
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
            </div>

			<UserFormDrawer open={drawerVisible} onOpenChange={setDrawerVisible} editingUser={editingUser} initialOrgId={selectedKey === "root" ? undefined : Number(selectedKey)} onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }} />
		</PageContainer>
	);
};

export default UserListPage;
