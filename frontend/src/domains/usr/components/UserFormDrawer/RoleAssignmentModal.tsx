import { ExclamationCircleOutlined, SafetyOutlined } from "@ant-design/icons";
import { ModalForm } from "@ant-design/pro-components";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { message, Select, Tag, Typography, theme, Space } from "antd";
import type React from "react";
import { useState, useEffect } from "react";
import { assignUserRolesApi, getRolesApi } from "@/domains/iam/api/auth";
import type { Role } from "@/domains/iam/types";
import { MESSAGES } from "@/shared/locales/i18n-utils";

const { Text } = Typography;

interface RoleAssignmentModalProps {
    userId: number;
    userName: string;
    currentRoleIds: number[];
    open: boolean;
    onOpenChange: (open: boolean) => void;
    onSuccess: (newRoleIds: number[]) => void;
}

const RoleAssignmentModal: React.FC<RoleAssignmentModalProps> = ({
    userId,
    userName,
    currentRoleIds,
    open,
    onOpenChange,
    onSuccess,
}) => {
    const { token } = theme.useToken();
    const queryClient = useQueryClient();
    const [tempRoleIds, setTempRoleIds] = useState<number[]>([]);

    const { data: allRoles } = useQuery({
        queryKey: ["iam-roles"],
        queryFn: getRolesApi,
        enabled: open,
    });

    useEffect(() => {
        if (open) {
            setTempRoleIds(currentRoleIds);
        }
    }, [open, currentRoleIds]);

    const handleAddRole = (roleId: number) => {
        if (!tempRoleIds.includes(roleId)) {
            setTempRoleIds([...tempRoleIds, roleId]);
        }
    };

    const handleRemoveRole = (roleId: number) => {
        setTempRoleIds(tempRoleIds.filter((id) => id !== roleId));
    };

    const getRoleColor = (code: string) => {
        const upperCode = (code || "").toUpperCase();
        if (upperCode.includes("ADMIN")) return "magenta";
        if (upperCode.includes("MANAGER")) return "blue";
        if (upperCode.includes("USER")) return "green";
        if (upperCode.includes("SYS")) return "purple";
        if (upperCode.includes("DEV")) return "cyan";
        return "orange";
    };

    return (
        <ModalForm
            title={
                <Space>
                    <SafetyOutlined />
                    <span>{userName} 역할 관리</span>
                </Space>
            }
            open={open}
            onOpenChange={onOpenChange}
            width={420}
            modalProps={{ destroyOnHidden: true, centered: true, maskClosable: false }}
            onFinish={async () => {
                try {
                    await assignUserRolesApi(userId, tempRoleIds);
                    message.success(MESSAGES.USR.ROLE_UPDATE_SUCCESS);
                    onSuccess(tempRoleIds);
                    queryClient.invalidateQueries({ queryKey: ["users"] });
                    return true;
                } catch (err) {
                    message.error(MESSAGES.COMMON.SAVE_FAILURE);
                    return false;
                }
            }}
        >
            <div style={{ marginBottom: 20 }}>
                <Text type="secondary" style={{ fontSize: "12px", display: "block", marginBottom: 8 }}>
                    추가할 역할을 선택하세요
                </Text>
                <Select
                    placeholder="역할 검색 및 선택"
                    style={{ width: "100%" }}
                    onChange={handleAddRole}
                    value={null}
                    showSearch
                    optionFilterProp="label"
                    options={allRoles
                        ?.filter((r: Role) => !tempRoleIds.includes(r.id))
                        .map((r: Role) => ({ label: r.name, value: r.id }))}
                />
            </div>

            <div style={{ background: token.colorFillQuaternary, padding: "16px", borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, minHeight: "120px" }}>
                <Text strong style={{ fontSize: "13px", display: "block", marginBottom: 12 }}>
                    현재 부여된 역할 ({tempRoleIds.length})
                </Text>
                <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
                    {tempRoleIds.length > 0 ? (
                        tempRoleIds.map((id) => {
                            const role = allRoles?.find((r: Role) => r.id === id);
                            return (
                                <Tag key={id} color={getRoleColor(role?.code || role?.name || "")} closable onClose={() => handleRemoveRole(id)} style={{ padding: "4px 10px", borderRadius: "12px", border: "none" }}>
                                    {role?.name || `Role ${id}`}
                                </Tag>
                            );
                        })
                    ) : (
                        <div style={{ width: "100%", textAlign: "center", padding: "20px 0", color: token.colorTextDisabled }}>
                            <ExclamationCircleOutlined style={{ marginRight: 4 }} />
                            할당된 역할이 없습니다.
                        </div>
                    )}
                </div>
            </div>
        </ModalForm>
    );
};

export default RoleAssignmentModal;
