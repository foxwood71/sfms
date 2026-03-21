import {
	ApartmentOutlined,
	ClusterOutlined,
	DeleteOutlined,
	EditOutlined,
	FilterOutlined,
	PlusOutlined,
	ReloadOutlined,
	SaveOutlined,
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
	Tree,
	Tooltip,
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
 * 부서(조직) 관리 페이지 (Bento Standard v1.1)
 */
const OrganizationPage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const [form] = OrgFormCard.useForm?.() || [undefined]; 

	// 상태 관리
	const [selectedKey, setSelectedKey] = useState<React.Key | null>(null);
	const [isEditing, setIsEditing] = useState(false);
	const [isAdding, setIsAdding] = useState(false);
	const [showFilter, setShowFilter] = useState(false);
	const [searchValue, setSearchValue] = useState("");
	const [showInactive, setShowInactive] = useState(false);

	// 조직 데이터 조회 (React Query)
	const { data: orgResponse, isFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactive],
		queryFn: () => getOrganizationsApi("tree", showInactive ? undefined : true),
	});

	// 평면 구조 데이터 (선택된 항목 검색용)
	const { data: flatOrgs } = useQuery({
		queryKey: ["organizations", "flat"],
		queryFn: () => getOrganizationsApi("flat"),
	});

	const selectedOrg = useMemo(() => {
		if (!selectedKey || selectedKey === "root" || !flatOrgs?.data) return null;
		return flatOrgs.data.find((o: Organization) => o.id === Number(selectedKey)) || null;
	}, [selectedKey, flatOrgs]);

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

	// 트리 데이터 가공 (검색 필터 적용 및 최상단 '전체 조직도' 추가)
	const treeData = useMemo(() => {
		const filterTree = (items: Organization[]): any[] => {
			return items
				.map((item) => {
					const children = item.children ? filterTree(item.children) : [];
					const isMatched = item.name.toLowerCase().includes(searchValue.toLowerCase());
					if (!isMatched && children.length === 0) return null;
					return {
						key: item.id,
						title: item.is_active ? (
							item.name
						) : (
							<span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>
								{item.name}
							</span>
						),
						icon: <ClusterOutlined />,
						children,
					};
				})
				.filter(Boolean);
		};
		
		return [
			{
				key: "root",
				title: t("user.root_org"),
				icon: <ApartmentOutlined />,
				children: filterTree(orgResponse?.data || []),
			}
		];
	}, [orgResponse, searchValue, token, t]);

	return (
		<PageContainer
			header={{ title: t("org.title") }}
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; }
			`}</style>

			<Splitter style={{ height: "100%", background: token.colorBgContainer }}>
				{/* 좌측: 조직 트리 영역 */}
				<Splitter.Panel defaultSize="30%" min="20%">
					<ProCard
						title={t("org.tree_title")}
						headerBordered
						styles={{ header: { height: LAYOUT_CONSTANTS.HEADER_HEIGHT } }}
						extra={
							<Space size={2}>
								<Tooltip title={t("common.search")}>
									<Button
										type="text"
										icon={<FilterOutlined style={{ color: showFilter ? token.colorPrimary : undefined }} />}
										onClick={() => setShowFilter(!showFilter)}
									/>
								</Tooltip>
								<Tooltip title={t("common.reload")}>
									<Button
										type="text"
										icon={<ReloadOutlined />}
										onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })}
										loading={isFetching}
									/>
								</Tooltip>
								<Tooltip title={t("common.add")}>
									<Button
										type="primary"
										size="small"
										icon={<PlusOutlined />}
										onClick={() => {
											setIsAdding(true);
											setIsEditing(true);
										}}
									/>
								</Tooltip>
							</Space>
						}
					>
						{showFilter && (
							<div style={{ padding: "12px", background: token.colorFillAlter, marginBottom: 12, borderRadius: token.borderRadiusLG }}>
								<Input.Search
									placeholder={t("org.search_placeholder")}
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
						<div style={{ flex: 1, overflowY: "auto" }}>
							<Tree
								showIcon
								blockNode
								defaultExpandAll
								treeData={treeData}
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
				</Splitter.Panel>

				{/* 우측: 상세 정보 및 편집 영역 */}
				<Splitter.Panel>
					<ProCard
						title={isAdding ? t("org.new_org") : t("org.detail_title")}
						headerBordered
						styles={{ header: { height: LAYOUT_CONSTANTS.HEADER_HEIGHT } }}
						extra={
							(selectedKey && selectedKey !== "root") || isAdding ? (
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
						{selectedOrg || isAdding ? (
							<div style={{ padding: "0 24px", overflowY: "auto", flex: 1 }}>
								<OrgFormCard
									initialValues={isAdding ? { 
										parent_id: (selectedKey && selectedKey !== "root") ? Number(selectedKey) : null, 
										is_active: true, 
										sort_order: 10 
									} : selectedOrg}
									disabled={!isEditing}
									onFinish={(values) => saveMutation.mutate(values)}
									form={form}
								/>
							</div>
						) : (
							<Empty description={t("org.select_prompt")} style={{ marginTop: 100 }} />
						)}
					</ProCard>
				</Splitter.Panel>
			</Splitter>
		</PageContainer>
	);
};

export default OrganizationPage;
