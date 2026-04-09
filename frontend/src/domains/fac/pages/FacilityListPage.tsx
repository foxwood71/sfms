import { DeleteOutlined, EditOutlined, FilterOutlined, PlusOutlined, ReloadOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { App, Button, Input, Popconfirm, Space, Switch, Tag, Tooltip, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import FacilityFormDrawer from "../components/FacilityFormDrawer";
import type { Facility } from "../types";
import { useFacilityListPage } from "./FacilityList/hooks/useFacilityListPage";

/**
 * 최상위 시설물 관리 페이지 (Bento Standard v1.1)
 */
const FacilityListPage: React.FC = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const { token } = theme.useToken();
    const logic = useFacilityListPage();

    const columns: ProColumns<Facility>[] = [
        {
            title: t("fac.facility.code"),
            dataIndex: "code",
            width: 120,
            copyable: true,
        },
        {
            title: t("fac.facility.name"),
            dataIndex: "name",
            ellipsis: true,
            render: (text, record) => (
                <Button
                    type="link"
                    size="small"
                    style={{ fontWeight: 500, padding: 0, height: "auto" }}
                    onClick={() => logic.handleEdit(record)}
                >
                    {text}
                </Button>
            ),
        },
        { title: t("fac.facility.address"), dataIndex: "address", ellipsis: true },
        {
            title: t("fac.facility.status"),
            dataIndex: "is_active",
            width: 100,
            align: "center",
            render: (active) => (
                <Tag color={active ? "green" : "red"}>{active ? t("common.active") : t("common.inactive")}</Tag>
            ),
        },
        {
            title: t("common.action"),
            valueType: "option",
            width: 100,
            align: "center",
            render: (_, record) => [
                <Tooltip key="edit-tip" title={t("common.edit")}>
                    <Button
                        key="edit"
                        type="text"
                        size="small"
                        icon={<EditOutlined style={{ color: token.colorPrimary }} />}
                        onClick={() => logic.handleEdit(record)}
                    />
                </Tooltip>,
                <Popconfirm
                    key="del-pop"
                    title={t("common.delete_confirm_msg")}
                    onConfirm={() => message.info("물리 삭제는 도메인 정책에 따라 제한될 수 있습니다.")}
                >
                    <Tooltip key="del-tip" title={t("common.delete")}>
                        <Button key="delete" type="text" size="small" danger icon={<DeleteOutlined />} />
                    </Tooltip>
                </Popconfirm>,
            ],
        },
    ];

    return (
        <PageContainer
            header={{ title: t("fac.facility.title") }}
            childrenContentStyle={{
                padding: 0,
                height: LAYOUT_CONSTANTS.CONTENT_HEIGHT,
                overflow: "hidden",
            }}
        >
            <style>{`
				html, body { overflow: hidden !important; height: 100%; }
				.ant-pro-card-body { overflow: hidden !important; display: flex; flex-direction: column; height: 100%; }
				.ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
				${logic.pageSize <= 10 ? ".ant-table-body { overflow-y: hidden !important; }" : ".ant-table-body { flex: 1; overflow-y: auto !important; }"}
			`}</style>

            <ProCard
                headerBordered
                headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
                extra={
                    <Space>
                        <Tooltip title={t("common.search")}>
                            <Button
                                type="text"
                                icon={<FilterOutlined style={{ color: logic.showFilter ? token.colorPrimary : undefined }} />}
                                onClick={() => logic.setShowFilter(!logic.showFilter)}
                            />
                        </Tooltip>
                        <Tooltip title={t("common.reload")}>
                            <Button
                                type="text"
                                icon={<ReloadOutlined />}
                                onClick={logic.reload}
                                loading={logic.isFetching}
                            />
                        </Tooltip>
                        <Tooltip title={t("common.add")}>
                            <Button type="primary" size="small" icon={<PlusOutlined />} onClick={logic.handleAdd} />
                        </Tooltip>
                    </Space>
                }
            >
                <div style={{ height: "100%", display: "flex", flexDirection: "column", padding: "0 16px" }}>
                    {logic.showFilter && (
                        <div style={{ padding: "16px", background: token.colorFillAlter, borderRadius: token.borderRadiusLG, marginBottom: 16, marginTop: 8 }}>
                            <Space size={24}>
                                <Space direction="vertical" size={2}>
                                    <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>
                                        {t("fac.facility.name")} / {t("fac.facility.code")}
                                    </span>
                                    <Input.Search
                                        placeholder={t("common.search_placeholder")}
                                        size="small"
                                        allowClear
                                        onSearch={logic.setSearchValue}
                                        style={{ width: 250 }}
                                    />
                                </Space>
                                <Space direction="vertical" size={2}>
                                    <span style={{ fontSize: "12px", color: token.colorTextSecondary }}>{t("org.include_inactive")}</span>
                                    <Switch size="small" checked={logic.showInactive} onChange={logic.setShowInactive} />
                                </Space>
                            </Space>
                        </div>
                    )}

                    <ProTable<Facility>
                        columns={columns}
                        dataSource={logic.filteredData}
                        rowKey="id"
                        search={false}
                        options={false}
                        size="small"
                        pagination={{
                            pageSize: logic.pageSize,
                            onChange: (_, size) => logic.setPageSize(size || 10),
                            showSizeChanger: true,
                        }}
                        scroll={{
                            x: "max-content",
                            y: logic.pageSize <= 10 ? undefined : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT,
                        }}
                    />
                </div>
            </ProCard>

            <FacilityFormDrawer
                open={logic.drawerOpen}
                onOpenChange={logic.setDrawerOpen}
                editingFacility={logic.editingFacility}
                onFinish={logic.onSaveFinish}
            />
        </PageContainer>
    );
};

export default FacilityListPage;
