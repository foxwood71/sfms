import { Checkbox, Table, theme, Typography } from "antd";
import type { PermissionResource } from "../../types/role";
import React from "react";
import { usePermissionEditor } from "../hooks/usePermissionEditor";

const { Text } = Typography;

interface PermissionEditorProps {
  resources: PermissionResource;
  value: Record<string, string[]>;
  onChange: (value: Record<string, string[]>) => void;
  disabled?: boolean;
}

const PermissionEditor: React.FC<PermissionEditorProps> = ({
  resources,
  value,
  onChange,
  disabled,
}) => {
  const { token } = theme.useToken();
  const { isChecked, handleToggle } = usePermissionEditor({ value, onChange });

  // 테이블 컬럼 정의 (UI 구성요소)
  const columns = [
    {
      title: "업무 영역 (Domain/Resource)",
      dataIndex: "name",
      key: "name",
      width: 250,
      render: (text: string, record: any) => (
        <div style={{ display: "flex", flexDirection: "column" }}>
          <Text strong>{text}</Text>
          <Text type="secondary" style={{ fontSize: "12px" }}>{record.key}</Text>
        </div>
      ),
    },
    {
      title: "권한 설정 (Actions)",
      dataIndex: "actions",
      key: "actions",
      render: (actions: any[], record: any) => (
        <div style={{ display: "flex", flexWrap: "wrap", gap: "16px" }}>
          {actions.map((act) => (
            <Checkbox
              key={`${record.key}-${act.action}`}
              checked={isChecked(record.key, act.action)}
              onChange={() => handleToggle(record.key, act.action)}
              disabled={disabled || value["ALL"]?.includes("*")}
            >
              {act.label} <Text type="secondary" style={{ fontSize: "11px" }}>({act.action})</Text>
            </Checkbox>
          ))}
        </div>
      ),
    },
  ];

  const dataSource = Object.entries(resources).map(([key, val]) => ({
    key,
    ...val,
  }));

  return (
    <div style={{ border: `1px solid ${token.colorBorderSecondary}`, borderRadius: "8px", overflow: "hidden" }}>
      <Table
        dataSource={dataSource}
        columns={columns}
        pagination={false}
        size="middle"
        bordered={false}
        rowKey="key"
        style={{ background: token.colorBgContainer }}
      />
      {value["ALL"]?.includes("*") && (
        <div style={{ padding: "12px", background: token.colorWarningBg, borderTop: `1px solid ${token.colorWarningBorder}` }}>
          <Text type="warning" strong>슈퍼유저(ALL:*) 권한이 부여되어 모든 기능에 대한 접근이 허용됩니다.</Text>
        </div>
      )}
    </div>
  );
};

export default PermissionEditor;
