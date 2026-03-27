import { DeleteOutlined, EditOutlined, FilterOutlined, PlusOutlined, ReloadOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App, Button, Input, Popconfirm, Space, Switch, Tag, Tooltip, theme } from "antd";
import type { AxiosError } from "axios";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { createFacilityApi, getFacilitiesApi, updateFacilityApi } from "../api";
import FacilityFormDrawer from "../components/FacilityFormDrawer";
import type { Facility, FacilityParams } from "../types";

/**
 * 에러 응답 구조 정의
 */
interface ApiErrorResponse {
    message?: string;
}

/**
 * 최상위 시설물 관리 페이지 (Bento Standard v1.1)
 */
const FacilityListPage: React.FC = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();
    const { token } = theme.useToken();

    // 상태 관리
    const [showFilter, setShowFilter] = useState(false);
    const [pageSize, setPageSize] = useState(10);
    const [searchText, setSearchValue] = useState("");
    const [showInactive, setShowInactive] = useState(false);

    // 드로어 상태
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editingFacility, setEditingFacility] = useState<Facility | null>(null);

    // 시설 데이터 조회
    const { data: facilities, isFetching } = useQuery({
        queryKey: ["facilities", showInactive],
        queryFn: getFacilitiesApi,
    });

    // 저장 Mutation
    const saveMutation = useMutation({
        mutationFn: (values: FacilityParams) => {
            if (editingFacility) return updateFacilityApi(editingFacility.id, values);
            return createFacilityApi(values);
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setDrawerOpen(false);
            queryClient.invalidateQueries({ queryKey: ["facilities"] });
        },
        onError: (err: AxiosError<ApiErrorResponse>) =>
            message.error(err.response?.data?.message || t("common.save_failure")),
    });

    // 필터링된 데이터
    const filteredData = useMemo(() => {
        if (!facilities?.data) return [];
        return facilities.data.filter((item) => {
            const matchesSearch =
                item.name.toLowerCase().includes(searchText.toLowerCase()) ||
                item.code.toLowerCase().includes(searchText.toLowerCase());
            const matchesStatus = showInactive ? true : item.is_active;
            return matchesSearch && matchesStatus;
        });
    }, [facilities, searchText, showInactive]);

    /**
     * 테이블 컬럼 정의
     */
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
                    onClick={() => {
                        setEditingFacility(record);
                        setDrawerOpen(true);
                    }}
                >
                    {text}
                </Button>
            ),
        },
        {
            title: t("fac.facility.address"),
            dataIndex: "address",
            ellipsis: true,
        },
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
                        onClick={() => {
                            setEditingFacility(record);
                            setDrawerOpen(true);
                        }}
                    />
                </Tooltip>,
                <Popconfirm
                    key="del-pop"
                    title={t("common.delete_confirm_msg")}
                    onConfirm={() => {
                        message.info("물리 삭제는 도메인 정책에 따라 제한될 수 있습니다.");
                    }}
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
				${pageSize <= 10 ? ".ant-table-body { overflow-y: hidden !important; }" : ".ant-table-body { flex: 1; overflow-y: auto !important; }"}
			`}</style>

            <ProCard
                headerBordered
                headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
                extra={
                    <Space>
                        <Tooltip title={t("common.search")}>
                            <Button
                                type="text"
                                icon={
                                    <FilterOutlined
                                        style={{
                                            color: showFilter ? token.colorPrimary : undefined,
                                        }}
                                    />
                                }
                                onClick={() => setShowFilter(!showFilter)}
                            />
                        </Tooltip>
                        <Tooltip title={t("common.reload")}>
                            <Button
                                type="text"
                                icon={<ReloadOutlined />}
                                onClick={() => queryClient.invalidateQueries({ queryKey: ["facilities"] })}
                                loading={isFetching}
                            />
                        </Tooltip>
                        <Tooltip title={t("common.add")}>
                            <Button
                                type="primary"
                                size="small"
                                icon={<PlusOutlined />}
                                onClick={() => {
                                    setEditingFacility(null);
                                    setDrawerOpen(true);
                                }}
                            />
                        </Tooltip>
                    </Space>
                }
            >
                <div
                    style={{
                        height: "100%",
                        display: "flex",
                        flexDirection: "column",
                        padding: "0 16px",
                    }}
                >
                    {showFilter && (
                        <div
                            style={{
                                padding: "16px",
                                background: token.colorFillAlter,
                                borderRadius: token.borderRadiusLG,
                                marginBottom: 16,
                                marginTop: 8,
                            }}
                        >
                            <Space size={24}>
                                <Space direction="vertical" size={2}>
                                    <span
                                        style={{
                                            fontSize: "12px",
                                            color: token.colorTextSecondary,
                                        }}
                                    >
                                        {t("fac.facility.name")} / {t("fac.facility.code")}
                                    </span>
                                    <Input.Search
                                        placeholder={t("common.search_placeholder")}
                                        size="small"
                                        allowClear
                                        onSearch={setSearchValue}
                                        style={{ width: 250 }}
                                    />
                                </Space>
                                <Space direction="vertical" size={2}>
                                    <span
                                        style={{
                                            fontSize: "12px",
                                            color: token.colorTextSecondary,
                                        }}
                                    >
                                        {t("org.include_inactive")}
                                    </span>
                                    <Switch size="small" checked={showInactive} onChange={setShowInactive} />
                                </Space>
                            </Space>
                        </div>
                    )}

                    <ProTable<Facility>
                        columns={columns}
                        dataSource={filteredData}
                        rowKey="id"
                        search={false}
                        options={false}
                        size="small"
                        pagination={{
                            pageSize,
                            onChange: (_, size) => setPageSize(size || 10),
                            showSizeChanger: true,
                        }}
                        scroll={{
                            x: "max-content",
                            y: pageSize <= 10 ? undefined : LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT,
                        }}
                    />
                </div>
            </ProCard>

            <FacilityFormDrawer
                open={drawerOpen}
                onOpenChange={setDrawerOpen}
                editingFacility={editingFacility}
                onFinish={async (values) => {
                    await saveMutation.mutateAsync(values);
                    return true;
                }}
            />
        </PageContainer>
    );
};

export default FacilityListPage;
