import {
	ClusterOutlined,
	CompressOutlined,
	DeleteOutlined,
	EditOutlined,
	ExpandOutlined,
	FilterOutlined,
	PlusOutlined,
	ReloadOutlined,
	SaveOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Empty,
	Input,
	Popconfirm,
	Space,
	Splitter,
	Switch,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import {
	createOrganizationApi,
	deleteOrganizationApi,
	getOrganizationsApi,
	updateOrganizationApi,
} from "@/domains/usr/api";
import OrgFormCard from "@/domains/usr/components/OrgFormCard";
import type { CreateOrgParams, Organization, UpdateOrgParams } from "@/domains/usr/types";

/**
 * 부서(조직) 관리 페이지
 */
const OrganizationPage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const [form] = OrgFormCard.useForm?.() || [undefined]; 

	// 상태 관리
	const [selectedKey, setSelectedKey] = useState<React.Key | null>(null);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);
	const [isEditing, setIsEditing] = useState(false);
	const [isAdding, setIsAdding] = useState(false);
	const [showFilter, setShowFilter] = useState(false);
	const [searchValue, setSearchValue] = useState("");
	const [showInactive, setShowInactive] = useState(false);

	// Splitter 초기 크기 결정 (비제어 모드)
	const initialSplitterSize = useMemo(() => {
		const saved = localStorage.getItem("sfms_org_splitter_size");
		// 저장된 값이 숫자 형태의 문자열이면 숫자로 변환, 아니면 기본값 25%
		return saved && !isNaN(Number(saved)) ? Number(saved) : "25%";
	}, []);

	const handleSplitterChange = (sizes: number[]) => {
		if (sizes.length > 0) {
			localStorage.setItem("sfms_org_splitter_size", String(sizes[0]));
		}
	};

	// 조직 데이터 조회
	const { data: orgResponse, isFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactive],
		queryFn: () => getOrganizationsApi("tree", showInactive ? undefined : true),
	});

	// 모든 조직 데이터를 평면화하여 선택 기능에 사용 (API 의존성 제거 및 정합성 확보)
	const allOrgs = useMemo(() => {
		const flatten = (items: Organization[]): Organization[] => {
			let result: Organization[] = [];
			for (const item of items) {
				result.push(item);
				if (item.children && item.children.length > 0) {
					result = [...result, ...flatten(item.children)];
				}
			}
			return result;
		};
		return flatten(orgResponse?.data || []);
	}, [orgResponse]);

	const selectedOrg = useMemo(() => {
		if (selectedKey === null || selectedKey === undefined || allOrgs.length === 0) return null;
		
		const targetId = Number(selectedKey);
		return allOrgs.find((o) => Number(o.id) === targetId) || null;
	}, [selectedKey, allOrgs]);

	// 트리 데이터 가공 (검색 필터 적용)
	const treeData = useMemo(() => {
		const mapToTree = (items: Organization[]): any[] => {
			return items
				.map((item) => {
					const filteredChildren = item.children ? mapToTree(item.children) : [];
					const isMatched = item.name.toLowerCase().includes(searchValue.toLowerCase());
					
					// 검색어가 있고, 본인도 매칭 안되고 자식도 없으면 제외
					if (searchValue && !isMatched && filteredChildren.length === 0) return null;
					
					const node: any = {
						key: item.id,
						title: item.is_active ? (
							item.name
						) : (
							<span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>
								{item.name}
							</span>
						),
						icon: <ClusterOutlined />,
					};

					if (filteredChildren.length > 0) {
						node.children = filteredChildren;
					}

					return node;
				})
				.filter(Boolean);
		};

		const data = [{
			key: "root",
			title: t("common.company_name"),
			icon: <TeamOutlined />,
			children: mapToTree(orgResponse?.data || []),
		}];

		// 초기 로딩 시 모든 키를 확장 대상으로 수집
		if (expandedKeys.length === 0 && data[0].children && data[0].children.length > 0) {
			const getAllKeys = (items: any[]): React.Key[] => {
				let keys: React.Key[] = ["root"];
				for (const item of items) {
					keys.push(item.key);
					if (item.children) keys = [...keys, ...getAllKeys(item.children)];
				}
				return keys;
			};
			setExpandedKeys(getAllKeys(data));
		}
		return data;
	}, [orgResponse, searchValue, token, t]);

	// 트리 전체 확장/축소 제어
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

	// 생성/수정/삭제 Mutation
	const saveMutation = useMutation({
		mutationFn: (values: CreateOrgParams | UpdateOrgParams) => {
			if (isAdding) return createOrganizationApi(values as CreateOrgParams);
			return updateOrganizationApi(Number(selectedKey), values as UpdateOrgParams);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setIsEditing(false);
			setIsAdding(false);
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || t("common.save_failure")),
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteOrganizationApi(id),
		onSuccess: () => {
			message.success(t("common.delete_success"));
			setSelectedKey(null);
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || t("common.delete_failure")),
	});

	return (
		<PageContainer
			header={{ title: t("org.title") }}
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				.ant-pro-card-body { 
					overflow: hidden !important; 
					display: flex; 
					flex-direction: column; 
					height: 100%; 
					padding: 0 !important;
				}
				.sfms-tree-wrapper {
					flex: 1;
					overflow-y: auto;
					padding: 8px;
				}
				/* 스크롤바가 필요 없을 때는 공간을 전혀 차지하지 않도록 설정 */
				.sfms-tree-wrapper::-webkit-scrollbar {
					width: 6px;
				}
				.sfms-tree-wrapper::-webkit-scrollbar-thumb {
					background: transparent;
					border-radius: 3px;
				}
				.sfms-tree-wrapper:hover::-webkit-scrollbar-thumb {
					background: rgba(0, 0, 0, 0.15);
				}
			`}</style>

			<Splitter 
				style={{ height: "100%", background: "transparent", gap: 2 }}
				onResizeEnd={handleSplitterChange}
			>
				{/* 좌측: 조직 트리 영역 (Bento Box 1) */}
				<Splitter.Panel defaultSize={initialSplitterSize} min="15%" max="40%">
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard
							title={t("org.tree_title")}
							headerBordered
							headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
							extra={
								<Space size={2}>
									<Tooltip title={expandedKeys.length > 0 ? t("common.collapse_all") : t("common.expand_all")}>
										<Button
											type="text"
											icon={expandedKeys.length > 0 ? <CompressOutlined /> : <ExpandOutlined />}
											onClick={toggleExpandAll}
										/>
									</Tooltip>
									<Button
										type="text"
										icon={<FilterOutlined style={{ color: showFilter ? token.colorPrimary : undefined }} />}
										onClick={() => setShowFilter(!showFilter)}
									/>
									<Button
										type="text"
										icon={<ReloadOutlined />}
										onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })}
										loading={isFetching}
									/>
									<Button
										type="primary"
										size="small"
										icon={<PlusOutlined />}
										onClick={() => {
											setIsAdding(true);
											setIsEditing(true);
											setSelectedKey(null);
										}}
									>
										{t("common.add")}
									</Button>
								</Space>
							}
						>
							{showFilter && (
								<div style={{ padding: "8px 16px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}`, borderRadius: 8, margin: "8px 8px 0 8px" }}>
									<Input.Search										placeholder={t("org.search_placeholder")}
										size="small"
										allowClear
										onChange={(e) => setSearchValue(e.target.value)}
										style={{ marginBottom: 8 }}
									/>
									<div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
										<span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("org.include_inactive")}</span>
										<Switch size="small" checked={showInactive} onChange={setShowInactive} />
									</div>
								</div>
							)}
							<div className="sfms-tree-wrapper">
								<Tree
									showIcon
									showLine={{ showLeafIcon: false }}
									blockNode
									treeData={treeData}
									expandedKeys={expandedKeys}
									onExpand={setExpandedKeys as any}
									selectedKeys={selectedKey ? [selectedKey] : []}
									onSelect={(keys) => {
										if (keys.length > 0) {
											setSelectedKey(keys[0]);
											setIsEditing(false);
											setIsAdding(false);
										}
									}}
								/>
							</div>
						</ProCard>
					</div>
				</Splitter.Panel>

				{/* 우측: 상세 정보 및 편집 영역 (Bento Box 2) */}
				<Splitter.Panel>
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard
							title={isAdding ? t("org.new_org") : t("org.detail_title")}
							headerBordered
							headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
							extra={
								selectedKey || isAdding ? (
									<Space>
										{!isEditing ? (
											<>
												<Popconfirm
													title={t("org.delete_confirm")}
													description={t("org.delete_desc")}
													onConfirm={() => deleteMutation.mutate(Number(selectedKey))}
													okText={t("common.delete")}
													cancelText={t("common.cancel")}
													disabled={selectedOrg?.children && selectedOrg.children.length > 0}
												>
													<Button
														danger
														type="text"
														icon={<DeleteOutlined />}
														disabled={selectedOrg?.children && selectedOrg.children.length > 0}
													>
														{t("common.delete")}
													</Button>
												</Popconfirm>
												<Button type="primary" icon={<EditOutlined />} onClick={() => setIsEditing(true)}>
													{t("common.edit")}
												</Button>
											</>
										) : (
											<>
												<Button onClick={() => {
													setIsEditing(false);
													setIsAdding(false);
												}}>
													{t("common.cancel")}
												</Button>
												<Button
													type="primary"
													icon={<SaveOutlined />}
													loading={saveMutation.isPending}
													onClick={() => form?.submit()}
												>
													{t("common.save")}
												</Button>
											</>
										)}
									</Space>
								) : null
							}
						>
							<div style={{ padding: "24px", overflowY: "auto", flex: 1, height: "100%" }}>
								{selectedOrg || isAdding ? (
									<OrgFormCard
										initialValues={isAdding ? { parent_id: selectedKey ? Number(selectedKey) : null, is_active: true, sort_order: 10 } : selectedOrg}
										disabled={!isEditing}
										onFinish={(values) => saveMutation.mutate(values)}
										form={form}
									/>
								) : (
									<Empty description={t("org.select_prompt")} style={{ marginTop: 100 }} />
								)}
							</div>
						</ProCard>
					</div>
				</Splitter.Panel>
			</Splitter>
		</PageContainer>
	);
};

export default OrganizationPage;
