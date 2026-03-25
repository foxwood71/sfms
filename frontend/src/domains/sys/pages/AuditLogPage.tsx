import {
	AuditOutlined,
	CameraOutlined,
	CloseCircleOutlined,
	FilterOutlined,
	ReloadOutlined,
} from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useQueryClient } from "@tanstack/react-query";
import {
	Button,
	Col,
	DatePicker,
	Descriptions,
	Divider,
	Input,
	Modal,
	Row,
	Select,
	Space,
	Tag,
	Tooltip,
	theme,
} from "antd";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { getAuditLogsApi } from "../api/audit";
import type { AuditLog } from "../types";
import dayjs from "dayjs";

const { RangePicker } = DatePicker;

interface AuditLogFilters {
	action_type?: string;
	target_domain?: string;
	actor_user_id?: string;
	keyword?: string;
	dateRange?: [dayjs.Dayjs, dayjs.Dayjs] | null;
}

interface FilterTag {
	key: keyof AuditLogFilters;
	label: string;
	value: string;
}

/**
 * 시스템 감사 로그 조회 페이지 (Refined Single Bento Standard)
 */
const AuditLogPage: React.FC = () => {
	const { t } = useTranslation();
	const { token } = theme.useToken();
	const queryClient = useQueryClient();

	const [pageSize, setPageSize] = useState(10);
	const [showFilter, setShowFilter] = useState(false);
	const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
	const [modalVisible, setModalVisible] = useState(false);

	const [filters, setFilters] = useState<AuditLogFilters>({});

	const getActionColor = (action: string) => {
		const upperAction = action.toUpperCase();
		if (upperAction.includes("CREATE")) return "green";
		if (upperAction.includes("UPDATE")) return "blue";
		if (upperAction.includes("DELETE")) return "red";
		if (upperAction.includes("LOGIN")) return "purple";
		if (upperAction.includes("GRANT")) return "orange";
		return "default";
	};

	const filterTags = useMemo(() => {
		const tags: FilterTag[] = [];
		if (filters.action_type) tags.push({ key: "action_type", label: t("sys.audit.action_type"), value: filters.action_type });
		if (filters.target_domain) tags.push({ key: "target_domain", label: t("sys.audit.domain"), value: filters.target_domain });
		if (filters.actor_user_id) tags.push({ key: "actor_user_id", label: t("sys.audit.actor"), value: filters.actor_user_id });
		if (filters.keyword) tags.push({ key: "keyword", label: t("common.search"), value: filters.keyword });
		if (filters.dateRange) {
			const start = filters.dateRange[0].format("YYYY-MM-DD");
			const end = filters.dateRange[1].format("YYYY-MM-DD");
			tags.push({ key: "dateRange", label: t("sys.audit.created_at"), value: `${start} ~ ${end}` });
		}
		return tags;
	}, [filters, t]);

	const removeFilter = (key: keyof AuditLogFilters) => {
		const newFilters = { ...filters };
		delete newFilters[key];
		setFilters(newFilters);
	};

	const columns: ProColumns<AuditLog>[] = [
		{ title: "ID", dataIndex: "id", width: 80 },
		{ title: t("sys.audit.action_type"), dataIndex: "action_type", width: 120, render: (val) => <Tag color={getActionColor(String(val))}>{val}</Tag> },
		{ title: t("sys.audit.domain"), dataIndex: "target_domain", width: 100 },
		{ title: t("sys.audit.actor"), dataIndex: "actor_user_id", width: 100, render: (val) => (val as string | number) || t("common.none") },
		{ title: t("sys.audit.description"), dataIndex: "description", ellipsis: true },
		{ title: t("sys.audit.client_ip"), dataIndex: "client_ip", width: 130 },
		{ title: t("sys.audit.created_at"), dataIndex: "created_at", width: 180, valueType: "dateTime" },
		{
			title: t("common.action"),
			valueType: "option",
			width: 80,
			render: (_, record) => [
				<Tooltip key="view-tip" title={t("common.detail_info")}><Button key="view" type="text" size="small" icon={<CameraOutlined />} onClick={() => { setSelectedLog(record); setModalVisible(true); }} /></Tooltip>,
			],
		},
	];

	return (
		<PageContainer
			header={{ title: t("menu.sys_audit_logs") }}
			childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
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
				${pageSize <= 10 ? '.ant-table-body { overflow-y: hidden !important; }' : '.ant-table-body { flex: 1; overflow-y: auto !important; }'}
			`}</style>

            <div style={{ 
                height: "100%", 
                background: token.colorBgContainer, 
                borderRadius: "12px", 
                border: `1px solid ${token.colorBorderSecondary}`, 
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
                boxShadow: "0 4px 12px rgba(0,0,0,0.05)"
            }}>
                <ProCard
                    bordered={false}
                    extra={
                        <Space>
                            <Tooltip title={t("common.search")}><Button type="text" size="small" icon={<FilterOutlined style={{ color: showFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowFilter(!showFilter)} /></Tooltip>
                            <Tooltip title={t("common.reload")}><Button type="text" size="small" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["audit-logs"] })} /></Tooltip>
                        </Space>
                    }
                >
                    <div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
                        {showFilter && (
                            <div style={{ padding: "16px 20px", background: token.colorBgSubtle, borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
                                <Row gutter={[16, 16]}>
                                    <Col span={6}><Space direction="vertical" style={{ width: "100%" }} size={2}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("sys.audit.created_at")}</span><RangePicker size="small" style={{ width: "100%" }} value={filters.dateRange} onChange={(val) => setFilters({ ...filters, dateRange: val })} /></Space></Col>
                                    <Col span={4}><Space direction="vertical" style={{ width: "100%" }} size={2}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("sys.audit.action_type")}</span><Select size="small" style={{ width: "100%" }} placeholder={t("common.select_placeholder")} allowClear value={filters.action_type} onChange={(val) => setFilters({ ...filters, action_type: val })} options={[{ value: "CREATE", label: "CREATE" }, { value: "UPDATE", label: "UPDATE" }, { value: "DELETE", label: "DELETE" }, { value: "LOGIN", label: "LOGIN" }, { value: "LOGIN_FAILURE", label: "LOGIN_FAILURE" }, { value: "GRANT_ROLE", label: "GRANT_ROLE" }]} /></Space></Col>
                                    <Col span={4}><Space direction="vertical" style={{ width: "100%" }} size={2}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("sys.audit.domain")}</span><Select size="small" style={{ width: "100%" }} placeholder={t("common.select_placeholder")} allowClear value={filters.target_domain} onChange={(val) => setFilters({ ...filters, target_domain: val })} options={["USR", "IAM", "FAC", "SYS", "CMM"].map(d => ({ value: d, label: d }))} /></Space></Col>
                                    <Col span={4}><Space direction="vertical" style={{ width: "100%" }} size={2}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("sys.audit.actor")}</span><Input size="small" placeholder="User ID" value={filters.actor_user_id} onChange={(e) => setFilters({ ...filters, actor_user_id: e.target.value })} /></Space></Col>
                                    <Col span={6}><Space direction="vertical" style={{ width: "100%" }} size={2}><span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("common.search")}</span><Input.Search size="small" placeholder={t("sys.audit.description")} allowClear value={filters.keyword} onChange={(e) => setFilters({ ...filters, keyword: e.target.value })} onSearch={(val) => setFilters({ ...filters, keyword: val })} /></Space></Col>
                                </Row>
                            </div>
                        )}

                        <div style={{ flex: 1, overflow: "hidden", padding: "16px" }}>
                            {filterTags.length > 0 && (
                                <div style={{ marginBottom: 12, display: "flex", alignItems: "center", flexWrap: "wrap", gap: 8 }}>
                                    <Tooltip title={t("common.active_filters")}><FilterOutlined style={{ color: token.colorTextSecondary, marginRight: 4 }} /></Tooltip>
                                    {filterTags.map(tag => (<Tag key={tag.key} closable onClose={() => removeFilter(tag.key)} style={{ borderRadius: "12px", padding: "0 10px", background: token.colorBgContainer }}><span style={{ color: token.colorTextSecondary }}>{tag.label}:</span> {tag.value}</Tag>))}
                                    <Tooltip title={t("common.clear_all")}><Button type="text" size="small" danger icon={<CloseCircleOutlined />} onClick={() => setFilters({})} /></Tooltip>
                                </div>
                            )}

                            <ProTable<AuditLog>
                                columns={columns}
                                cardBordered={false}
                                rowKey="id"
                                search={false}
                                options={{ setting: true, density: false }}
                                pagination={{ pageSize, onChange: (_, size) => setPageSize(size || 10) }}
                                scroll={{ x: "max-content", y: pageSize <= 10 ? undefined : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT }}
                                params={{ ...filters }}
                                request={async (params) => {
                                    const { current, pageSize: size, action_type, target_domain, actor_user_id, keyword, dateRange } = params;
                                    const res = await getAuditLogsApi({ page: current, size: size, action_type, target_domain, keyword, actor_user_id: actor_user_id ? Number(actor_user_id) : undefined, start_date: dateRange ? dateRange[0].startOf('day').toISOString() : undefined, end_date: dateRange ? dateRange[1].endOf('day').toISOString() : undefined });
                                    return { data: res.data.items, success: true, total: res.data.total };
                                }}
                                toolBarRender={() => [
                                    <Select key="pz" size="small" value={pageSize} onChange={setPageSize} options={[{ value: 10, label: t("user.page_size", { count: 10 }) }, { value: 20, label: t("user.page_size", { count: 20 }) }, { value: 50, label: t("user.page_size", { count: 50 }) }]} style={{ width: 80 }} />,
                                ]}
                            />
                        </div>
                    </div>
                </ProCard>
            </div>

			<Modal title={t("sys.audit.snapshot_title")} open={modalVisible} onCancel={() => setModalVisible(false)} footer={[<Button key="close" onClick={() => setModalVisible(false)}>{t("common.confirm")}</Button>]} width={800}>
				{selectedLog && (
					<div style={{ maxHeight: "600px", overflowY: "auto" }}>
						<Descriptions title={t("common.detail_info")} bordered size="small" column={2}>
							<Descriptions.Item label={t("sys.audit.action_type")}>{selectedLog.action_type}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.domain")}>{selectedLog.target_domain}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.table", "대상 테이블")}>{selectedLog.target_table}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.target_id", "대상 ID")}>{selectedLog.target_id}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.actor")}>{selectedLog.actor_user_id || "-"}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.client_ip")}>{selectedLog.client_ip}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.created_at")} span={2}>{selectedLog.created_at}</Descriptions.Item>
							<Descriptions.Item label={t("sys.audit.description")} span={2}>{selectedLog.description}</Descriptions.Item>
						</Descriptions>
						<Divider orientation="left" style={{ fontSize: "14px" }}>{t("sys.audit.snapshot_data", "데이터 스냅샷")}</Divider>
						<pre style={{ background: token.colorFillAlter, padding: "16px", borderRadius: "8px", fontSize: "12px", border: `1px solid ${token.colorBorderSecondary}` }}>{JSON.stringify(selectedLog.snapshot, null, 2)}</pre>
					</div>
				)}
			</Modal>
		</PageContainer>
	);
};

export default AuditLogPage;
