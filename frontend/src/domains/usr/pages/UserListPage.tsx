import React, { useState, useMemo, useEffect } from "react";
import { PlusOutlined, EditOutlined, DeleteOutlined, ApartmentOutlined, ClusterOutlined, TeamOutlined, SearchOutlined, CompressOutlined, ExpandOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import {
	PageContainer,
	ProTable,
	ModalForm,
	ProFormText,
	ProFormSwitch,
	ProCard,
} from "@ant-design/pro-components";
import { Button, Space, Tag, Popconfirm, App, Tree, Spin, Empty, theme, Switch, Tooltip, Splitter, Input } from "antd";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { getUsersApi, createUserApi, updateUserApi, deleteUserApi, getOrganizationsApi } from "../api";
import type { User, CreateUserParams, UpdateUserParams, Organization } from "../types";
import OrgTreeSelect from "../components/OrgTreeSelect";
import CodeSelect from "../components/CodeSelect";

/**
 * 사용자 관리 페이지 컴포넌트
 */
const UserListPage: React.FC = () => {
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	
	const [modalVisible, setModalVisible] = useState(false);
	const [editingUser, setEditingUser] = useState<User | null>(null);
	const [selectedOrgId, setSelectedOrgId] = useState<number | undefined>(undefined);
	
	// 필터 및 트리 제어 상태
	const [showInactive, setShowInactive] = useState(false);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["all"]);
	const [searchValue, setSearchValue] = useState("");
	const [showSearch, setShowSearch] = useState(false);

	const CONTENT_HEIGHT = "calc(100vh - 220px)";

	// 1. 조직 데이터 조회
	const { data: orgResponse, isLoading: isOrgLoading } = useQuery({
		queryKey: ["organizations", "tree", "all"],
		queryFn: () => getOrganizationsApi("tree", false),
	});

	// 모든 키 추출 (전체 제어용)
	const getAllKeys = (items: Organization[]): React.Key[] => {
		let keys: React.Key[] = [];
		for (const item of items) {
			keys.push(item.id);
			if (item.children) keys = [...keys, ...getAllKeys(item.children)];
		}
		return keys;
	};
	const allOrgKeys = useMemo(() => ["all", ...(orgResponse?.data ? getAllKeys(orgResponse.data) : [])], [orgResponse]);

	// 검색어 입력 시 자동 펼침
	useEffect(() => {
		if (searchValue && orgResponse?.data) { setExpandedKeys(allOrgKeys); } 
		else { setExpandedKeys(["all"]); }
	}, [searchValue, allOrgKeys]);

	// 조직 트리 데이터 변환 (Deep Search 포함)
	const treeData = useMemo(() => {
		const mapToTree = (items: Organization[]): any[] => {
			return items.map((item) => {
				const childrenNodes = item.children ? mapToTree(item.children) : [];
				const isSearchMatch = !searchValue || item.name.toLowerCase().includes(searchValue.toLowerCase());
				const hasVisibleChildren = childrenNodes.length > 0;
				if (searchValue && !isSearchMatch && !hasVisibleChildren) return null;

				return {
					key: item.id,
					title: item.name,
					icon: item.children && item.children.length > 0 ? <ClusterOutlined /> : <ApartmentOutlined />,
					children: childrenNodes,
				};
			}).filter(Boolean);
		};
		return [{
			key: "all",
			title: "전체 조직",
			icon: <TeamOutlined />,
			children: orgResponse?.data ? mapToTree(orgResponse.data) : [],
		}];
	}, [orgResponse, searchValue]);

	// 2. 뮤테이션 로직
	const saveMutation = useMutation({
		mutationFn: (values: any) => {
			const payload = { ...values, metadata: { pos: values.pos } };
			delete payload.pos;
			if (editingUser) return updateUserApi(editingUser.id, payload as UpdateUserParams);
			return createUserApi(payload as CreateUserParams);
		},
		onSuccess: () => {
			message.success("저장 완료");
			setModalVisible(false);
			queryClient.invalidateQueries({ queryKey: ["users"] });
		},
		onError: (error: any) => { message.error("저장 실패"); },
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteUserApi(id),
		onSuccess: () => {
			message.success("비활성화 완료");
			queryClient.invalidateQueries({ queryKey: ["users"] });
		},
		onError: (error: any) => { message.error("삭제 실패"); },
	});

	// 4. 테이블 컬럼
	const columns: ProColumns<User>[] = [
		{ title: "로그인 ID", dataIndex: "login_id", copyable: true, width: 120 },
		{ title: "성명", dataIndex: "name", width: 100 },
		{ title: "사번", dataIndex: "emp_code", width: 100 },
		{ title: "소속 부서", dataIndex: "org_name", hideInSearch: true, width: 150 },
		{ title: "이메일", dataIndex: "email", ellipsis: true, hideInSearch: true },
		{
			title: "재직 상태",
			dataIndex: "is_active",
			width: 100,
			valueEnum: { true: { text: "재직", status: "Success" }, false: { text: "퇴사", status: "Default" } },
			render: (dom, record) => <Tag color={record.is_active ? "green" : "default"}>{record.is_active ? "재직" : "퇴사"}</Tag>,
		},
		{
			title: "관리",
			valueType: "option",
			width: 100,
			render: (_, record) => [
				<a key="edit" onClick={() => { setEditingUser(record); setModalVisible(true); }}><EditOutlined /></a>,
				<Popconfirm key="delete" title="비활성화?" onConfirm={() => deleteMutation.mutate(record.id)}>
					<a style={{ color: "#ff4d4f" }}><DeleteOutlined /></a>
				</Popconfirm>,
			],
		},
	];

	const toggleExpandAll = () => expandedKeys.length > 1 ? setExpandedKeys(["all"]) : setExpandedKeys(allOrgKeys);
	const closeSearch = () => { setShowSearch(false); setSearchValue(""); };

	return (
		<PageContainer 
			header={{ title: "사용자 관리" }}
			childrenContentStyle={{ padding: 0, height: CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<Splitter style={{ height: "100%", background: token.colorBgContainer, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, overflow: "hidden" }}>
				
				{/* [Left] 조직 트리 영역 */}
				<Splitter.Panel defaultSize="25%" min="15%" max="40%">
					<ProCard 
						title="조직도" 
						headerBordered 
						headerStyle={{ minHeight: "56px" }}
						extra={
							<Space size={4} style={{ height: "32px", display: "flex", alignItems: "center" }}>
								<Tooltip title="조직 검색"><Button type="text" size="middle" icon={<SearchOutlined style={{ color: showSearch ? token.colorPrimary : undefined }} />} onClick={() => showSearch ? closeSearch() : setShowSearch(true)} /></Tooltip>
								<Tooltip title={expandedKeys.length > 1 ? "전체 접기" : "전체 펼치기"}><Button type="text" size="middle" icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} /></Tooltip>
							</Space>
						}
						style={{ height: "100%" }}
						bodyStyle={{ height: "calc(100% - 56px)", display: "flex", flexDirection: "column", padding: 0 }}
					>
						<div style={{ padding: "24px 24px 16px 24px", flexShrink: 0 }}>
							<div style={{ padding: "8px 12px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}` }}>
								{showSearch && (
									<div style={{ marginBottom: 12 }}>
										<Input
											placeholder="부서 검색 (ESC/Tab)"
											prefix={<SearchOutlined style={{ color: "#bfbfbf", fontSize: "12px" }} />}
											allowClear autoFocus value={searchValue}
											variant="filled"
											onChange={(e) => setSearchValue(e.target.value)}
											onKeyDown={(e) => { if (e.key === "Escape" || e.key === "Tab") setShowSearch(false); }}
											style={{ width: "100%", background: token.colorBgContainer, height: "32px", fontSize: "13px" }}
										/>
									</div>
								)}
								<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
									<span style={{ fontSize: "11px", color: token.colorTextSecondary, fontWeight: 500 }}>조직 선택</span>
									<Tooltip title="선택한 부서의 인원만 목록에 표시됩니다.">
										<TeamOutlined style={{ color: token.colorTextDescription, fontSize: "12px" }} />
									</Tooltip>
								</div>
							</div>
						</div>

						<div style={{ flex: 1, overflowY: "auto", padding: "8px 24px 24px 24px" }}>
							{isOrgLoading ? (
								<div style={{ textAlign: "center", padding: 24 }}><Spin tip="로딩..." /></div>
							) : (
								<Tree
									showLine={{ showLeafIcon: false }}
									showIcon
									treeData={treeData}
									expandedKeys={expandedKeys}
									onExpand={setExpandedKeys}
									selectedKeys={selectedOrgId ? [selectedOrgId] : ["all"]}
									onSelect={(keys) => { if (keys.length > 0) { const key = keys[0]; setSelectedOrgId(key === "all" ? undefined : key as number); } }}
								/>
							)}
						</div>
					</ProCard>
				</Splitter.Panel>

				{/* [Right] 사용자 목록 영역 */}
				<Splitter.Panel>
					<ProCard 
						title="사용자 목록" 
						headerBordered
						headerStyle={{ minHeight: "56px" }}
						style={{ height: "100%" }}
						bodyStyle={{ padding: 0, height: "calc(100% - 56px)", overflow: "hidden", display: "flex", flexDirection: "column" }}
					>
						<div style={{ padding: "16px 12px 0 12px", flexShrink: 0 }}>
							<div style={{ 
								padding: "8px 12px",
								background: token.colorFillAlter,
								borderRadius: token.borderRadiusLG,
								border: `1px solid ${token.colorBorderSecondary}`,
								display: "flex",
								justifyContent: "space-between",
								alignItems: "center"
							}}>
								<span style={{ fontSize: "11px", color: token.colorTextSecondary, fontWeight: 500 }}>조회 필터</span>
								<Space size={4}>
									<span style={{ fontSize: "11px", color: token.colorTextDescription }}>퇴사자 포함</span>
									<Switch 
										size="small" 
										checked={showInactive} 
										onChange={setShowInactive} 
										tabIndex={-1} // 탭 이동 제외
									/>
								</Space>
							</div>
						</div>

						<ProTable<User>
							scroll={{ y: "calc(100vh - 480px)" }}
							style={{ height: "100%" }}
							rowKey="id"
							params={{ org_id: selectedOrgId, is_active: showInactive ? undefined : true }}
							search={{ labelWidth: "auto", defaultCollapsed: false }}
							options={{ setting: true, density: true, fullScreen: true }}
							toolBarRender={() => [
								<Button key="button" icon={<PlusOutlined />} type="primary" onClick={() => { setEditingUser(null); setModalVisible(true); }}>
									사용자 등록
								</Button>,
							]}
							request={async (params) => {
								const { data } = await getUsersApi({ keyword: params.keyword, org_id: params.org_id, include_children: true, is_active: params.is_active });
								return { data: data.data || [], success: true };
							}}
							columns={columns}
							pagination={{ pageSize: 20, showSizeChanger: true }}
						/>
					</ProCard>
				</Splitter.Panel>
			</Splitter>

			<ModalForm
				title={editingUser ? "사용자 수정" : "신규 사용자"}
				open={modalVisible}
				onOpenChange={setModalVisible}
				onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }}
				initialValues={editingUser ? { ...editingUser, pos: editingUser.metadata?.pos } : { is_active: true, org_id: selectedOrgId }}
				modalProps={{ destroyOnClose: true }}
			>
				<ProFormText name="login_id" label="로그인 ID" rules={[{ required: true }]} disabled={!!editingUser} />
				{!editingUser && <ProFormText.Password name="password" label="비밀번호" rules={[{ required: true }]} />}
				<ProFormText name="name" label="성명" rules={[{ required: true }]} />
				<ProFormText name="emp_code" label="사번" rules={[{ required: true }]} />
				<ProFormText name="email" label="이메일" rules={[{ type: "email" }]} />
				<div style={{ marginBottom: 24 }}><label style={{ display: "block", marginBottom: 8, fontSize: "14px" }}>소속 부서</label><OrgTreeSelect name="org_id" /></div>
				<div style={{ marginBottom: 24 }}><label style={{ display: "block", marginBottom: 8, fontSize: "14px" }}>직위/직급</label><CodeSelect groupCode="POS_TYPE" name="pos" /></div>
				<ProFormSwitch name="is_active" label="재직 상태" />
			</ModalForm>
		</PageContainer>
	);
};

export default UserListPage;
