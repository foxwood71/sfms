import {
	ApartmentOutlined,
	ClusterOutlined,
	CompressOutlined,
	DeleteOutlined,
	ExpandOutlined,
	FilterOutlined,
	PlusOutlined,
	ReloadOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App, Button, Input, Space, Spin, Splitter, Switch, Tooltip, Tree, theme } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import {
	createOrganizationApi,
	deleteOrganizationApi,
	getOrganizationsApi,
	updateOrganizationApi,
} from "../api";
import OrgFormCard from "../components/OrgFormCard";
import type { Organization } from "../types";

const OrganizationPage: React.FC = () => {
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	// 부서관리 트리 선택 상태 관리 (Key 기반으로 통일)
	const [selectedKey, setSelectedKey] = useState<React.Key>("root");
	const [showInactive, setShowInactive] = useState(false);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>(["root"]);
	const [searchValue, setSearchValue] = useState("");
	const [showOrgFilter, setShowOrgFilter] = useState(false);

	const CONTENT_HEIGHT = "calc(100vh - 220px)";
	const HEADER_HEIGHT = "56px";

	// 조직 데이터 조회
	const {
		data: orgResponse,
		isLoading,
		isFetching,
	} = useQuery({
		queryKey: ["organizations", "tree", showInactive],
		queryFn: () => getOrganizationsApi("tree", showInactive ? undefined : true),
	});

	// 평면 데이터 추출 (검색 및 상세 조회용)
	const flatData = useMemo(() => {
		const flatten = (items: Organization[]): Organization[] => {
			let result: Organization[] = [];
			for (const item of items) {
				result.push(item);
				if (item.children) result = [...result, ...flatten(item.children)];
			}
			return result;
		};
		return orgResponse?.data ? flatten(orgResponse.data) : [];
	}, [orgResponse]);

	// 현재 선택된 조직 객체
	const selectedOrg = useMemo(() => {
		if (selectedKey === "root") return null;
		return flatData.find((org) => org.id === Number(selectedKey)) || null;
	}, [selectedKey, flatData]);

	const getAllKeys = (items: Organization[]): React.Key[] => {
		let keys: React.Key[] = [];
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
			return items
				.map((item) => {
					const isMatched = !searchValue || item.name.toLowerCase().includes(searchValue.toLowerCase());
					const childrenNodes = item.children ? mapToTree(item.children, parentMatched || isMatched) : [];
					const hasVisibleChildren = childrenNodes.length > 0;

					if (!parentMatched && !isMatched && !hasVisibleChildren) return null;

					return {
						key: item.id,
						title: (
							<Tooltip title={item.name} placement="right" mouseEnterDelay={0.5}>
								<span style={{ whiteSpace: "nowrap", display: "inline-block" }}>
									{item.is_active ? (
										item.name
									) : (
										<span
											style={{
												textDecoration: "line-through",
												color: token.colorTextDisabled,
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
						icon: item.children && item.children.length > 0 ? <ClusterOutlined /> : <ApartmentOutlined />,
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
				children: mapToTree(orgResponse?.data || []),
			},
		];
	}, [orgResponse, searchValue, token]);

	// 뮤테이션 정의
	const createMutation = useMutation({
		mutationFn: createOrganizationApi,
		onSuccess: (res) => {
			message.success("조직이 생성되었습니다.");
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
			setSelectedKey(res.data.id);
		},
		onError: (err: any) => message.error(err.response?.data?.message || "생성 실패"),
	});

	const updateMutation = useMutation({
		mutationFn: ({ id, data }: { id: number; data: any }) => updateOrganizationApi(id, data),
		onSuccess: () => {
			message.success("수정되었습니다.");
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || "수정 실패"),
	});

	const deleteMutation = useMutation({
		mutationFn: deleteOrganizationApi,
		onSuccess: () => {
			message.success("삭제되었습니다.");
			setSelectedKey("root");
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || "삭제 실패"),
	});

	const toggleExpandAll = () => {
		if (expandedKeys.length > 1) {
			setExpandedKeys(["root"]);
		} else {
			setExpandedKeys(["root", ...getAllKeys(orgResponse?.data || [])]);
		}
	};

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
				{/* 좌측: 조직도 트리 판넬 */}
				<Splitter.Panel defaultSize="25%" min="15%" max="40%">
					<ProCard
						title={
							<div style={{ height: "32px", display: "flex", alignItems: "center" }}>
								<span style={{ fontWeight: 600 }}>조직도</span>
							</div>
						}
						headerBordered
						headerStyle={{ height: HEADER_HEIGHT, padding: "0 16px" }}
						extra={
							<div style={{ height: "32px", display: "flex", alignItems: "center" }}>
								<Space size={2}>
									<Tooltip title="필터 및 검색">
										<Button
											type="text"
											size="middle"
											icon={
												<FilterOutlined
													style={{ color: showOrgFilter ? token.colorPrimary : undefined }}
												/>
											}
											onClick={() => setShowOrgFilter(!showOrgFilter)}
										/>
									</Tooltip>
									<Tooltip title={expandedKeys.length > 1 ? "전체 접기" : "전체 펼치기"}>
										<Button
											type="text"
											size="middle"
											icon={expandedKeys.length > 1 ? <CompressOutlined /> : <ExpandOutlined />}
											onClick={toggleExpandAll}
										/>
									</Tooltip>
									<Button
										type="text"
										size="middle"
										icon={<ReloadOutlined />}
										onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })}
										loading={isFetching}
									/>
									<Divider type="vertical" />
									<Button
										key="add"
										icon={<PlusOutlined />}
										type="primary"
										size="small"
										onClick={() => {
											const parentId = selectedOrg ? selectedOrg.id : null;
											createMutation.mutate({
												name: "새 조직",
												code: `ORG_${Date.now().toString().slice(-4)}`,
												parent_id: parentId,
												sort_order: 10,
											});
										}}
									>
										추가
									</Button>
								</Space>
							</div>
						}
						style={{ height: "100%" }}
						bodyStyle={{
							height: `calc(100% - ${HEADER_HEIGHT})`,
							display: "flex",
							flexDirection: "column",
							padding: 0,
						}}
					>
						{showOrgFilter && (
							<div style={{ padding: "16px 16px 8px 16px", flexShrink: 0 }}>
								<div
									style={{
										padding: "12px",
										background: token.colorFillAlter,
										borderRadius: token.borderRadiusLG,
										border: `1px solid ${token.colorBorderSecondary}`,
									}}
								>
									<div style={{ marginBottom: 8 }}>
										<Input.Search
											placeholder="부서명 검색..."
											size="small"
											allowClear
											value={searchValue}
											onChange={(e) => setSearchValue(e.target.value)}
											onSearch={(val) => setSearchValue(val)}
										/>
									</div>
									<div
										style={{
											display: "flex",
											justifyContent: "space-between",
											alignItems: "center",
										}}
									>
										<span
											style={{
												fontSize: "11px",
												color: token.colorTextSecondary,
												fontWeight: 500,
											}}
										>
											비활성 포함
										</span>
										<Switch
											size="small"
											checked={showInactive}
											onChange={setShowInactive}
											loading={isFetching}
										/>
									</div>
								</div>
							</div>
						)}

						<div style={{ flex: 1, overflowY: "auto", padding: "16px 24px" }}>
							{isLoading && !isFetching ? (
								<div style={{ textAlign: "center", padding: 24 }}>
									<Spin tip="로딩..." />
								</div>
							) : (
								<Tree
									showLine={{ showLeafIcon: false }}
									showIcon
									blockNode
									treeData={treeData}
									expandedKeys={expandedKeys}
									onExpand={(keys) => setExpandedKeys(keys as any)}
									selectedKeys={[selectedKey]}
									onSelect={(keys) => {
										// 선택 해제 시 root로 자동 선택되도록 보정
										const key = keys.length > 0 ? keys[0] : "root";
										setSelectedKey(key);
									}}
								/>
							)}
						</div>
					</ProCard>
				</Splitter.Panel>

				{/* 우측: 조직 상세 정보 판넬 */}
				<Splitter.Panel>
					<ProCard
						title={
							<div style={{ height: "32px", display: "flex", alignItems: "center" }}>
								<span style={{ fontWeight: 600 }}>부서 상세 정보</span>
							</div>
						}
						headerBordered
						headerStyle={{ height: HEADER_HEIGHT, padding: "0 16px" }}
						extra={
							selectedOrg && (
								<div style={{ height: "32px", display: "flex", alignItems: "center" }}>
									<Button
										danger
										icon={<DeleteOutlined />}
										size="small"
										onClick={() => deleteMutation.mutate(selectedOrg.id)}
									>
										조직 삭제
									</Button>
								</div>
							)
						}
						style={{ height: "100%" }}
						bodyStyle={{ padding: "24px", overflowY: "auto", height: `calc(100% - ${HEADER_HEIGHT})` }}
					>
						{selectedOrg ? (
							<OrgFormCard
								key={selectedOrg.id}
								initialValues={selectedOrg}
								onFinish={async (values) => {
									updateMutation.mutate({ id: selectedOrg.id, data: values });
									return true;
								}}
							/>
						) : (
							<div
								style={{
									height: "100%",
									display: "flex",
									flexDirection: "column",
									justifyContent: "center",
									alignItems: "center",
									color: token.colorTextDisabled,
								}}
							>
								<TeamOutlined style={{ fontSize: 48, marginBottom: 16, opacity: 0.2 }} />
								<p>좌측 조직도에서 부서를 선택하면 상세 정보를 확인할 수 있습니다.</p>
							</div>
						)}
					</ProCard>
				</Splitter.Panel>
			</Splitter>
		</PageContainer>
	);
};

const Divider: React.FC = () => {
	const { token } = theme.useToken();
	return (
		<div
			style={{
				width: "1px",
				height: "14px",
				backgroundColor: token.colorBorderSecondary,
				margin: "0 8px",
			}}
		/>
	);
};

export default OrganizationPage;
