import { DeleteOutlined, IdcardOutlined, LockOutlined, UnlockOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { Popconfirm, Tag, Tooltip, Typography } from "antd";
import type { TFunction } from "i18next";
import type { User } from "@/domains/usr/types";

interface GetUserTableColumnsProps {
    t: TFunction;
    posMap: Record<string, string>;
    dutyMap: Record<string, string>;
    onViewDetail: (record: User) => void;
    onToggleStatus: (id: number) => void;
    onDelete: (id: number) => void;
}

/**
 * 사용자 목록 테이블 컬럼 정의 생성 함수 (관심사 분리)
 */
export const getUserTableColumns = ({
    t,
    posMap,
    dutyMap,
    onViewDetail,
    onToggleStatus,
    onDelete,
}: GetUserTableColumnsProps): ProColumns<User>[] => {
    const getRoleColor = (code: string) => {
        const upperCode = (code || "").toUpperCase();
        if (upperCode.includes("ADMIN")) return "magenta";
        if (upperCode.includes("MANAGER")) return "blue";
        if (upperCode.includes("USER")) return "green";
        if (upperCode.includes("SYS")) return "purple";
        if (upperCode.includes("DEV")) return "cyan";
        return "orange";
    };

    return [
        {
            title: t("user.id"),
            dataIndex: "login_id",
            width: 120,
            ellipsis: true,
            sorter: true,
        },
        {
            title: t("user.name"),
            dataIndex: "name",
            width: 100,
            ellipsis: true,
            sorter: true,
            render: (text, record) => (
                <Typography.Link style={{ fontWeight: 500 }} onClick={() => onViewDetail(record)}>
                    {text}
                </Typography.Link>
            ),
        },
        {
            title: t("user.emp_code"),
            dataIndex: "emp_code",
            width: 100,
            ellipsis: true,
            sorter: true,
        },
        {
            title: t("user.dept"),
            dataIndex: "org_name",
            width: 140,
            ellipsis: true,
        },
        {
            title: t("iam.roles"),
            key: "roles",
            width: 160,
            render: (_, r) => (
                <div style={{ display: "flex", flexWrap: "wrap", gap: "2px" }}>
                    {r.roles?.map((role) => (
                        <Tag
                            key={role.id}
                            color={getRoleColor(role.code || role.name)}
                            style={{
                                fontSize: "10px",
                                borderRadius: "10px",
                                border: "none",
                            }}
                        >
                            {role.name}
                        </Tag>
                    )) || "-"}
                </div>
            ),
        },
        {
            title: t("user.position"),
            key: "pos",
            width: 90,
            render: (_, r) => posMap[(r.metadata?.pos as string) || ""] || (r.metadata?.pos as string) || "-",
        },
        {
            title: t("user.duty"),
            key: "duty",
            width: 90,
            render: (_, r) => dutyMap[(r.metadata?.duty as string) || ""] || (r.metadata?.duty as string) || "-",
        },
        {
            title: t("user.status"),
            dataIndex: "is_active",
            width: 80,
            render: (active) => (
                <Tag color={active ? "green" : "default"}>{active ? t("user.on_duty") : t("user.off_duty")}</Tag>
            ),
        },
        {
            title: t("sys.audit.table", "계정"), // "계정"에 해당하는 키가 마땅치 않아 audit.table 재활용하거나 임시 처리
            dataIndex: "account_status",
            width: 80,
            render: (s) => (
                <Tag color={s === "ACTIVE" ? "blue" : "error"}>
                    {s === "ACTIVE" ? t("common.active") : t("common.inactive")}
                </Tag>
            ),
        },
        {
            title: t("common.action"),
            valueType: "option",
            width: 120,
            fixed: "right",
            render: (_, record) => [
                <Tooltip key="v" title={t("common.detail_info")}>
                    <Typography.Link onClick={() => onViewDetail(record)}>
                        <IdcardOutlined />
                    </Typography.Link>
                </Tooltip>,
                <Tooltip key="l" title={t("auth.forgot_password", "계정 관리")}>
                    <Typography.Link style={{ marginLeft: 12 }} onClick={() => onToggleStatus(record.id)}>
                        {record.account_status === "ACTIVE" ? (
                            <LockOutlined style={{ color: "#faad14" }} />
                        ) : (
                            <UnlockOutlined style={{ color: "#52c41a" }} />
                        )}
                    </Typography.Link>
                </Tooltip>,
                <Popconfirm
                    key="d"
                    title={t("common.delete_confirm")}
                    description={t("common.delete_confirm_msg", "해당 사용자를 퇴직 처리하시겠습니까?")}
                    onConfirm={() => onDelete(record.id)}
                    okText={t("common.confirm")}
                    cancelText={t("common.cancel")}
                >
                    <Tooltip title={t("user.off_duty")}>
                        <Typography.Link style={{ color: "#ff4d4f", marginLeft: 12 }}>
                            <DeleteOutlined />
                        </Typography.Link>
                    </Tooltip>
                </Popconfirm>,
            ],
        },
    ];
};
