import {
    EditOutlined,
    FilterOutlined,
    LineHeightOutlined,
    PlusOutlined,
} from "@ant-design/icons";
import type { ActionType, ProColumns } from "@ant-design/pro-components";
import { ProCard, ProTable } from "@ant-design/pro-components";
import { Button, Dropdown, Empty, Select, Space, Switch, Tag, Tooltip, theme } from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getCodeDetails } from "@/domains/cmm/api";
import type { CodeDetail, CodeGroup } from "@/domains/cmm/types";

interface CodeDetailTableProps {
    selectedGroup: CodeGroup | null;
    onEditGroup: () => void;
    onAddDetail: () => void;
    onEditDetail: (record: CodeDetail) => void;
}

const CodeDetailTable: React.FC<CodeDetailTableProps> = ({
    selectedGroup,
    onEditGroup,
    onAddDetail,
    onEditDetail,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const detailActionRef = useRef<ActionType>(null);

    const [tableSize, setTableSize] = useState<SizeType>("middle");
    const [pageSize, setPageSize] = useState(10);
    const [showFilter, setShowFilter] = useState(false);
    const [showInactive, setShowInactive] = useState(false);
    const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

    const columns: ProColumns<CodeDetail>[] = [
        { title: t("cmm.code.detail_name"), dataIndex: "detail_name", ellipsis: true },
        { title: t("cmm.code.detail_code"), dataIndex: "detail_code", width: 100 },
        {
            title: t("common.sort_order"),
            dataIndex: "sort_order",
            width: 80,
            hideInSearch: true,
            sorter: (a, b) => a.sort_order - b.sort_order,
            defaultSortOrder: "ascend",
        },
        {
            title: t("common.status"),
            dataIndex: "is_active",
            width: 100,
            render: (active) => (
                <Tag color={active ? "green" : "default"} style={{ borderRadius: "10px", padding: "0 10px" }}>
                    {active ? t("common.active") : t("common.inactive")}
                </Tag>
            ),
        },
        {
            title: t("common.action"),
            valueType: "option",
            width: 80,
            render: (_, record) => [
                <Button
                    key="edit"
                    type="text"
                    size="small"
                    icon={<EditOutlined />}
                    onClick={() => onEditDetail(record)}
                />,
            ],
        },
    ];

    return (
        <ProCard
            title={
                selectedGroup
                    ? `${selectedGroup.group_name} (${selectedGroup.group_code})`
                    : t("cmm.code.detail_list")
            }
            bordered={false}
            extra={
                selectedGroup && (
                    <Space size={8}>
                        <Button
                            type="text"
                            size="small"
                            icon={
                                <FilterOutlined
                                    style={{ color: showFilter ? token.colorPrimary : undefined }}
                                />
                            }
                            onClick={() => setShowFilter(!showFilter)}
                        />
                        <Button
                            icon={<EditOutlined />}
                            size="small"
                            onClick={onEditGroup}
                        >
                            {t("cmm.code.edit_group")}
                        </Button>
                        <Button
                            type="primary"
                            icon={<PlusOutlined />}
                            size="small"
                            onClick={onAddDetail}
                        >
                            {t("cmm.code.add_detail")}
                        </Button>
                    </Space>
                )
            }
        >
            <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
                {showFilter && (
                    <div
                        style={{
                            padding: "12px 20px",
                            background: token.colorFillAlter,
                            borderBottom: `1px solid ${token.colorBorderSecondary}`,
                        }}
                    >
                        <div
                            style={{
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                            }}
                        >
                            <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                {t("cmm.code.include_inactive")}
                            </span>
                            <Switch
                                size="small"
                                checked={showInactive}
                                onChange={setShowInactive}
                            />
                        </div>
                    </div>
                )}

                {selectedGroup ? (
                    <div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
                        <ProTable<CodeDetail>
                            actionRef={detailActionRef}
                            columns={columns}
                            size={tableSize}
                            rowKey="detail_code"
                            rowSelection={{
                                selectedRowKeys,
                                onChange: setSelectedRowKeys,
                            }}
                            tableAlertRender={({ selectedRowKeys, onCleanSelected }) => (
                                <Space size={24}>
                                    <span>
                                        {t("common.selected_count", { count: selectedRowKeys.length })}
                                    </span>
                                    <Button type="link" size="small" onClick={onCleanSelected}>
                                        {t("common.clear_selection")}
                                    </Button>
                                </Space>
                            )}
                            request={async () => {
                                const details = await getCodeDetails(selectedGroup.group_code);
                                const filteredData = showInactive
                                    ? details
                                    : details.filter((d: CodeDetail) => d.is_active);
                                return { data: filteredData || [], success: true };
                            }}
                            params={{
                                groupCode: selectedGroup.group_code,
                                showInactive: showInactive,
                            }}
                            search={false}
                            options={{ setting: true, density: false }}
                            pagination={{
                                pageSize,
                                onChange: (_, size) => setPageSize(size || 10),
                            }}
                            toolBarRender={() => [
                                <Select
                                    key="dpz"
                                    size="small"
                                    value={pageSize}
                                    onChange={setPageSize}
                                    options={[
                                        { value: 10, label: t("user.page_size", { count: 10 }) },
                                        { value: 20, label: t("user.page_size", { count: 20 }) },
                                        { value: 50, label: t("user.page_size", { count: 50 }) },
                                    ]}
                                    style={{ width: 80 }}
                                />,
                                <Dropdown
                                    key="dds"
                                    menu={{
                                        items: [
                                            {
                                                key: "large",
                                                label: t("user.density_default"),
                                                onClick: () => setTableSize("large"),
                                            },
                                            {
                                                key: "middle",
                                                label: t("user.density_middle"),
                                                onClick: () => setTableSize("middle"),
                                            },
                                            {
                                                key: "small",
                                                label: t("user.density_small"),
                                                onClick: () => setTableSize("small"),
                                            },
                                        ],
                                    }}
                                    placement="bottomRight"
                                >
                                    <Tooltip title={t("user.density")}>
                                        <Button type="text" icon={<LineHeightOutlined />} />
                                    </Tooltip>
                                </Dropdown>,
                            ]}
                        />
                    </div>
                ) : (
                    <div
                        style={{
                            flex: 1,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            background: token.colorFillQuaternary,
                        }}
                    >
                        <Empty description={t("cmm.code.select_group_prompt")} />
                    </div>
                )}
            </div>
        </ProCard>
    );
};

export default CodeDetailTable;
