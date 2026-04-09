import { PageContainer } from "@ant-design/pro-components";
import { Splitter, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { getStandardTableStyle } from "@/shared/constants/layout";
import CodeDetailDrawer from "../components/CodeDetailDrawer";
import CodeGroupDrawer from "../components/CodeGroupDrawer";
import CodeDetailTable from "./CodeManage/components/CodeDetailTable";
import CodeGroupTree from "./CodeManage/components/CodeGroupTree";
import { useCodeManagePage } from "./CodeManage/hooks/useCodeManagePage";

/**
 * 공통 코드 관리 페이지 (Refined Bento Standard - Final Tree Navigator)
 */
const CodeManagePage: React.FC = () => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const logic = useCodeManagePage();

    return (
        <PageContainer
            header={{ title: t("cmm.code.title") }}
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
                        <CodeGroupTree
                            groups={logic.groups}
                            isLoading={logic.isGroupsLoading}
                            selectedGroupCode={logic.selectedGroup?.group_code}
                            onSelectGroup={logic.setSelectedGroup}
                            onAddGroup={logic.handleAddGroup}
                        />
                    </Splitter.Panel>

                    <Splitter.Panel>
                        <CodeDetailTable
                            selectedGroup={logic.selectedGroup}
                            onEditGroup={logic.handleEditGroup}
                            onAddDetail={logic.handleAddDetail}
                            onEditDetail={logic.handleEditDetail}
                        />
                    </Splitter.Panel>
                </Splitter>
            </div>

            <CodeGroupDrawer
                open={logic.groupDrawerOpen}
                onOpenChange={logic.setGroupDrawerOpen}
                editingGroup={logic.editingGroup}
                onFinish={logic.invalidateGroups}
            />
            <CodeDetailDrawer
                open={logic.detailDrawerOpen}
                onOpenChange={logic.setDetailDrawerOpen}
                editingDetail={logic.editingDetail}
                groupName={logic.selectedGroup?.group_name || ""}
                onFinish={logic.onDetailSaveFinish}
            />
        </PageContainer>
    );
};

export default CodeManagePage;
