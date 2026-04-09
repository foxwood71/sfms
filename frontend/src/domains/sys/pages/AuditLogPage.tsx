import { CameraOutlined, FilterOutlined, ReloadOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { Button, Select, Space, Tag, Tooltip, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { getAuditLogsApi } from "../api/audit";
import type { AuditLog } from "../types";
import AuditLogDetailModal from "./AuditLog/components/AuditLogDetailModal";
import AuditLogFilter from "./AuditLog/components/AuditLogFilter";
import { useAuditLogPage } from "./AuditLog/hooks/useAuditLogPage";

/**
 * 시스템 감사 로그 조회 페이지 (Refined Single Bento Standard)
 */
const AuditLogPage: React.FC = () => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const logic = useAuditLogPage();

    const getActionColor = (action: string) => {
        const upperAction = action.toUpperCase();
        if (upperAction.includes("CREATE")) return "green";
        if (upperAction.includes("UPDATE")) return "blue";
        if (upperAction.includes("DELETE")) return "red";
        if (upperAction.includes("LOGIN")) return "purple";
        if (upperAction.includes("GRANT")) return "orange";
        return "default";
    };

    const columns: ProColumns<AuditLog>[] = [
        { title: "ID", dataIndex: "id", width: 80 },
        {
            title: t("sys.audit.action_type"),
            dataIndex: "action_type",
            width: 120,
            render: (val) => <Tag color={getActionColor(String(val))}>{val}</Tag>,
        },
        { title: t("sys.audit.domain"), dataIndex: "target_domain", width: 100 },
        {
            title: t("sys.audit.actor"),
            dataIndex: "actor_user_id",
            width: 100,
            render: (val) => (val as string | number) || t("common.none"),
        },
        {
            title: t("sys.audit.description"),
            dataIndex: "description",
            ellipsis: true,
        },
        { title: t("sys.audit.client_ip"), dataIndex: "client_ip", width: 130 },
        {
            title: t("sys.audit.created_at"),
            dataIndex: "created_at",
            width: 180,
            valueType: "dateTime",
        },
        {
            title: t("common.action"),
            valueType: "option",
            width: 80,
            render: (_, record) => [
                <Tooltip key="view-tip" title={t("common.detail_info")}>
                    <Button
                        key="view"
                        type="text"
                        size="small"
                        icon={<CameraOutlined />}
                        onClick={() => logic.handleViewDetail(record)}
                    />
                </Tooltip>,
            ],
        },
    ];

    return (
        <PageContainer
            header={{ title: t("menu.sys-audit-logs") }}
            childrenContentStyle={{
                padding: "0 24px 24px 24px",
                height: "calc(100vh - 140px)",
                overflow: "hidden",
            }}
        >
            <style>{`
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; padding: 0 !important; }
                .ant-pro-card-header {
                    padding: 0 20px !important;
                    background: ${token.colorFillAlter} !important;
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    min-height: 56px !important;
                }
                .ant-pro-card-title { font-weight: 600 !important; }
				.ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
				${logic.pageSize <= 10 ? ".ant-table-body { overflow-y: hidden !important; }" : ".ant-table-body { flex: 1; overflow-y: auto !important; }"}
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
                <ProCard
                    bordered={false}
                    extra={
                        <Space>
                            <Tooltip title={t("common.search")}>
                                <Button
                                    type="text"
                                    size="small"
                                    icon={
                                        <FilterOutlined
                                            style={{
                                                color: logic.showFilter ? token.colorPrimary : undefined,
                                            }}
                                        />
                                    }
                                    onClick={() => logic.setShowFilter(!logic.showFilter)}
                                />
                            </Tooltip>
                            <Tooltip title={t("common.reload")}>
                                <Button
                                    type="text"
                                    size="small"
                                    icon={<ReloadOutlined />}
                                    onClick={logic.handleReload}
                                />
                            </Tooltip>
                        </Space>
                    }
                >
                    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                        <AuditLogFilter
                            filters={logic.filters}
                            onFilterChange={logic.setFilters}
                            showFilter={logic.showFilter}
                        />

                        <div style={{ flex: 1, overflow: "hidden", padding: "16px" }}>
                            <ProTable<AuditLog>
                                columns={columns}
                                cardBordered={false}
                                rowKey="id"
                                search={false}
                                options={{ setting: true, density: false }}
                                pagination={{
                                    pageSize: logic.pageSize,
                                    onChange: (_, size) => logic.setPageSize(size || 10),
                                }}
                                scroll={{
                                    x: "max-content",
                                    y: logic.pageSize <= 10 ? undefined : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT,
                                }}
                                params={{ ...logic.filters }}
                                request={async (params) => {
                                    const { current, pageSize: size, action_type, target_domain, actor_user_id, keyword, dateRange } = params;
                                    const res = await getAuditLogsApi({
                                        page: current,
                                        size: size,
                                        action_type,
                                        target_domain,
                                        keyword,
                                        actor_user_id: actor_user_id ? Number(actor_user_id) : undefined,
                                        start_date: dateRange?.[0]?.startOf("day").toISOString(),
                                        end_date: dateRange?.[1]?.endOf("day").toISOString(),
                                    });
                                    return { data: res.data.items, success: true, total: res.data.total };
                                }}
                                toolBarRender={() => [
                                    <Select
                                        key="pz"
                                        size="small"
                                        value={logic.pageSize}
                                        onChange={logic.setPageSize}
                                        options={[
                                            { value: 10, label: t("user.page_size", { count: 10 }) },
                                            { value: 20, label: t("user.page_size", { count: 20 }) },
                                            { value: 50, label: t("user.page_size", { count: 50 }) },
                                        ]}
                                        style={{ width: 80 }}
                                    />,
                                ]}
                            />
                        </div>
                    </div>
                </ProCard>
            </div>

            <AuditLogDetailModal
                open={logic.modalVisible}
                onClose={() => logic.setModalVisible(false)}
                log={logic.selectedLog}
            />
        </PageContainer>
    );
};

export default AuditLogPage;
