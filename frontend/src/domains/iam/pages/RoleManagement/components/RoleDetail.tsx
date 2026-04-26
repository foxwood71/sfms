import { Form, Input, Button, Card, Tabs, Space, theme, Popconfirm, Empty, Spin } from "antd";
import { SaveOutlined, DeleteOutlined, InfoCircleOutlined, KeyOutlined } from "@ant-design/icons";
import type { Role, PermissionResource, RoleCreate, RoleUpdate } from "../../types/role";
import PermissionEditor from "./PermissionEditor";
import React from "react";
import { useRoleDetail } from "../hooks/useRoleDetail";

interface RoleDetailProps {
  role: Role | null;
  resources: PermissionResource;
  onSave: (data: RoleCreate | RoleUpdate) => void;
  onDelete: (id: number) => void;
  loading: boolean;
  isMutating: boolean;
}

const RoleDetail: React.FC<RoleDetailProps> = ({
  role,
  resources,
  onSave,
  onDelete,
  loading,
  isMutating,
}) => {
  const { token } = theme.useToken();
  const { form, handleSubmit } = useRoleDetail({ role, onSave });

  if (loading) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100%" }}>
        <Spin size="large" tip="역할 정보를 불러오는 중..." />
      </div>
    );
  }

  if (!role && !form.getFieldValue("code") && role !== null) {
    return (
      <div style={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100%" }}>
        <Empty description="역할을 선택하거나 새로 추가해주세요." />
      </div>
    );
  }

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <DetailHeader 
        isEdit={!!role} 
        isSystem={role?.is_system} 
        onDelete={() => role && onDelete(role.id)} 
        onSave={handleSubmit} 
        isMutating={isMutating} 
        token={token} 
      />

      <div style={{ flex: 1, overflowY: "auto", padding: "24px" }}>
        <Form form={form} layout="vertical" requiredMark="optional">
          <Tabs
            defaultActiveKey="basic"
            items={[
              {
                key: "basic",
                label: <Space><InfoCircleOutlined />기본 정보</Space>,
                children: <BasicInfo role={role} />,
              },
              {
                key: "permissions",
                label: <Space><KeyOutlined />권한 설정</Space>,
                children: (
                  <Form.Item name="permissions" noStyle>
                    <PermissionEditor 
                      resources={resources} 
                      value={form.getFieldValue("permissions") || {}}
                      onChange={(val) => form.setFieldsValue({ permissions: val })}
                    />
                  </Form.Item>
                ),
              },
            ]}
          />
        </Form>
      </div>
    </div>
  );
};

/**
 * 서브 컴포넌트: 헤더 영역 (라인 수 절약을 위해 분리)
 */
const DetailHeader = ({ isEdit, isSystem, onDelete, onSave, isMutating, token }: any) => (
  <div style={{ 
    padding: "0 24px", borderBottom: `1px solid ${token.colorBorderSecondary}`,
    minHeight: "56px", display: "flex", alignItems: "center", justifyContent: "space-between",
    background: token.colorFillAlter
  }}>
    <span style={{ fontWeight: 600 }}>{isEdit ? "역할 상세 정보" : "새 역할 추가"}</span>
    <Space>
      {isEdit && !isSystem && (
        <Popconfirm title="역할 삭제" onConfirm={onDelete} okText="삭제" cancelText="취소">
          <Button danger icon={<DeleteOutlined />}>삭제</Button>
        </Popconfirm>
      )}
      <Button type="primary" icon={<SaveOutlined />} onClick={onSave} loading={isMutating}>저장</Button>
    </Space>
  </div>
);

/**
 * 서브 컴포넌트: 기본 정보 폼 항목
 */
const BasicInfo = ({ role }: { role: any }) => (
  <Card bordered={false} bodyStyle={{ padding: "12px 0" }}>
    <Form.Item name="code" label="역할 코드" rules={[{ required: true }]}>
      <Input placeholder="예: FAC_MANAGER" disabled={role?.is_system} />
    </Form.Item>
    <Form.Item name="name" label="역할 명칭" rules={[{ required: true }]}>
      <Input placeholder="예: 시설물 관리자" />
    </Form.Item>
    <Form.Item name="description" label="설명">
      <Input.TextArea rows={4} placeholder="역할 설명을 입력하세요." />
    </Form.Item>
  </Card>
);

export default RoleDetail;
