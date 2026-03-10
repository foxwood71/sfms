import {
	ApartmentOutlined,
	CloseOutlined,
	ClusterOutlined,
	CompressOutlined,
	DeleteOutlined,
	EditOutlined,
	ExpandOutlined,
	FilterOutlined,
	HistoryOutlined,
	PlusOutlined,
	SaveOutlined,
	SearchOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import {
	PageContainer,
	ProCard,
	ProForm,
	ProFormDateTimePicker,
	ProFormDigit,
	ProFormSwitch,
	ProFormText,
	ProFormTextArea,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Col,
	Divider,
	Input,
	Popconfirm,
	Row,
	Space,
	Spin,
	Splitter,
	Switch,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import {
	createOrganizationApi,
	deleteOrganizationApi,
	getOrganizationsApi,
	updateOrganizationApi,
} from "../api";
import OrgTreeSelect from "../components/OrgTreeSelect";
import type { CreateOrgParams, Organization, UpdateOrgParams } from "../types";

/**
 * 조직도 관리 페이지 컴포넌트
 */
const OrganizationPage: React.FC = () => {
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	const [selectedKey, setSelectedKey] = useState<number | null>(null);
	const [isAdding, setIsAdding] = useState(false);
	const [isEditing, setIsEditing] = useState(false);

	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);
	const [searchValue, setSearchValue] = useState("");
	const [showSearch, setShowSearch] = useState(false);
	const [showInactive, setShowInactive] = useState(false);
	const [showFilter, setShowFilter] = useState(false); // 필터 박스 토글 상태

	const CONTENT_HEIGHT = "calc(100vh - 220px)";

	const {
		data: orgResponse,
		isLoading,
		isFetching,
	} = useQuery({
		queryKey: ["organizations", "tree", showInactive],
		queryFn: () => getOrganizationsApi("tree", showInactive ? undefined : true),
	});

	const getAllKeys = (items: Organization[]): React.Key[] => {
		let keys: React.Key[] = [];
		for (const item of items) {
			keys.push(item.id);
			if (item.children) keys = [...keys, ...getAllKeys(item.children)];
		}
		return keys;
	};

	const allKeys = useMemo(
		() => ["root", ...(orgResponse?.data ? getAllKeys(orgResponse.data) : [])],
		[orgResponse],
	);

	useEffect(() => {
		if (searchValue && orgResponse?.data) {
			setExpandedKeys(allKeys);
		} else {
			setExpandedKeys(["root"]);
		}
	}, [searchValue, allKeys]);

	useEffect(() => {
		if (orgResponse?.data && !expandedKeys.includes("root")) {
			setExpandedKeys((prev) => Array.from(new Set([...prev, "root"])));
		}
	}, [orgResponse, expandedKeys]);

	const flatData = useMemo(() => {
		const flatten = (items: Organization[]): Organization[] => {
			let result: Organization[] = [];
			for (const item of items) {
				result.push(item);
				if (item.children && item.children.length > 0) {
					result = result.concat(flatten(item.children));
				}
			}
			return result;
		};
		return orgResponse?.data ? flatten(orgResponse.data) : [];
	}, [orgResponse]);

	useEffect(() => {
		if (searchValue && flatData.length > 0) {
			const match = flatData.find((org) =>
				org.name.toLowerCase().includes(searchValue.toLowerCase()),
			);
			if (match) setSelectedKey(match.id);
		}
	}, [searchValue, flatData]);

	const selectedOrg = useMemo(() => {
		if (selectedKey === null || selectedKey === ("root" as any)) return null;
		return flatData.find((org) => org.id === selectedKey) || null;
	}, [selectedKey, flatData]);

	const treeData = useMemo(() => {
		const mapToTree = (items: Organization[], parentMatched = false): any[] => {
			return items
				.map((item) => {
					const isMatched =
						!searchValue ||
						item.name.toLowerCase().includes(searchValue.toLowerCase());
					const childrenNodes = item.children
						? mapToTree(item.children, parentMatched || isMatched)
						: [];
					const hasVisibleChildren = childrenNodes.length > 0;
					if (!parentMatched && !isMatched && !hasVisibleChildren) return null;

					return {
						key: item.id,
						title: (
							<Tooltip title={item.name} placement="right" mouseEnterDelay={0.5}>
								<span style={{ 
									whiteSpace: 'nowrap', // 줄바꿈 금지
									display: 'inline-block'
								}}>
									{item.is_active ? (
										item.name
									) : (
										<span
											style={{
												color: token.colorTextDisabled,
												textDecoration: "line-through",
												opacity: 0.6,
												fontStyle: "italic",
											}}
										>
											{item.name} (비활성)
										</span>
									)}
								</span>
							</Tooltip>
						),
						icon:
							item.children && item.children.length > 0 ? (
								<ClusterOutlined />
							) : (
								<ApartmentOutlined />
							),
						children: childrenNodes,
					};
				})
				.filter(Boolean);
		};
		return [
			{
				key: "root",
				title: "전체 조직도",
				icon: <TeamOutlined />,
				children: orgResponse?.data ? mapToTree(orgResponse.data) : [],
			},
		];
	}, [orgResponse, searchValue, token]);

	// [수정] 친절한 에러 메시지 처리 (기존 유지)
	const saveMutation = useMutation({
		mutationFn: (values: any) => {
			const payload = { ...values, code: values.code?.toUpperCase() };
			if (isAdding) return createOrganizationApi(payload as CreateOrgParams);
			if (selectedKey)
				return updateOrganizationApi(selectedKey, payload as UpdateOrgParams);
			throw new Error("대상 조직이 선택되지 않았습니다.");
		},
		onSuccess: async (response) => {
			message.success("조직 정보가 안전하게 저장되었습니다.");
			await queryClient.invalidateQueries({ queryKey: ["organizations"] });
			if (isAdding && response.data?.id) {
				setSelectedKey(response.data.id);
			}
			setIsAdding(false);
			setIsEditing(false);
		},
		onError: (error: any) => {
			const errorMsg =
				error.response?.data?.message ||
				error.message ||
				"알 수 없는 오류가 발생했습니다.";
			message.error(`저장에 실패했습니다: ${errorMsg}`);
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteOrganizationApi(id),
		onSuccess: async () => {
			message.success("조직이 삭제되었습니다.");
			setSelectedKey(null);
			setIsEditing(false);
			await queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (error: any) => {
			const errorMsg =
				error.response?.data?.message ||
				error.message ||
				"삭제 권한이 없거나 하위 데이터가 존재합니다.";
			message.error(`삭제 실패: ${errorMsg}`);
		},
	});

	const handleAdd = () => { setIsAdding(true); setIsEditing(true); };
	const handleCancel = () => { if (isAdding) { setIsAdding(false); setSelectedKey(null); } setIsEditing(false); };
	const toggleExpandAll = () => expandedKeys.length > 1 ? setExpandedKeys(["root"]) : setExpandedKeys(allKeys);
	const closeSearch = () => { setShowSearch(false); setSearchValue(""); };

	const isDisabled = !isEditing;

	return (
		<PageContainer
			header={{ title: "부서 관리" }}
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
						title={
							showSearch ? (
								<div style={{ display: 'flex', alignItems: 'center', width: '100%' }}>
									<Input
										placeholder="부서 검색..."
										variant="borderless"
										autoFocus
										value={searchValue}
										onChange={(e) => setSearchValue(e.target.value)}
										onKeyDown={(e) => { if (e.key === "Escape") closeSearch(); }}
										style={{ padding: 0, width: '100%' }}
									/>
								</div>
							) : ( "조직도" )
						}
						headerBordered
						headerStyle={{ minHeight: "56px" }}
						extra={
							<Space size={2} style={{ height: "32px", display: "flex", alignItems: "center" }}>
								<Tooltip title="신규 추가"><Button type="text" size="middle" icon={<PlusOutlined style={{ color: token.colorPrimary }} />} onClick={handleAdd} /></Tooltip>
								<Tooltip title={showSearch ? "검색 종료" : "조직 검색"}><Button type="text" size="middle" icon={<SearchOutlined style={{ color: showSearch ? token.colorPrimary : undefined }} />} onClick={() => showSearch ? closeSearch() : setShowSearch(true)} /></Tooltip>
								<Tooltip title="필터"><Button type="text" size="middle" icon={<FilterOutlined style={{ color: showFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowFilter(!showFilter)} /></Tooltip>
								<Tooltip title={expandedKeys.length > 1 ? "전체 접기" : "전체 펼치기"}><Button type="text" size="middle" icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} /></Tooltip>
							</Space>
						}
						style={{ height: "100%" }}
						bodyStyle={{
							height: "calc(100% - 56px)",
							display: "flex",
							flexDirection: "column",
							padding: 0,
							overflowX: 'auto' // 가로 스크롤 허용
						}}
					>
						{showFilter && (
							<div style={{ padding: "16px 24px 8px 24px", flexShrink: 0 }}>
								<div style={{ padding: "8px 12px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
									<span style={{ fontSize: "11px", color: token.colorTextSecondary, fontWeight: 500 }}>필터</span>
									<Space size={4}>
										<span style={{ fontSize: "11px", color: showInactive ? token.colorError : token.colorSuccess, fontWeight: 500 }}>{showInactive ? "비활성 포함" : "활성 조직만"}</span>
										<Switch size="small" checked={showInactive} onChange={setShowInactive} loading={isFetching} tabIndex={-1} />
									</Space>
								</div>
							</div>
						)}
						<div style={{ flex: 1, overflow: "auto", padding: "16px 24px" }}>
							{isLoading && !isFetching ? (
								<div style={{ textAlign: "center", padding: 24 }}><Spin tip="로딩..." /></div>
							) : (
								<Tree
									showLine={{ showLeafIcon: false }}
									showIcon
									treeData={treeData}
									expandedKeys={expandedKeys}
									onExpand={setExpandedKeys}
									selectedKeys={selectedKey ? [selectedKey] : ["root"]}
									onSelect={(keys) => {
										if (keys.length > 0) {
											const key = keys[0];
											if (key === "root") { setSelectedKey(null); setIsAdding(false); setIsEditing(false); } 
											else { setSelectedKey(key as number); setIsAdding(false); setIsEditing(false); }
										}
									}}
								/>
							)}
						</div>
					</ProCard>
				</Splitter.Panel>

				<Splitter.Panel>
					<ProCard
						title={isAdding ? "신규 부서 등록" : selectedOrg ? `[${selectedOrg.name}] 상세 정보` : "부서 상세 정보"}
						headerBordered
						headerStyle={{ minHeight: "56px" }}
						extra={
							<div style={{ height: "32px", display: "flex", alignItems: "center" }}>
								{!isAdding && selectedOrg && (
									<Space size={8}>
										{!isEditing && <Button icon={<EditOutlined />} onClick={() => setIsEditing(true)} type="primary" ghost size="small">수정</Button>}
										<Popconfirm title="삭제?" onConfirm={() => deleteMutation.mutate(selectedOrg.id)} okText="삭제" cancelText="취소"><Button danger type="text" icon={<DeleteOutlined />} loading={deleteMutation.isPending} size="small">삭제</Button></Popconfirm>
									</Space>
								)}
							</div>
						}
						style={{ height: "100%" }}
						bodyStyle={{ height: "calc(100% - 56px)", overflowY: "auto", padding: "24px", display: "flex", flexDirection: "column" }}
					>
						{selectedOrg || isAdding ? (
							<ProForm
								key={isAdding ? "new" : `${selectedOrg?.id}-${isEditing}`}
								initialValues={isAdding ? { is_active: true, sort_order: 10, parent_id: selectedKey } : selectedOrg}
								readonly={false}
								onFinish={async (values) => { await saveMutation.mutateAsync(values); return true; }}
								submitter={isEditing ? {
									render: (props) => (
										<div style={{ position: "sticky", bottom: -24, left: -24, right: -24, padding: "16px 24px", background: token.colorBgContainer, borderTop: `1px solid ${token.colorBorderSecondary}`, zIndex: 10, display: "flex", justifyContent: "flex-end", gap: "8px", marginTop: "auto" }}>
											<Button icon={<CloseOutlined />} onClick={handleCancel}>취소</Button>
											<Button type="primary" icon={<SaveOutlined />} onClick={() => props.form?.submit()} loading={saveMutation.isPending}>{isAdding ? "등록" : "저장"}</Button>
										</div>
									),
								} : false}
							>
								<Row gutter={24}>
									<Col span={12}><ProFormText name="code" label="조직 코드" rules={[{ required: true }, { max: 50 }]} disabled={!isAdding || isDisabled} getValueFromEvent={(e) => e.target.value.toUpperCase()} fieldProps={{ showCount: true, maxLength: 50, style: { textTransform: "uppercase" } }} /></Col>
									<Col span={12}><ProFormText name="name" label="조직 명칭" rules={[{ required: true, message: "명칭 필수" }, { max: 100 }]} disabled={isDisabled} fieldProps={{ showCount: true, maxLength: 100 }} /></Col>
								</Row>
								<ProForm.Item name="parent_id" label="상위 조직"><OrgTreeSelect placeholder="상위 선택" activeOnly={false} disabled={isDisabled} /></ProForm.Item>
								<Row gutter={24}>
									<Col span={12}><ProFormDigit name="sort_order" label="정렬 순서" initialValue={10} min={0} max={9999} disabled={isDisabled} /></Col>
									<Col span={12}><ProFormSwitch name="is_active" label="조직 상태" disabled={isDisabled} fieldProps={{ checkedChildren: "활성", unCheckedChildren: "비활성" }} /></Col>
								</Row>
								<ProFormTextArea name="description" label="비고" placeholder="참고사항을 입력하세요." disabled={isDisabled} fieldProps={{ rows: 5, showCount: true, maxLength: 255 }} />
								{!isAdding && selectedOrg && (
									<>
										<Divider orientation="left" style={{ margin: "16px 0" }}><Space><HistoryOutlined /> 이력 정보</Space></Divider>
										<Row gutter={24}>
											<Col span={12}><ProFormDateTimePicker name="created_at" label="생성 일시" disabled fieldProps={{ style: { width: "100%" } }} /></Col>
											<Col span={12}><ProFormDateTimePicker name="updated_at" label="최종 수정 일시" disabled fieldProps={{ style: { width: "100%" } }} /></Col>
										</Row>
									</>
								)}
							</ProForm>
						) : (
							<div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center", alignItems: "center", color: "#bfbfbf" }}>
								<TeamOutlined style={{ fontSize: 64, marginBottom: 16, opacity: 0.2 }} />
								<p>좌측 트리에서 조직을 선택하거나 새 조직을 추가하세요.</p>
							</div>
						)}
					</ProCard>
				</Splitter.Panel>
			</Splitter>
		</PageContainer>
	);
};

export default OrganizationPage;
