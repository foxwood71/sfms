import { PageContainer } from "@ant-design/pro-components";
import { Splitter, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import UserFormDrawer from "../components/UserFormDrawer";
import UserListTable from "./UserList/components/UserListTable";
import UserOrgTree from "./UserList/components/UserOrgTree";
import { useUserListPage } from "./UserList/hooks/useUserListPage";

/**
 * 사용자 목록 관리 페이지 (Refined Single Bento Standard)
 */
const UserListPage: React.FC = () => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const logic = useUserListPage();

    return (
        <PageContainer
            header={{ title: t("user.title") }}
            childrenContentStyle={{
                padding: "0 24px 24px 24px",
                height: "calc(100vh - 140px)",
                overflow: "hidden",
            }}
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
                    <Splitter.Panel defaultSize="25%" min="15%" max="40%">
                        <UserOrgTree
                            orgData={logic.orgData}
                            isFetching={logic.isOrgFetching}
                            selectedKey={logic.selectedKey}
                            onSelect={logic.setSelectedKey}
                            showInactive={logic.showInactiveOrg}
                            onShowInactiveChange={logic.setShowInactiveOrg}
                        />
                    </Splitter.Panel>

                    <Splitter.Panel min="50%">
                        <UserListTable
                            selectedOrgKey={logic.selectedKey}
                            onAddUser={logic.handleAddUser}
                            onViewUser={logic.handleViewUser}
                        />
                    </Splitter.Panel>
                </Splitter>
            </div>

            <UserFormDrawer
                open={logic.drawerVisible}
                onOpenChange={logic.setDrawerVisible}
                editingUser={logic.editingUser}
                initialOrgId={logic.selectedKey === "root" ? undefined : Number(logic.selectedKey)}
                onFinish={logic.onSaveFinish}
            />
        </PageContainer>
    );
};

export default UserListPage;
