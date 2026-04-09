import { EditOutlined, LineHeightOutlined } from "@ant-design/icons";
import type { ActionType, ProColumns } from "@ant-design/pro-components";
import { ProTable } from "@ant-design/pro-components";
import { Button, Dropdown, Select, Tag } from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Organization } from "@/domains/usr/types";

interface OrgTableProps {
    dataSource: Organization[];
    onSelectOrg: (key: React.Key) => void;
    onEditOrg: (record: Organization) => void;
}

const OrgTable: React.FC<OrgTableProps> = ({ dataSource, onSelectOrg, onEditOrg }) => {
    const { t } = useTranslation();
    const actionRef = useRef<ActionType>(null);
    const [tableSize, setTableSize] = useState<SizeType>("middle");
    const [pageSize, setPageSize] = useState(10);

    const columns: ProColumns<Organization>[] = [
        {
            title: t("org.name"),
            dataIndex: "name",
            render: (text, record) => (
                <Button
                    type="link"
                    style={{ padding: 0, height: "auto" }}
                    onClick={() => onSelectOrg(String(record.id))}
                >
                    {text}
                </Button>
            ),
        },
        { title: t("org.code"), dataIndex: "code", width: 100 },
        {
            title: t("common.status"),
            dataIndex: "is_active",
            width: 80,
            render: (active) => (
                <Tag color={active ? "green" : "default"}>{active ? t("common.active") : t("common.inactive")}</Tag>
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
                    onClick={() => onEditOrg(record)}
                />,
            ],
        },
    ];

    return (
        <div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
            <ProTable<Organization>
                actionRef={actionRef}
                columns={columns}
                dataSource={dataSource}
                rowKey="id"
                search={false}
                options={{ setting: true, density: false }}
                size={tableSize}
                pagination={{
                    pageSize,
                    onChange: (_, size) => setPageSize(size || 10),
                }}
                toolBarRender={() => [
                    <Select
                        key="pz"
                        size="small"
                        value={pageSize}
                        onChange={setPageSize}
                        options={[
                            { value: 10, label: t("user.page_size", { count: 10 }) },
                            { value: 20, label: t("user.page_size", { count: 20 }) },
                        ]}
                        style={{ width: 80 }}
                    />,
                    <Dropdown
                        key="ds"
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
                    >
                        <Button type="text" size="small" icon={<LineHeightOutlined />} />
                    </Dropdown>,
                ]}
            />
        </div>
    );
};

export default OrgTable;
