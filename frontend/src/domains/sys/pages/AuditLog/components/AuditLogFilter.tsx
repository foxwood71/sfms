import { CloseCircleOutlined, FilterOutlined } from "@ant-design/icons";
import { Button, Col, DatePicker, Input, Row, Select, Space, Tag, Tooltip, theme } from "antd";
import type dayjs from "dayjs";
import type React from "react";
import { useMemo } from "react";
import { useTranslation } from "react-i18next";

const { RangePicker } = DatePicker;

export interface AuditLogFilters {
    action_type?: string;
    target_domain?: string;
    actor_user_id?: string;
    keyword?: string;
    dateRange?: [dayjs.Dayjs | null, dayjs.Dayjs | null] | null;
}

interface FilterTag {
    key: keyof AuditLogFilters;
    label: string;
    value: string;
}

interface AuditLogFilterProps {
    filters: AuditLogFilters;
    onFilterChange: (filters: AuditLogFilters) => void;
    showFilter: boolean;
}

const AuditLogFilter: React.FC<AuditLogFilterProps> = ({ filters, onFilterChange, showFilter }) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();

    const filterTags = useMemo(() => {
        const tags: FilterTag[] = [];
        if (filters.action_type)
            tags.push({
                key: "action_type",
                label: t("sys.audit.action_type"),
                value: filters.action_type,
            });
        if (filters.target_domain)
            tags.push({
                key: "target_domain",
                label: t("sys.audit.domain"),
                value: filters.target_domain,
            });
        if (filters.actor_user_id)
            tags.push({
                key: "actor_user_id",
                label: t("sys.audit.actor"),
                value: filters.actor_user_id,
            });
        if (filters.keyword)
            tags.push({
                key: "keyword",
                label: t("common.search"),
                value: filters.keyword,
            });
        if (filters.dateRange?.[0] && filters.dateRange?.[1]) {
            const start = filters.dateRange[0].format("YYYY-MM-DD");
            const end = filters.dateRange[1].format("YYYY-MM-DD");
            tags.push({
                key: "dateRange",
                label: t("sys.audit.created_at"),
                value: `${start} ~ ${end}`,
            });
        }
        return tags;
    }, [filters, t]);

    const removeFilter = (key: keyof AuditLogFilters) => {
        const newFilters = { ...filters };
        delete newFilters[key];
        onFilterChange(newFilters);
    };

    return (
        <div style={{ height: "auto", display: "flex", flexDirection: "column" }}>
            {showFilter && (
                <div
                    style={{
                        padding: "16px 20px",
                        background: token.colorFillAlter,
                        borderBottom: `1px solid ${token.colorBorderSecondary}`,
                    }}
                >
                    <Row gutter={[16, 16]}>
                        <Col span={6}>
                            <Space direction="vertical" style={{ width: "100%" }} size={2}>
                                <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                    {t("sys.audit.created_at")}
                                </span>
                                <RangePicker
                                    size="small"
                                    style={{ width: "100%" }}
                                    value={filters.dateRange}
                                    onChange={(val) => onFilterChange({ ...filters, dateRange: val })}
                                />
                            </Space>
                        </Col>
                        <Col span={4}>
                            <Space direction="vertical" style={{ width: "100%" }} size={2}>
                                <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                    {t("sys.audit.action_type")}
                                </span>
                                <Select
                                    size="small"
                                    style={{ width: "100%" }}
                                    placeholder={t("common.select_placeholder")}
                                    allowClear
                                    value={filters.action_type}
                                    onChange={(val) => onFilterChange({ ...filters, action_type: val })}
                                    options={[
                                        { value: "CREATE", label: "CREATE" },
                                        { value: "UPDATE", label: "UPDATE" },
                                        { value: "DELETE", label: "DELETE" },
                                        { value: "LOGIN", label: "LOGIN" },
                                        { value: "LOGIN_FAILURE", label: "LOGIN_FAILURE" },
                                        { value: "GRANT_ROLE", label: "GRANT_ROLE" },
                                    ]}
                                />
                            </Space>
                        </Col>
                        <Col span={4}>
                            <Space direction="vertical" style={{ width: "100%" }} size={2}>
                                <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                    {t("sys.audit.domain")}
                                </span>
                                <Select
                                    size="small"
                                    style={{ width: "100%" }}
                                    placeholder={t("common.select_placeholder")}
                                    allowClear
                                    value={filters.target_domain}
                                    onChange={(val) => onFilterChange({ ...filters, target_domain: val })}
                                    options={["USR", "IAM", "FAC", "SYS", "CMM"].map((d) => ({
                                        value: d,
                                        label: d,
                                    }))}
                                />
                            </Space>
                        </Col>
                        <Col span={4}>
                            <Space direction="vertical" style={{ width: "100%" }} size={2}>
                                <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                    {t("sys.audit.actor")}
                                </span>
                                <Input
                                    size="small"
                                    placeholder="User ID"
                                    value={filters.actor_user_id}
                                    onChange={(e) =>
                                        onFilterChange({
                                            ...filters,
                                            actor_user_id: e.target.value,
                                        })
                                    }
                                />
                            </Space>
                        </Col>
                        <Col span={6}>
                            <Space direction="vertical" style={{ width: "100%" }} size={2}>
                                <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                    {t("common.search")}
                                </span>
                                <Input.Search
                                    size="small"
                                    placeholder={t("sys.audit.description")}
                                    allowClear
                                    value={filters.keyword}
                                    onChange={(e) => onFilterChange({ ...filters, keyword: e.target.value })}
                                    onSearch={(val) => onFilterChange({ ...filters, keyword: val })}
                                />
                            </Space>
                        </Col>
                    </Row>
                </div>
            )}

            <div style={{ padding: "16px 16px 0 16px" }}>
                {filterTags.length > 0 && (
                    <div
                        style={{
                            marginBottom: 12,
                            display: "flex",
                            alignItems: "center",
                            flexWrap: "wrap",
                            gap: 8,
                        }}
                    >
                        <Tooltip title={t("common.active_filters")}>
                            <FilterOutlined style={{ color: token.colorTextSecondary, marginRight: 4 }} />
                        </Tooltip>
                        {filterTags.map((tag) => (
                            <Tag
                                key={tag.key}
                                closable
                                onClose={() => removeFilter(tag.key)}
                                style={{
                                    borderRadius: "12px",
                                    padding: "0 10px",
                                    background: token.colorBgContainer,
                                }}
                            >
                                <span style={{ color: token.colorTextSecondary }}>{tag.label}:</span> {tag.value}
                            </Tag>
                        ))}
                        <Tooltip title={t("common.clear_all")}>
                            <Button
                                type="text"
                                size="small"
                                danger
                                icon={<CloseCircleOutlined />}
                                onClick={() => onFilterChange({})}
                            />
                        </Tooltip>
                    </div>
                )}
            </div>
        </div>
    );
};

export default AuditLogFilter;
