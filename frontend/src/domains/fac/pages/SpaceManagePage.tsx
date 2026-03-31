import {
	ApartmentOutlined,
	ArrowRightOutlined,
	ClusterOutlined,
	DeleteOutlined,
	EditOutlined,
	FilterOutlined,
	InfoCircleOutlined,
	PlusOutlined,
	ReloadOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Descriptions,
	Empty,
	Input,
	Popconfirm,
	Select,
	Space,
	Splitter,
	Tag,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type { DataNode } from "antd/es/tree";
import type { AxiosError } from "axios";
import type React from "react";
import { useCallback, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import {
	createSpaceApi,
	deleteSpaceApi,
	getFacilitiesApi,
	getSpaceTreeApi,
	updateSpaceApi,
} from "../api";
import SpaceFormDrawer from "../components/SpaceFormDrawer";
import type { SpaceParams, Space as SpaceType } from "../types";

/**
 * 에러 응답 구조 정의
 */
interface ApiErrorResponse {
	message?: string;
}

/**
 * 트리 노드 타입 가드 (Zero Any Policy)
 */
interface SpaceTreeNode extends DataNode {
	id: number;
	facility_id: number;
}

/**
 * 공간 계층 관리 페이지 (Bento Standard v1.1)
 */
const SpaceManagePage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const navigate = useNavigate();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	// 상태 관리
	const [selectedFacilityId, setSelectedFacilityId] = useState<number | null>(
		null,
	);
	const [selectedKey, setSelectedKey] = useState<React.Key | null>(null);
	const [showFilter, setShowFilter] = useState(false);
	const [searchValue, setSearchValue] = useState("");

	// 드로어 상태 (Union Type으로 any 제거)
	const [drawerOpen, setDrawerOpen] = useState(false);
	const [editingSpace, setEditingSpace] = useState<
		SpaceType | SpaceParams | null
	>(null);

	// 시설 목록 조회
	const { data: facilities } = useQuery({
		queryKey: ["facilities"],
		queryFn: getFacilitiesApi,
	});

	// 선택된 시설의 공간 트리 조회
	const { data: spaceRes, isFetching: isTreeLoading } = useQuery({
		queryKey: ["spaces", "tree", selectedFacilityId],
		queryFn: async () => {
			if (!selectedFacilityId)
				return {
					data: [],
					success: true,
					domain: "FAC",
					code: "SUCCESS",
					message: "",
				};
			return getSpaceTreeApi(selectedFacilityId);
		},
		enabled: !!selectedFacilityId,
	});

	// 평면 구조 데이터 (선택된 노드 찾기용)
	const flatSpaces = useMemo(() => {
		const flatten = (items: SpaceType[]): SpaceType[] => {
			let result: SpaceType[] = [];
			for (const item of items) {
				result.push(item);
				if (item.children) result = result.concat(flatten(item.children));
			}
			return result;
		};
		return flatten(spaceRes?.data || []);
	}, [spaceRes]);

	const selectedSpace = useMemo(() => {
		if (!selectedKey || selectedKey === "root") return null;
		return flatSpaces.find((s) => s.id === Number(selectedKey)) || null;
	}, [selectedKey, flatSpaces]);

	// 저장 Mutation
	const saveMutation = useMutation({
		mutationFn: (values: SpaceParams) => {
			if (editingSpace && "id" in editingSpace)
				return updateSpaceApi(editingSpace.id, values);
			if (!selectedFacilityId) {
				throw new Error("No facility selected");
			}
			return createSpaceApi({ ...values, facility_id: selectedFacilityId });
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setDrawerOpen(false);
			queryClient.invalidateQueries({
				queryKey: ["spaces", "tree", selectedFacilityId],
			});
		},
		onError: (err: AxiosError<ApiErrorResponse>) => {
			message.error(err.response?.data?.message || t("common.save_failure"));
		},
	});

	// 삭제 Mutation
	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteSpaceApi(id),
		onSuccess: () => {
			message.success(t("common.delete_success"));
			setSelectedKey(null);
			queryClient.invalidateQueries({
				queryKey: ["spaces", "tree", selectedFacilityId],
			});
		},
		onError: (err: AxiosError<ApiErrorResponse>) => {
			message.error(err.response?.data?.message || t("common.delete_failure"));
		},
	});

	// Splitter 초기 크기 결정 (localStorage)
	const initialSplitterSize = useMemo(() => {
		const saved = localStorage.getItem("sfms_fac_splitter_size");
		return saved && !Number.isNaN(Number(saved)) ? Number(saved) : "30%";
	}, []);

	const handleSplitterChange = useCallback((sizes: number[]) => {
		if (sizes.length > 0) {
			localStorage.setItem("sfms_fac_splitter_size", String(sizes[0]));
		}
	}, []);

	// 트리 데이터 가공
	const treeData = useMemo(() => {
		const mapNodes = (items: SpaceType[]): SpaceTreeNode[] => {
			return items
				.map((item) => {
					const children = item.children ? mapNodes(item.children) : [];
					const isMatched = item.name
						.toLowerCase()
						.includes(searchValue.toLowerCase());
					if (searchValue && !isMatched && children.length === 0) return null;

					return {
						key: item.id,
						id: item.id,
						facility_id: item.facility_id,
						title: item.is_active ? (
							item.name
						) : (
							<span
								style={{
									color: token.colorTextDisabled,
									textDecoration: "line-through",
								}}
							>
								{item.name}
							</span>
						),
						icon: <ClusterOutlined />,
						children,
					} as SpaceTreeNode;
				})
				.filter((node): node is SpaceTreeNode => node !== null);
		};

		const rootTitle =
			facilities?.data?.find((f) => f.id === selectedFacilityId)?.name ||
			t("fac.space.tree_title");

		return [
			{
				key: "root",
				title: rootTitle,
				icon: <ApartmentOutlined />,
				children: mapNodes(spaceRes?.data || []),
			},
		];
	}, [spaceRes, facilities, selectedFacilityId, searchValue, token, t]);

	return (
		<PageContainer
			header={{
				title: t("fac.space.title"),
				extra: [
					facilities?.data && facilities.data.length > 0 ? (
						<Select
							key="fac-select"
							placeholder={
								t("fac.space.select_facility_placeholder") ||
								"시설을 선택하세요"
							}
							style={{ width: 220 }}
							options={facilities.data.map((f) => ({
								label: f.name,
								value: f.id,
							}))}
							onChange={(val) => {
								setSelectedFacilityId(val);
								setSelectedKey(null);
							}}
							value={selectedFacilityId}
						/>
					) : (
						<Button
							key="go-to-fac"
							type="primary"
							danger={!isTreeLoading && facilities?.data?.length === 0}
							icon={<ArrowRightOutlined />}
							onClick={() => navigate("/fac/facilities")}
						>
							{t("fac.space.go_to_facility_list") || "시설물 먼저 등록하기"}
						</Button>
					),
				],
			}}
			childrenContentStyle={{
				padding: 0,
				height: LAYOUT_CONSTANTS.CONTENT_HEIGHT,
				overflow: "hidden",
			}}
		>
			<style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; }
			`}</style>

			<Splitter
				style={{ height: "100%", background: token.colorBgContainer }}
				onResizeEnd={handleSplitterChange}
			>
				<Splitter.Panel defaultSize={initialSplitterSize} min="20%" max="50%">
					<ProCard
						title={t("fac.space.tree_title")}
						headerBordered
						extra={
							<Space size={2}>
								<Tooltip title={t("common.search")}>
									<Button
										type="text"
										icon={
											<FilterOutlined
												style={{
													color: showFilter ? token.colorPrimary : undefined,
												}}
											/>
										}
										onClick={() => setShowFilter(!showFilter)}
									/>
								</Tooltip>
								<Tooltip title={t("common.reload")}>
									<Button
										type="text"
										icon={<ReloadOutlined />}
										onClick={() =>
											queryClient.invalidateQueries({
												queryKey: ["spaces", "tree", selectedFacilityId],
											})
										}
										loading={isTreeLoading}
									/>
								</Tooltip>
								<Tooltip title={t("common.add")}>
									<Button
										type="primary"
										size="small"
										icon={<PlusOutlined />}
										onClick={() => {
											setEditingSpace(null);
											setDrawerOpen(true);
										}}
										disabled={!selectedFacilityId}
									/>
								</Tooltip>
							</Space>
						}
					>
						{selectedFacilityId ? (
							<div
								style={{
									height: "100%",
									display: "flex",
									flexDirection: "column",
								}}
							>
								{showFilter && (
									<div
										style={{
											padding: "12px",
											background: token.colorFillAlter,
											marginBottom: 12,
											borderRadius: token.borderRadiusLG,
											margin: "0 16px 8px 16px",
										}}
									>
										<Input.Search
											placeholder="공간명 검색..."
											size="small"
											allowClear
											onChange={(e) => setSearchValue(e.target.value)}
										/>
									</div>
								)}
								<div style={{ flex: 1, overflowY: "auto", padding: "0 16px" }}>
									<Tree
										showLine
										showIcon
										blockNode
										defaultExpandAll
										treeData={treeData}
										selectedKeys={selectedKey ? [selectedKey] : []}
										onSelect={(keys) => {
											if (keys.length > 0) setSelectedKey(keys[0]);
										}}
									/>
								</div>
								{selectedSpace && (
									<div
										style={{
											padding: "12px 16px",
											borderTop: `1px solid ${token.colorBorderSecondary}`,
											background: token.colorBgLayout,
										}}
									>
										<Button
											type="dashed"
											block
											icon={<PlusOutlined />}
											onClick={() => {
												// [FIX] as unknown as 제거: SpaceParams 타입 사용
												setEditingSpace({
													parent_id: selectedSpace.id,
													facility_id: selectedSpace.facility_id,
												} as SpaceParams);
												setDrawerOpen(true);
											}}
										>
											{selectedSpace.name} {t("fac.space.add_sub")}
										</Button>
									</div>
								)}
							</div>
						) : (
							<div
								style={{
									height: "100%",
									display: "flex",
									justifyContent: "center",
									alignItems: "center",
								}}
							>
								<Empty
									description={
										<Space direction="vertical" align="center">
											<span
												style={{
													fontSize: 16,
													color: token.colorTextSecondary,
												}}
											>
												{facilities?.data?.length === 0
													? "등록된 시설물이 없습니다."
													: "상단에서 시설을 먼저 선택해주세요."}
											</span>
											{facilities?.data?.length === 0 && (
												<Button
													type="primary"
													size="large"
													onClick={() => navigate("/fac/facilities")}
													style={{ marginTop: 12 }}
												>
													{t("fac.space.go_to_facility_list") ||
														"시설물 먼저 등록하기"}
												</Button>
											)}
										</Space>
									}
								/>
							</div>
						)}
					</ProCard>
				</Splitter.Panel>

				<Splitter.Panel>
					<ProCard
						title={t("fac.space.detail_title")}
						headerBordered
						extra={
							selectedSpace && (
								<Space>
									<Popconfirm
										title={t("common.delete_confirm_msg")}
										onConfirm={() => deleteMutation.mutate(selectedSpace.id)}
										okButtonProps={{ loading: deleteMutation.isPending }}
									>
										<Button danger type="text" icon={<DeleteOutlined />}>
											{t("common.delete")}
										</Button>
									</Popconfirm>
									<Button
										type="primary"
										icon={<EditOutlined />}
										onClick={() => {
											setEditingSpace(selectedSpace);
											setDrawerOpen(true);
										}}
									>
										{t("common.edit")}
									</Button>
								</Space>
							)
						}
					>
						{selectedSpace ? (
							<div style={{ padding: "24px", overflowY: "auto", flex: 1 }}>
								<div
									style={{
										display: "flex",
										alignItems: "center",
										gap: 16,
										marginBottom: 24,
									}}
								>
									<ClusterOutlined
										style={{ fontSize: 32, color: token.colorPrimary }}
									/>
									<div>
										<h3 style={{ margin: 0 }}>{selectedSpace.name}</h3>
										<code
											style={{ fontSize: 12, color: token.colorTextSecondary }}
										>
											{selectedSpace.code}
										</code>
									</div>
									<div style={{ marginLeft: "auto" }}>
										<Tag
											color={selectedSpace.is_active ? "success" : "default"}
										>
											{selectedSpace.is_active
												? t("common.active")
												: t("common.inactive")}
										</Tag>
									</div>
								</div>

								<Descriptions bordered column={2} size="small">
									<Descriptions.Item label={t("fac.space.code")}>
										{selectedSpace.code}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.name")}>
										{selectedSpace.name}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.type")}>
										{selectedSpace.space_type_code || "-"}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.function")}>
										{selectedSpace.space_func_code || "-"}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.area")}>
										{selectedSpace.area_size?.toLocaleString()} m²
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.facility.sort_order")}>
										{selectedSpace.sort_order}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.restricted")} span={2}>
										{selectedSpace.is_restricted ? (
											<Tag color="error">RESTRICTED</Tag>
										) : (
											<Tag color="processing">PUBLIC</Tag>
										)}
									</Descriptions.Item>
									<Descriptions.Item label={t("fac.space.org")} span={2}>
										{selectedSpace.org_id || t("common.none")}
									</Descriptions.Item>
									<Descriptions.Item label={t("common.description")} span={2}>
										{(selectedSpace.metadata_info?.description as string) ||
											"-"}
									</Descriptions.Item>
								</Descriptions>

								<div
									style={{
										marginTop: 24,
										padding: 16,
										background: token.colorInfoBg,
										borderRadius: 8,
										border: `1px dashed ${token.colorInfoBorder}`,
									}}
								>
									<Space align="start">
										<InfoCircleOutlined
											style={{ color: token.colorInfo, marginTop: 4 }}
										/>
										<div
											style={{ fontSize: 13, color: token.colorTextSecondary }}
										>
											{t("fac.space.hint_msg") ||
												"이 공간은 장비(EQP) 및 자산 관리의 기본 단위가 됩니다."}
										</div>
									</Space>
								</div>
							</div>
						) : (
							<Empty
								description={t("common.select_placeholder")}
								style={{ marginTop: 100 }}
							/>
						)}
					</ProCard>
				</Splitter.Panel>
			</Splitter>

			<SpaceFormDrawer
				open={drawerOpen}
				onOpenChange={setDrawerOpen}
				editingSpace={editingSpace}
				facilityName={
					facilities?.data?.find((f) => f.id === selectedFacilityId)?.name || ""
				}
				parentTreeData={treeData[0]?.children || []}
				onFinish={async (values) => {
					await saveMutation.mutateAsync(values);
					return true;
				}}
			/>
		</PageContainer>
	);
};

export default SpaceManagePage;
