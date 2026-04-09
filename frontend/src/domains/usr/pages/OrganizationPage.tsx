import { PartitionOutlined, PlusOutlined, TeamOutlined } from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { Button, Space, Splitter, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { getStandardTableStyle } from "@/shared/constants/layout";
import UserFormDrawer from "../components/UserFormDrawer";
import OrgFormDrawer from "./Organization/components/OrgFormDrawer";
import OrgTable from "./Organization/components/OrgTable";
import OrgTree from "./Organization/components/OrgTree";
import UserTable from "./Organization/components/UserTable";
import { useOrganizationPage } from "./Organization/hooks/useOrganizationPage";

/**
 * 조직 및 사용자 통합 관리 페이지 (Integrated Workspace)
 * [좌측 트리 - 우측 하위부서/사용자 테이블] 구조로 일관성 확보
 */
const OrganizationPage: React.FC = () => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const logic = useOrganizationPage();

    return (
        <PageContainer
            header={{ title: t("menu.usr") }}
            childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
        >
            <style>{`
                ${getStandardTableStyle(token)}
				.ant-pro-card { height: 100% !important; display: flex !important; flex-direction: column !important; }
				.ant-pro-card-body { flex: 1 !important; display: flex !important; flex-direction: column !important; padding: 0 !important; overflow: hidden !important; }
                .ant-pro-card-header {
                    padding: 0 20px !important;
                    background: ${token.colorFillAlter} !important;
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    min-height: 56px !important;
                }
                .ant-pro-card-title { font-weight: 600 !important; }
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }

                /* 풍선 형태의 Bulk Action Bar 스타일 */
                .bulk-action-balloon {
                    position: absolute;
                    bottom: 30px;
                    left: 50%;
                    transform: translateX(-50%);
                    background: ${token.colorBgElevated};
                    padding: 8px 24px;
                    border-radius: 50px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.15);
                    border: 1px solid ${token.colorBorderSecondary};
                    display: flex;
                    align-items: center;
                    gap: 16px;
                    z-index: 1000;
                    animation: slideUp 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
                }
                @keyframes slideUp {
                    from { opacity: 0; transform: translate(-50%, 30px); }
                    to { opacity: 1; transform: translate(-50%, 0); }
                }
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
                    {/* 좌측 네비게이터 */}
                    <Splitter.Panel defaultSize="25%" min="15%" max="40%">
                        <OrgTree
                            orgData={logic.orgData}
                            isFetching={logic.isOrgFetching}
                            selectedKey={logic.selectedKey}
                            onSelect={logic.setSelectedKey}
                            showInactive={logic.showInactiveOrg}
                            onShowInactiveChange={logic.setShowInactiveOrg}
                        />
                    </Splitter.Panel>

                    {/* 우측 워크스페이스 */}
                    <Splitter.Panel min="50%">
                        <ProCard
                            tabs={{
                                activeKey: logic.activeTab,
                                onChange: logic.setActiveTab,
                                items: [
                                    {
                                        key: "suborgs",
                                        label: (
                                            <Space>
                                                <PartitionOutlined />
                                                {t("org.title")}
                                            </Space>
                                        ),
                                        children: (
                                            <OrgTable
                                                dataSource={logic.subOrgData}
                                                onSelectOrg={logic.setSelectedKey}
                                                onEditOrg={logic.handleEditOrg}
                                            />
                                        ),
                                    },
                                    {
                                        key: "users",
                                        label: (
                                            <Space>
                                                <TeamOutlined />
                                                {t("user.list_title")}
                                            </Space>
                                        ),
                                        children: (
                                            <UserTable
                                                orgId={logic.selectedKey === "root" ? undefined : Number(logic.selectedKey)}
                                                onViewUser={logic.handleViewUser}
                                            />
                                        ),
                                    },
                                ],
                            }}
                            extra={
                                <Space>
                                    <Button
                                        type="primary"
                                        size="small"
                                        icon={<PlusOutlined />}
                                        onClick={logic.activeTab === "suborgs" ? logic.handleAddOrg : logic.handleAddUser}
                                    >
                                        {t("common.create")}
                                    </Button>
                                </Space>
                            }
                        />
                    </Splitter.Panel>
                </Splitter>
            </div>

            <OrgFormDrawer
                open={logic.orgDrawerOpen}
                onOpenChange={logic.setOrgDrawerOpen}
                isAdding={logic.isOrgAdding}
                editingOrg={logic.editingOrg}
                initialParentId={logic.selectedKey === "root" ? null : String(logic.selectedKey)}
            />

            <UserFormDrawer
                open={logic.userDrawerOpen}
                onOpenChange={logic.setUserDrawerOpen}
                editingUser={logic.editingUser}
                initialOrgId={logic.selectedKey === "root" ? undefined : Number(logic.selectedKey)}
                onFinish={async () => {
                    await logic.invalidateUsers();
                    return true;
                }}
            />
        </PageContainer>
    );
};

export default OrganizationPage;
