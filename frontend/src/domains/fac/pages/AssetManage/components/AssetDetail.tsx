import {
    BuildOutlined,
    DeleteOutlined,
    EditOutlined,
    HistoryOutlined,
    InfoCircleOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { Button, Empty, Popconfirm, Space, Tabs, theme } from "antd";
import type React from "react";
import { useState } from "react";
import { useTranslation } from "react-i18next";

interface AssetDetailProps {
    selectedNode: { type: "FAC" | "SPC"; id: number } | null;
    title: string;
    onEdit: () => void;
    onDelete: (node: { type: "FAC" | "SPC"; id: number }) => void;
}

const AssetDetail: React.FC<AssetDetailProps> = ({
    selectedNode,
    title,
    onEdit,
    onDelete,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [activeTab, setActiveTab] = useState("info");

    return (
        <ProCard
            bordered={false}
            title={title}
            extra={
                selectedNode && (
                    <Space size={8}>
                        <Popconfirm
                            title={t("common.delete_confirm_msg")}
                            onConfirm={() => onDelete(selectedNode)}
                        >
                            <Button danger type="text" size="small" icon={<DeleteOutlined />}>
                                {t("common.delete")}
                            </Button>
                        </Popconfirm>
                        <Button
                            type="primary"
                            size="small"
                            icon={<EditOutlined />}
                            onClick={onEdit}
                        >
                            {t("common.edit")}
                        </Button>
                    </Space>
                )
            }
        >
            {selectedNode ? (
                <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                    <Tabs
                        activeKey={activeTab}
                        onChange={setActiveTab}
                        items={[
                            {
                                key: "info",
                                label: (
                                    <Space>
                                        <InfoCircleOutlined />
                                        {t("fac.manage.tab_info")}
                                    </Space>
                                ),
                            },
                            {
                                key: "docs",
                                label: (
                                    <Space>
                                        <BuildOutlined />
                                        {t("fac.manage.tab_docs")}
                                    </Space>
                                ),
                            },
                            {
                                key: "history",
                                label: (
                                    <Space>
                                        <HistoryOutlined />
                                        {t("fac.manage.tab_history")}
                                    </Space>
                                ),
                            },
                        ]}
                    />
                    <div style={{ flex: 1, overflowY: "auto", padding: "24px" }}>
                        <Empty description="준비 중인 기능입니다." />
                    </div>
                </div>
            ) : (
                <div
                    style={{
                        height: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        background: token.colorBgContainer,
                    }}
                >
                    <Empty
                        image={Empty.PRESENTED_IMAGE_SIMPLE}
                        description={t("fac.manage.select_prompt")}
                    />
                </div>
            )}
        </ProCard>
    );
};

export default AssetDetail;
