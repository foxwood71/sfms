import { PageContainer } from "@ant-design/pro-components";
import { Splitter, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import AssetFormDrawer from "../components/AssetFormDrawer";
import type { Facility } from "../types";
import AssetDetail from "./AssetManage/components/AssetDetail";
import AssetTree from "./AssetManage/components/AssetTree";
import { useAssetManagePage } from "./AssetManage/hooks/useAssetManagePage";

/**
 * 시설 및 공간 관리 페이지 (Refined Single Bento Standard)
 */
const AssetManagePage: React.FC = () => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const logic = useAssetManagePage();

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
                        <AssetTree
                            facilities={logic.facilities}
                            spaceTree={logic.spaceTree}
                            selectedNodeId={logic.selectedNode?.id || null}
                            selectedNodeType={logic.selectedNode?.type || null}
                            isFetching={logic.isLoading}
                            onSelect={logic.setSelectedNode}
                            onAddFacility={logic.handleAddFacility}
                        />
                    </Splitter.Panel>

                    <Splitter.Panel>
                        <AssetDetail
                            selectedNode={logic.selectedNode}
                            title={
                                logic.selectedNode
                                    ? (logic.facilities.find((f: Facility) => f.id === logic.selectedNode?.id)?.name) || t("fac.manage.detail_title")
                                    : t("fac.manage.detail_title")
                            }
                            onEdit={logic.handleEditNode}
                            onDelete={logic.deleteNode}
                        />
                    </Splitter.Panel>
                </Splitter>
            </div>

            <AssetFormDrawer
                open={logic.drawerOpen}
                onOpenChange={logic.setGroupDrawerOpen}
                editingNode={logic.editingNode}
                onFinish={logic.onSaveFinish}
            />
        </PageContainer>
    );
};

export default AssetManagePage;
