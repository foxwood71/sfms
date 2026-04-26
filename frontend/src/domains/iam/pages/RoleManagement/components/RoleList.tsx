import { List, Input, Button, Tag, Space, theme } from "antd";
import { SearchOutlined, PlusOutlined, SafetyCertificateOutlined } from "@ant-design/icons";
import type { Role } from "../../types/role";
import React from "react";

interface RoleListProps {
  roles: Role[];
  selectedRoleId: number | null;
  onSelect: (id: number) => void;
  onAdd: () => void;
  keyword: string;
  onSearch: (value: string) => void;
  loading: boolean;
}

const RoleList: React.FC<RoleListProps> = ({
  roles,
  selectedRoleId,
  onSelect,
  onAdd,
  keyword,
  onSearch,
  loading,
}) => {
  const { token } = theme.useToken();

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <div style={{ padding: "16px", borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
        <Space direction="vertical" style={{ width: "100%" }} size={12}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <span style={{ fontWeight: 600, fontSize: "16px" }}>역할 목록</span>
            <Button 
              type="primary" 
              size="small" 
              icon={<PlusOutlined />} 
              onClick={onAdd}
            >
              추가
            </Button>
          </div>
          <Input
            placeholder="역할명 또는 코드 검색"
            prefix={<SearchOutlined />}
            value={keyword}
            onChange={(e) => onSearch(e.target.value)}
            allowClear
          />
        </Space>
      </div>
      <div style={{ flex: 1, overflowY: "auto" }}>
        <List
          dataSource={roles}
          loading={loading}
          renderItem={(item) => (
            <List.Item
              onClick={() => onSelect(item.id)}
              style={{
                cursor: "pointer",
                padding: "12px 16px",
                background: selectedRoleId === item.id ? token.colorFillAlter : "transparent",
                borderLeft: selectedRoleId === item.id ? `4px solid ${token.colorPrimary}` : "4px solid transparent",
                transition: "all 0.3s",
              }}
            >
              <List.Item.Meta
                avatar={<SafetyCertificateOutlined style={{ fontSize: "20px", color: item.is_system ? token.colorWarning : token.colorPrimary }} />}
                title={
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                    <span style={{ fontWeight: selectedRoleId === item.id ? 600 : 400 }}>{item.name}</span>
                    {item.is_system && <Tag color="orange" style={{ marginRight: 0, fontSize: "10px", lineHeight: "16px" }}>SYSTEM</Tag>}
                  </div>
                }
                description={item.code}
              />
            </List.Item>
          )}
        />
      </div>
    </div>
  );
};

export default RoleList;
