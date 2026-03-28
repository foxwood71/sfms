import {
    BankOutlined,
    BuildOutlined,
    ClusterOutlined,
    DeleteOutlined,
    EditOutlined,
    FilterOutlined,
    HistoryOutlined,
    InfoCircleOutlined,
    PlusOutlined,
    ReloadOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App, Button, Empty, Popconfirm, Space, Splitter, Tabs, Tree, theme } from "antd";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
    createFacilityApi,
    createSpaceApi,
    deleteFacilityApi,
    deleteSpaceApi,
    getFacilitiesApi,
    getSpaceTreeApi,
    updateFacilityApi,
    updateSpaceApi,
} from "../api";
import AssetFormDrawer from "../components/AssetFormDrawer";
import type { Facility, FacilityParams, SpaceParams, Space as SpaceType } from "../types";

/**
 * 트리 노드 데이터 구조 정의
 */
interface AssetTreeNode {
    key: string;
    title: string;
    icon: React.ReactNode;
    type: "FAC" | "SPC";
    id: number;
    data: Facility | SpaceType;
    children?: AssetTreeNode[];
}

/**
 * 시설 및 공간 관리 페이지 (Refined Single Bento Standard)
 */
const AssetManagePage: React.FC = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();
    const { token } = theme.useToken();

    // 상태 관리
    const [selectedNode, setSelectedNode] = useState<{ type: "FAC" | "SPC"; id: number } | null>(null);
    const [activeTab, setActiveTab] = useState("info");
    const [drawerOpen, setGroupDrawerOpen] = useState(false);
    const [editingNode, setEditingNode] = useState<{ type: "FAC" | "SPC"; data: Facility | SpaceType | null } | null>(
        null,
    );

    // 트리 필터 상태
    const [showFilter, setShowFilter] = useState(false);

    // 데이터 조회
    const { data: facilities, isFetching: isFacLoading } = useQuery({
        queryKey: ["facilities"],
        queryFn: getFacilitiesApi,
    });

    const { data: spaceTree, isFetching: isSpaceLoading } = useQuery({
        queryKey: ["spaces", selectedNode?.type === "FAC" ? selectedNode.id : null],
        queryFn: () => {
            if (!selectedNode?.id) throw new Error("No node selected");
            return getSpaceTreeApi(selectedNode.id);
        },
        enabled: selectedNode?.type === "FAC",
    });

    // 뮤테이션
    const saveMutation = useMutation({
        mutationFn: async (values: FacilityParams | SpaceParams) => {
            if (editingNode?.data?.id) {
                return editingNode.type === "FAC"
                    ? await updateFacilityApi(editingNode.data.id, values as FacilityParams)
                    : await updateSpaceApi(editingNode.data.id, values as SpaceParams);
            }
            return editingNode?.type === "FAC"
                ? await createFacilityApi(values as FacilityParams)
                : await createSpaceApi(values as SpaceParams);
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setGroupDrawerOpen(false);
            queryClient.invalidateQueries({ queryKey: ["facilities"] });
            if (selectedNode?.type === "FAC") {
                queryClient.invalidateQueries({ queryKey: ["spaces", selectedNode.id] });
            }
        },
    });

    const deleteMutation = useMutation({
        mutationFn: (node: { type: "FAC" | "SPC"; id: number }) =>
            node.type === "FAC" ? deleteFacilityApi(node.id) : deleteSpaceApi(node.id),
        onSuccess: () => {
            message.success(t("common.delete_success"));
            setSelectedNode(null);
            queryClient.invalidateQueries({ queryKey: ["facilities"] });
        },
    });

    // 트리 데이터 가공
    const treeData = useMemo((): AssetTreeNode[] => {
        if (!facilities?.data) return [];
        return facilities.data.map((fac: Facility) => ({
            key: `FAC-${fac.id}`,
            title: fac.name,
            icon: <BankOutlined />,
            type: "FAC",
            id: fac.id,
            data: fac,
            children:
                selectedNode?.id === fac.id && spaceTree?.data
                    ? spaceTree.data.map((s: SpaceType) => ({
                        key: `SPC-${s.id}`,
                        title: s.name,
                        icon: <ClusterOutlined />,
                        type: "SPC",
                        id: s.id,
                        data: s,
                    }))
                    : [],
        }));
    }, [facilities, spaceTree, selectedNode]);

    return (
        <PageContainer
            header={{ title: t("fac.manage.title") }}
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
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }
                .ant-tabs-nav { margin-bottom: 0 !important; padding: 0 16px; background: ${token.colorFillAlter}; border-bottom: 1px solid ${token.colorBorderSecondary}; }
            `}</style>

            <div
                style={{
                    height: "100%",
                    background: token.colorBgContainer,
                    borderRadius: "12px",
                    border: `1px solid ${token.colorBorderSecondary}`,
                    overflow: "hidden",
                    display: "flex",
                    flexDirection: "column",
                    boxShadow: "0 4px 12px rgba(0,0,0,0.05)",
                }}
            >
                <Splitter style={{ height: "100%", background: "transparent" }}>
                    <Splitter.Panel defaultSize="30%" min="20%">
                        <ProCard
                            title={t("fac.manage.tree_title")}
                            bordered={false}
                            extra={
                                <Space size={4}>
                                    <Button
                                        type="text"
                                        size="small"
                                        icon={<FilterOutlined />}
                                        onClick={() => setShowFilter(!showFilter)}
                                    />
                                    <Button
                                        type="text"
                                        size="small"
                                        icon={<ReloadOutlined />}
                                        onClick={() => queryClient.invalidateQueries({ queryKey: ["facilities"] })}
                                        loading={isFacLoading || isSpaceLoading}
                                    />
                                    <Button
                                        type="primary"
                                        size="small"
                                        icon={<PlusOutlined />}
                                        onClick={() => {
                                            setEditingNode({ type: "FAC", data: null });
                                            setGroupDrawerOpen(true);
                                        }}
                                    >
                                        {t("common.create")}
                                    </Button>
                                </Space>
                            }
                        >
                            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                                <Tree
                                    showIcon
                                    blockNode
                                    treeData={treeData}
                                    onSelect={(_, info) => {
                                        if (info.selected) {
                                            const node = info.node as unknown as AssetTreeNode;
                                            setSelectedNode({ type: node.type, id: node.id });
                                        }
                                    }}
                                />
                            </div>
                        </ProCard>
                    </Splitter.Panel>

                    <Splitter.Panel>
                        <ProCard
                            bordered={false}
                            title={
                                selectedNode
                                    ? treeData.find((n) => n.id === selectedNode.id)?.title ||
                                      t("fac.manage.detail_title")
                                    : t("fac.manage.detail_title")
                            }
                            extra={
                                selectedNode && (
                                    <Space size={8}>
                                        <Popconfirm
                                            title={t("common.delete_confirm_msg")}
                                            onConfirm={() => deleteMutation.mutate(selectedNode)}
                                        >
                                            <Button danger type="text" size="small" icon={<DeleteOutlined />}>
                                                {t("common.delete")}
                                            </Button>
                                        </Popconfirm>
                                        <Button
                                            type="primary"
                                            size="small"
                                            icon={<EditOutlined />}
                                            onClick={() => {
                                                setEditingNode({ type: selectedNode.type, data: null });
                                                setGroupDrawerOpen(true);
                                            }}
                                        >
                                            {t("common.edit")}
                                        </Button>
                                    </Space>
                                )
                            }
                        >
                            {selectedNode ? (
                                <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                                    <Tabs
                                        activeKey={activeTab}
                                        onChange={setActiveTab}
                                        items={[
                                            {
                                                key: "info",
                                                label: (
                                                    <Space>
                                                        <InfoCircleOutlined />
                                                        {t("fac.manage.tab_info")}
                                                    </Space>
                                                ),
                                            },
                                            {
                                                key: "docs",
                                                label: (
                                                    <Space>
                                                        <BuildOutlined />
                                                        {t("fac.manage.tab_docs")}
                                                    </Space>
                                                ),
                                            },
                                            {
                                                key: "history",
                                                label: (
                                                    <Space>
                                                        <HistoryOutlined />
                                                        {t("fac.manage.tab_history")}
                                                    </Space>
                                                ),
                                            },
                                        ]}
                                    />
                                    <div style={{ flex: 1, overflowY: "auto", padding: "24px" }}>
                                        <Empty description="준비 중인 기능입니다." />
                                    </div>
                                </div>
                            ) : (
                                <div
                                    style={{
                                        height: "100%",
                                        display: "flex",
                                        alignItems: "center",
                                        justifyContent: "center",
                                        background: token.colorBgContainer,
                                    }}
                                >
                                    <Empty
                                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                                        description={t("fac.manage.select_prompt")}
                                    />
                                </div>
                            )}
                        </ProCard>
                    </Splitter.Panel>
                </Splitter>
            </div>

            <AssetFormDrawer
                open={drawerOpen}
                onOpenChange={setGroupDrawerOpen}
                editingNode={editingNode}
                onFinish={async (v) => {
                    await saveMutation.mutateAsync(v);
                    return true;
                }}
            />
        </PageContainer>
    );
};

export default AssetManagePage;
