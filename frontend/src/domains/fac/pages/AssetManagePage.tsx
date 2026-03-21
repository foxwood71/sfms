import {
	ApartmentOutlined,
	BuildOutlined,
	ClusterOutlined,
	DeleteOutlined,
	EditOutlined,
	FilterOutlined,
	InfoCircleOutlined,
	PlusOutlined,
	ReloadOutlined,
	SaveOutlined,
	FolderOpenOutlined,
	HistoryOutlined,
	ArrowRightOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Descriptions,
	Empty,
	Input,
	Popconfirm,
	Space,
	Splitter,
	Tabs,
	Tag,
	Tooltip,
	Tree,
	theme,
} from "antd";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { 
    getFacilitiesApi, 
    getSpaceTreeApi, 
    deleteFacilityApi, 
    deleteSpaceApi,
    createFacilityApi,
    updateFacilityApi,
    createSpaceApi,
    updateSpaceApi
} from "../api";
import type { Facility, Space as SpaceType } from "../types";
import AssetFormDrawer from "../components/AssetFormDrawer";

/**
 * 시설 및 공간 통합 관리 페이지 (Bento Standard v1.1)
 */
const AssetManagePage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	// 상태 관리
	const [selectedKey, setSelectedKey] = useState<string | null>(null);
	const [searchValue, setSearchValue] = useState("");
	const [activeTab, setActiveTab] = useState("info");

	// 드로어 상태
	const [drawerOpen, setDrawerOpen] = useState(false);
	const [editingNode, setEditingNode] = useState<{ type: "FAC" | "SPC", data: any } | null>(null);

	// 1. 데이터 로딩
	const { data: facilities, isFetching: isFacLoading } = useQuery({
		queryKey: ["facilities"],
		queryFn: getFacilitiesApi,
	});

    const selectedFacId = selectedKey?.startsWith("FAC_") ? Number(selectedKey.split("_")[1]) : null;
    const selectedSpcId = selectedKey?.startsWith("SPC_") ? Number(selectedKey.split("_")[1]) : null;

    const { data: spaceTree, isFetching: isSpcLoading } = useQuery({
        queryKey: ["spaces", "tree", selectedFacId || "all"],
        queryFn: async () => {
            if (selectedFacId) return getSpaceTreeApi(selectedFacId);
            return { data: [] };
        },
        enabled: !!selectedFacId || !!selectedSpcId,
    });

	// 2. 통합 트리 조립
	const treeData = useMemo(() => {
		const rootNode = {
			key: "ROOT",
			title: t("common.company_name") || "SFMS 전체",
			icon: <ApartmentOutlined />,
			children: facilities?.data?.map(f => ({
				key: `FAC_${f.id}`,
				title: f.name,
				icon: <BuildOutlined style={{ color: token.colorPrimary }} />,
                isLeaf: false,
                children: selectedFacId === f.id ? (spaceTree?.data || []).map(function mapSpc(s: any): any {
                    return {
                        key: `SPC_${s.id}`,
                        title: s.name,
                        icon: <ClusterOutlined />,
                        children: s.children?.map(mapSpc)
                    };
                }) : []
			})) || []
		};
		return [rootNode];
	}, [facilities, spaceTree, selectedFacId, token, t]);

    // 3. 선택된 노드 상세 정보 추출
    const selectedInfo = useMemo(() => {
        if (!selectedKey) return null;
        if (selectedKey.startsWith("FAC_")) {
            const id = Number(selectedKey.split("_")[1]);
            const fac = facilities?.data?.find(f => f.id === id);
            return fac ? { type: "FAC" as const, data: fac } : null;
        }
        if (selectedKey.startsWith("SPC_")) {
            const id = Number(selectedKey.split("_")[1]);
            const findInTree = (items: any[]): any => {
                for (const item of items) {
                    if (item.id === id) return item;
                    if (item.children) {
                        const found = findInTree(item.children);
                        if (found) return found;
                    }
                }
                return null;
            };
            const spc = findInTree(spaceTree?.data || []);
            return spc ? { type: "SPC" as const, data: spc } : null;
        }
        return null;
    }, [selectedKey, facilities, spaceTree]);

	// 4. 저장/삭제 Mutation
	const saveMutation = useMutation({
		mutationFn: async (values: any) => {
			if (editingNode?.data?.id) {
				return editingNode.type === "FAC" 
                    ? updateFacilityApi(editingNode.data.id, values) 
                    : updateSpaceApi(editingNode.data.id, values);
			}
            return editingNode?.type === "FAC"
                ? createFacilityApi(values)
                : createSpaceApi(values);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setDrawerOpen(false);
			queryClient.invalidateQueries({ queryKey: ["facilities"] });
			queryClient.invalidateQueries({ queryKey: ["spaces"] });
		},
	});

	return (
		<PageContainer
			header={{ title: t("fac.manage.title") }}
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; padding: 0 !important; }
                
                /* 헤더 높이 및 정렬 강제 규격화 */
                .ant-pro-card-header { 
                    height: ${LAYOUT_CONSTANTS.HEADER_HEIGHT}px !important; 
                    min-height: ${LAYOUT_CONSTANTS.HEADER_HEIGHT}px !important; 
                    max-height: ${LAYOUT_CONSTANTS.HEADER_HEIGHT}px !important;
                    padding: 0 16px !important;
                    display: flex !important;
                    align-items: center !important;
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    box-sizing: border-box !important;
                }
                .ant-pro-card-title { 
                    line-height: 1 !important; 
                    display: flex !important; 
                    align-items: center !important; 
                    height: 100% !important;
                    font-size: 14px !important;
                }
                .ant-pro-card-extra { 
                    margin: 0 !important; 
                    display: flex !important; 
                    align-items: center !important; 
                    height: 100% !important;
                }

                .ant-tabs-content { height: 100%; }
                .ant-tabs-tabpane { height: 100%; display: flex; flex-direction: column; }
                .full-height-tabs .ant-tabs-nav { 
                    padding-left: 16px; 
                    margin-bottom: 0; 
                    background: ${token.colorBgContainer}; 
                    border-bottom: 1px solid ${token.colorBorderSecondary};
                    min-height: 46px;
                    display: flex;
                    align-items: center;
                }
			`}</style>

			<Splitter style={{ height: "100%", background: token.colorBgContainer }}>
				{/* 왼쪽: 통합 트리 패널 */}
				<Splitter.Panel defaultSize="30%" min="20%" max="45%" style={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
					<ProCard
						title={t("fac.space.tree_title")}
						headerBordered
						extra={
							<Space size={2}>
								<Tooltip title={t("common.reload")}>
									<Button
										type="text"
										icon={<ReloadOutlined />}
										onClick={() => queryClient.invalidateQueries()}
										loading={isFacLoading || isSpcLoading}
									/>
								</Tooltip>
								<Tooltip title={t("common.add")}>
									<Button
										type="primary"
										size="small"
										icon={<PlusOutlined />}
										onClick={() => {
                                            if (!selectedKey || selectedKey === "ROOT") {
                                                setEditingNode({ type: "FAC", data: {} });
                                            } else {
                                                setEditingNode({ type: "SPC", data: { 
                                                    facility_id: selectedFacId || selectedInfo?.data?.facility_id,
                                                    parent_id: selectedSpcId 
                                                }});
                                            }
											setDrawerOpen(true);
										}}
									/>
								</Tooltip>
							</Space>
						}
					>
						<div style={{ flex: 1, overflowY: "auto", padding: "12px 16px" }}>
							<Tree
								showLine
								showIcon
								blockNode
								defaultExpandAll
								treeData={treeData}
								selectedKeys={selectedKey ? [selectedKey] : []}
								onSelect={(keys) => {
									if (keys.length > 0) setSelectedKey(keys[0] as string);
								}}
							/>
						</div>
					</ProCard>
				</Splitter.Panel>

				{/* 오른쪽: 상세 정보 및 탭 패널 */}
				<Splitter.Panel style={{ display: "flex", flexDirection: "column", overflow: "hidden" }}>
					<ProCard
						title={selectedInfo ? (
                            <Space align="center" size={8}>
                                {selectedInfo.type === "FAC" ? <BuildOutlined style={{ color: token.colorPrimary }} /> : <ClusterOutlined style={{ color: token.colorPrimary }} />}
                                <span style={{ fontWeight: 600 }}>{selectedInfo.data.name}</span>
                                <Tag color="blue" bordered={false} style={{ fontSize: '10px', lineHeight: '16px', margin: 0 }}>{selectedInfo.type}</Tag>
                            </Space>
                        ) : t("fac.facility.detail_title")}
						headerBordered
						extra={selectedInfo && (
							<Space>
								<Button 
                                    size="small"
                                    icon={<EditOutlined />} 
                                    onClick={() => {
                                        setEditingNode(selectedInfo);
                                        setDrawerOpen(true);
                                    }}
                                >
                                    {t("common.edit")}
                                </Button>
                                <Popconfirm
                                    title={t("common.delete_confirm")}
                                    onConfirm={async () => {
                                        try {
                                            if (selectedInfo.type === "FAC") {
                                                await deleteFacilityApi(selectedInfo.data.id);
                                            } else {
                                                await deleteSpaceApi(selectedInfo.data.id);
                                            }
                                            message.success(t("common.delete_success"));
                                            setSelectedKey(null);
                                            queryClient.invalidateQueries({ queryKey: ["facilities"] });
                                            queryClient.invalidateQueries({ queryKey: ["spaces"] });
                                        } catch (error) {}
                                    }}
                                    okText={t("common.yes")}
                                    cancelText={t("common.no")}
                                >
                                    <Button size="small" icon={<DeleteOutlined />} danger>
                                        {t("common.delete")}
                                    </Button>
                                </Popconfirm>
							</Space>
						)}
					>
						{selectedInfo ? (
							<Tabs
								activeKey={activeTab}
								onChange={setActiveTab}
								style={{ height: "100%" }}
                                className="full-height-tabs"
								items={[
									{
										key: "info",
										label: <Space><InfoCircleOutlined />{t("common.info")}</Space>,
										children: (
											<div style={{ padding: 24, overflowY: "auto", flex: 1 }}>
												<Descriptions bordered column={2} size="small">
													<Descriptions.Item label={t("common.code")}>{selectedInfo.data.code}</Descriptions.Item>
													<Descriptions.Item label={t("common.name")}>{selectedInfo.data.name}</Descriptions.Item>
                                                    {selectedInfo.type === "FAC" ? (
                                                        <Descriptions.Item label={t("fac.facility.address")} span={2}>{selectedInfo.data.address || "-"}</Descriptions.Item>
                                                    ) : (
                                                        <Descriptions.Item label={t("fac.space.area")}>{selectedInfo.data.area_size} ㎡</Descriptions.Item>
                                                    )}
													<Descriptions.Item label={t("common.status")}>
														<Tag color={selectedInfo.data.is_active ? "success" : "default"}>
                                                            {selectedInfo.data.is_active ? t("common.active") : t("common.inactive")}
                                                        </Tag>
													</Descriptions.Item>
												</Descriptions>
											</div>
										)
									},
									{
										key: "docs",
										label: <Space><FolderOpenOutlined />{t("fac.history.doc_tab")}</Space>,
										children: (
											<div style={{ padding: 16, overflowY: "auto", flex: 1 }}>
												<ProTable
													search={false}
													toolBarRender={() => [
														<Button key="upload" type="primary" size="small" icon={<PlusOutlined />}>{t("common.upload") || "자료 업로드"}</Button>
													]}
													columns={[
														{ title: t("fac.history.file_name"), dataIndex: "name" },
														{ title: t("fac.history.file_type"), dataIndex: "type", width: 100 },
														{ title: t("fac.history.upload_date"), dataIndex: "date", width: 150 },
													]}
													dataSource={[]}
												/>
											</div>
										)
									},
									{
										key: "history",
										label: <Space><HistoryOutlined />{t("fac.history.history_tab")}</Space>,
										children: (
											<div style={{ padding: 16, overflowY: "auto", flex: 1 }}>
												<ProTable
													search={false}
                                                    toolBarRender={false}
													columns={[
														{ title: t("sys.audit.created_at"), dataIndex: "at", width: 180 },
														{ title: t("sys.audit.actor"), dataIndex: "actor", width: 120 },
														{ title: t("sys.audit.description"), dataIndex: "desc" },
													]}
													dataSource={[]}
												/>
											</div>
										)
									}
								]}
							/>
						) : (
							<Empty description={t("common.select_placeholder")} style={{ marginTop: 200 }} />
						)}
					</ProCard>
				</Splitter.Panel>
			</Splitter>

			<AssetFormDrawer
				open={drawerOpen}
				onOpenChange={setDrawerOpen}
				editingNode={editingNode}
				onFinish={async (values) => {
					await saveMutation.mutateAsync(values);
					return true;
				}}
			/>
		</PageContainer>
	);
};

export default AssetManagePage;
