import { ArrowRightOutlined } from "@ant-design/icons";
import { PageContainer } from "@ant-design/pro-components";
import { Button, Select, Splitter, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import SpaceFormDrawer from "../components/SpaceFormDrawer";
import SpaceDetail from "./SpaceManage/components/SpaceDetail";
import SpaceTree from "./SpaceManage/components/SpaceTree";
import { useSpaceManage } from "./SpaceManage/hooks/useSpaceManage";

/**
 * 공간 계층 관리 페이지 (Bento Standard v1.1)
 */
const SpaceManagePage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { token } = theme.useToken();
    const logic = useSpaceManage();

    const rootTitle = logic.facilities.find((f) => f.id === logic.selectedFacilityId)?.name || t("fac.space.tree_title");

    return (
        <PageContainer
            header={{
                title: t("fac.space.title"),
                extra: [
                    logic.facilities.length > 0 ? (
                        <Select
                            key="fac-select"
                            placeholder={t("fac.space.select_facility_placeholder") || "시설을 선택하세요"}
                            style={{ width: 220 }}
                            options={logic.facilities.map((f) => ({ label: f.name, value: f.id }))}
                            onChange={(val) => {
                                logic.setSelectedFacilityId(val);
                                logic.setSelectedKey(null);
                            }}
                            value={logic.selectedFacilityId}
                        />
                    ) : (
                        <Button
                            key="go-to-fac"
                            type="primary"
                            danger={!logic.isTreeLoading && logic.facilities.length === 0}
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
                onResizeEnd={logic.handleSplitterChange}
            >
                <Splitter.Panel defaultSize={logic.initialSplitterSize} min="20%" max="50%">
                    <SpaceTree
                        facilityId={logic.selectedFacilityId}
                        rootTitle={rootTitle}
                        spaceData={logic.spaceTree}
                        isFetching={logic.isTreeLoading}
                        selectedKey={logic.selectedKey}
                        onSelect={logic.setSelectedKey}
                        onAddSpace={logic.handleAddSpace}
                        onAddSubSpace={logic.handleAddSubSpace}
                    />
                </Splitter.Panel>

                <Splitter.Panel>
                    <SpaceDetail
                        selectedSpace={logic.selectedSpace}
                        onEdit={logic.handleEditSpace}
                        onDelete={logic.deleteSpace}
                        isDeleting={logic.isDeleting}
                    />
                </Splitter.Panel>
            </Splitter>

            <SpaceFormDrawer
                open={logic.drawerOpen}
                onOpenChange={logic.setDrawerOpen}
                editingSpace={logic.editingSpace}
                facilityName={logic.facilities.find((f) => f.id === logic.selectedFacilityId)?.name || ""}
                parentTreeData={logic.spaceTree}
                onFinish={logic.onSaveFinish}
            />
        </PageContainer>
    );
};

export default SpaceManagePage;
