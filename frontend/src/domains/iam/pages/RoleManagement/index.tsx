import { PageContainer } from "@ant-design/pro-components";
import { Splitter, theme } from "antd";
import React from "react";
import { useTranslation } from "react-i18next";
import { useRoleManagement } from "./hooks/useRoleManagement";
import RoleList from "./components/RoleList";
import RoleDetail from "./components/RoleDetail";
import type { RoleCreate, RoleUpdate } from "../../types/role";

/**
 * 역할 관리 페이지
 * Bento UI 표준 적용: 단일 카드 컨테이너, 56px 헤더, Splitter 활용
 */
const RoleManagementPage: React.FC = () => {
  const { t } = useTranslation();
  const { token } = theme.useToken();
  const logic = useRoleManagement();

  const handleSave = async (data: RoleCreate | RoleUpdate) => {
    if (logic.selectedRoleId) {
      await logic.updateRole({ id: logic.selectedRoleId, data: data as RoleUpdate });
    } else {
      const newRole = await logic.createRole(data as RoleCreate);
      if (newRole?.data?.id) {
        logic.setSelectedRoleId(newRole.data.id);
      }
    }
  };

  const handleAddRole = () => {
    logic.setSelectedRoleId(null);
  };

  return (
    <PageContainer
      header={{ title: t("menu.iam-roles") || "역할 및 권한 관리" }}
      childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
    >
      <div
        style={{
          height: "100%", background: token.colorBgContainer, borderRadius: "12px",
          border: `1px solid ${token.colorBorderSecondary}`, overflow: "hidden",
          display: "flex", flexDirection: "column", boxShadow: "0 4px 12px rgba(0,0,0,0.05)",
        }}
      >
        <Splitter style={{ height: "100%", background: "transparent" }}>
          {/* 좌측 역할 목록 */}
          <Splitter.Panel defaultSize="25%" min="15%" max="40%">
            <RoleList
              roles={logic.roles}
              selectedRoleId={logic.selectedRoleId}
              onSelect={logic.setSelectedRoleId}
              onAdd={handleAddRole}
              keyword={logic.keyword}
              onSearch={logic.setKeyword}
              loading={logic.isLoading}
            />
          </Splitter.Panel>

          {/* 우측 상세 설정 */}
          <Splitter.Panel min="50%">
            <RoleDetail
              role={logic.selectedRole}
              resources={logic.resources}
              onSave={handleSave}
              onDelete={logic.deleteRole}
              loading={logic.isDetailLoading}
              isMutating={logic.isMutating}
            />
          </Splitter.Panel>
        </Splitter>
      </div>
    </PageContainer>
  );
};

export default RoleManagementPage;
