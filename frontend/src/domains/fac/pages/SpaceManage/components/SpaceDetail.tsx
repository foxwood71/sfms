import {
    ClusterOutlined,
    DeleteOutlined,
    EditOutlined,
    InfoCircleOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { Button, Descriptions, Empty, Popconfirm, Space, Tag, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import type { Space as SpaceType } from "@/domains/fac/types";

interface SpaceDetailProps {
    selectedSpace: SpaceType | null;
    onEdit: (space: SpaceType) => void;
    onDelete: (id: number) => void;
    isDeleting: boolean;
}

const SpaceDetail: React.FC<SpaceDetailProps> = ({
    selectedSpace,
    onEdit,
    onDelete,
    isDeleting,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();

    return (
        <ProCard
            title={t("fac.space.detail_title")}
            headerBordered
            extra={
                selectedSpace && (
                    <Space>
                        <Popconfirm
                            title={t("common.delete_confirm_msg")}
                            onConfirm={() => onDelete(selectedSpace.id)}
                            okButtonProps={{ loading: isDeleting }}
                        >
                            <Button danger type="text" icon={<DeleteOutlined />}>
                                {t("common.delete")}
                            </Button>
                        </Popconfirm>
                        <Button
                            type="primary"
                            icon={<EditOutlined />}
                            onClick={() => onEdit(selectedSpace)}
                        >
                            {t("common.edit")}
                        </Button>
                    </Space>
                )
            }
        >
            {selectedSpace ? (
                <div style={{ padding: "24px", overflowY: "auto", flex: 1 }}>
                    <div
                        style={{
                            display: "flex",
                            alignItems: "center",
                            gap: 16,
                            marginBottom: 24,
                        }}
                    >
                        <ClusterOutlined
                            style={{ fontSize: 32, color: token.colorPrimary }}
                        />
                        <div>
                            <h3 style={{ margin: 0 }}>{selectedSpace.name}</h3>
                            <code
                                style={{ fontSize: 12, color: token.colorTextSecondary }}
                            >
                                {selectedSpace.code}
                            </code>
                        </div>
                        <div style={{ marginLeft: "auto" }}>
                            <Tag
                                color={selectedSpace.is_active ? "success" : "default"}
                            >
                                {selectedSpace.is_active
                                    ? t("common.active")
                                    : t("common.inactive")}
                            </Tag>
                        </div>
                    </div>

                    <Descriptions bordered column={2} size="small">
                        <Descriptions.Item label={t("fac.space.code")}>
                            {selectedSpace.code}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.name")}>
                            {selectedSpace.name}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.type")}>
                            {selectedSpace.space_type_code || "-"}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.function")}>
                            {selectedSpace.space_func_code || "-"}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.area")}>
                            {selectedSpace.area_size?.toLocaleString()} m²
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.facility.sort_order")}>
                            {selectedSpace.sort_order}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.restricted")} span={2}>
                            {selectedSpace.is_restricted ? (
                                <Tag color="error">RESTRICTED</Tag>
                            ) : (
                                <Tag color="processing">PUBLIC</Tag>
                            )}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("fac.space.org")} span={2}>
                            {selectedSpace.org_id || t("common.none")}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("common.description")} span={2}>
                            {(selectedSpace.metadata_info?.description as string) ||
                                "-"}
                        </Descriptions.Item>
                    </Descriptions>

                    <div
                        style={{
                            marginTop: 24,
                            padding: 16,
                            background: token.colorInfoBg,
                            borderRadius: 8,
                            border: `1px dashed ${token.colorInfoBorder}`,
                        }}
                    >
                        <Space align="start">
                            <InfoCircleOutlined
                                style={{ color: token.colorInfo, marginTop: 4 }}
                            />
                            <div
                                style={{ fontSize: 13, color: token.colorTextSecondary }}
                            >
                                {t("fac.space.hint_msg") ||
                                    "이 공간은 장비(EQP) 및 자산 관리의 기본 단위가 됩니다."}
                            </div>
                        </Space>
                    </div>
                </div>
            ) : (
                <Empty
                    description={t("common.select_placeholder")}
                    style={{ marginTop: 100 }}
                />
            )}
        </ProCard>
    );
};

export default SpaceDetail;
