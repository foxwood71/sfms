import { DeleteOutlined, EditOutlined, PlusOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import {
    ModalForm,
    PageContainer,
    ProCard,
    ProFormDigit,
    ProFormSwitch,
    ProFormText,
    ProFormTextArea,
    ProTable,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Button, message, Popconfirm, Space, Switch, Tag, Typography, theme } from "antd";
import axios from "axios";
import type React from "react";
import { useMemo, useState } from "react";
import {
    createCodeDetail,
    createCodeGroup,
    deleteCodeDetail,
    deleteCodeGroup,
    getCodeDetails,
    getCodeGroups,
    updateCodeDetail,
    updateCodeGroup,
} from "../api";
import type { CodeDetail, CodeGroup } from "../types";

/**
 * 공통 코드 관리 페이지 컴포넌트
 */
const CodeManagePage: React.FC = () => {
    const queryClient = useQueryClient();
    const { token } = theme.useToken();

    // 상태 관리
    const [selectedGroup, setSelectedGroup] = useState<CodeGroup | null>(null);
    const [showInactiveGroup, setShowInactiveGroup] = useState(true);
    const [showInactiveDetail, setShowInactiveDetail] = useState(true);

    const [groupModalVisible, setGroupModalVisible] = useState(false);
    const [detailModalVisible, setDetailModalVisible] = useState(false);
    const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
    const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

    // 레이아웃 설정
    const CONTENT_HEIGHT = "calc(100vh - 180px)";
    const TABLE_SCROLL_Y = "calc(100vh - 370px)";

    // [공통 에러 핸들러]
    const handleAxiosError = (error: unknown, prefix: string) => {
        let detail = "알 수 없는 오류가 발생했습니다.";
        if (axios.isAxiosError(error)) {
            detail = error.response?.data?.message || error.message;
        }
        message.error(`${prefix}: ${detail}`);
    };

    // 1. 데이터 조회 및 정렬
    const { data: groupResponse, isLoading: isGroupLoading } = useQuery({
        queryKey: ["codeGroups"],
        queryFn: () => getCodeGroups(),
    });

    // 그룹 목록: 코드순 정렬 및 필터링
    const filteredGroups = useMemo(() => {
        const allGroups = [...(groupResponse?.data || [])].sort((a, b) => a.group_code.localeCompare(b.group_code));
        if (showInactiveGroup) return allGroups;
        return allGroups.filter((g) => g.is_active);
    }, [groupResponse, showInactiveGroup]);

    const { data: rawDetails, isLoading: isDetailLoading } = useQuery({
        queryKey: ["codeDetails", selectedGroup?.group_code],
        queryFn: () => {
            if (!selectedGroup) return [];
            return getCodeDetails(selectedGroup.group_code);
        },
        enabled: !!selectedGroup,
    });

    // 상세 목록: [핵심] sort_order 오름차순 정렬 및 필터링
    const filteredDetails = useMemo(() => {
        if (!rawDetails) return [];
        const sorted = [...rawDetails].sort(
            (a, b) => (a.sort_order || 0) - (b.sort_order || 0) || a.detail_code.localeCompare(b.detail_code),
        );
        if (showInactiveDetail) return sorted;
        return sorted.filter((d) => d.is_active);
    }, [rawDetails, showInactiveDetail]);

    // 2. 뮤테이션
    const groupMutation = useMutation({
        mutationFn: (data: Partial<CodeGroup>) => {
            const formattedData = { ...data, group_code: data.group_code?.toUpperCase() };
            return editingGroup
                ? updateCodeGroup(editingGroup.group_code, formattedData)
                : createCodeGroup(formattedData as CodeGroup);
        },
        onSuccess: () => {
            message.success("그룹 정보가 저장되었습니다.");
            setGroupModalVisible(false);
            queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
        },
        onError: (err) => handleAxiosError(err, "그룹 저장 실패"),
    });

    const detailMutation = useMutation({
        mutationFn: (data: Partial<CodeDetail>) => {
            if (!selectedGroup) throw new Error("그룹 코드가 누락되었습니다.");
            const formattedData = {
                ...data,
                detail_code: data.detail_code?.toUpperCase(),
                group_code: selectedGroup.group_code,
            };
            return editingDetail
                ? updateCodeDetail(selectedGroup.group_code, editingDetail.detail_code, formattedData)
                : createCodeDetail(formattedData as CodeDetail);
        },
        onSuccess: () => {
            message.success("상세 코드가 저장되었습니다.");
            setDetailModalVisible(false);
            queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
            queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup?.group_code] });
        },
        onError: (err) => handleAxiosError(err, "코드 저장 실패"),
    });

    // 3. 삭제 처리
    const onDeleteGroup = async (code: string) => {
        try {
            await deleteCodeGroup(code);
            message.success("그룹이 삭제되었습니다.");
            if (selectedGroup?.group_code === code) setSelectedGroup(null);
            queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
        } catch (err) {
            handleAxiosError(err, "그룹 삭제 실패");
        }
    };

    const onDeleteDetail = async (detailCode: string) => {
        if (!selectedGroup) return;
        try {
            await deleteCodeDetail(selectedGroup.group_code, detailCode);
            message.success("코드가 삭제되었습니다.");
            queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
            queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup.group_code] });
        } catch (err) {
            handleAxiosError(err, "코드 삭제 실패");
        }
    };

    // 4. 컬럼 정의
    const groupColumns: ProColumns<CodeGroup>[] = [
        { title: "그룹 코드", dataIndex: "group_code", width: 140 },
        { title: "그룹명", dataIndex: "group_name", ellipsis: true },
        {
            title: "상태",
            dataIndex: "is_active",
            width: 60,
            align: "center",
            render: (val) => <Tag color={val ? "green" : "red"}>{val ? "사용" : "중지"}</Tag>,
        },
        {
            title: "작업",
            width: 70,
            align: "center",
            render: (_, record) => (
                <Space size={0}>
                    <EditOutlined
                        onClick={(e) => {
                            e.stopPropagation();
                            setEditingGroup(record);
                            setGroupModalVisible(true);
                        }}
                        style={{ padding: 4, cursor: "pointer", color: token.colorPrimary }}
                    />
                    <Popconfirm title="그룹을 삭제하시겠습니까?" onConfirm={() => onDeleteGroup(record.group_code)}>
                        <DeleteOutlined style={{ padding: 4, color: token.colorError, cursor: "pointer" }} />
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    const detailColumns: ProColumns<CodeDetail>[] = [
        { title: "상세 코드", dataIndex: "detail_code", width: 150 },
        { title: "코드명", dataIndex: "detail_name" },
        { title: "정렬", dataIndex: "sort_order", width: 60, align: "center" },
        {
            title: "상태",
            dataIndex: "is_active",
            width: 60,
            render: (val) => <Tag color={val ? "green" : "red"}>{val ? "사용" : "중지"}</Tag>,
        },
        {
            title: "작업",
            width: 70,
            align: "center",
            render: (_, record) => (
                <Space size={0}>
                    <EditOutlined
                        onClick={() => {
                            setEditingDetail(record);
                            setDetailModalVisible(true);
                        }}
                        style={{ padding: 4, cursor: "pointer", color: token.colorPrimary }}
                    />
                    <Popconfirm title="코드를 삭제하시겠습니까?" onConfirm={() => onDeleteDetail(record.detail_code)}>
                        <DeleteOutlined style={{ padding: 4, color: token.colorError, cursor: "pointer" }} />
                    </Popconfirm>
                </Space>
            ),
        },
    ];

    return (
        <PageContainer header={{ title: "공통 코드 관리" }}>
            <ProCard ghost gutter={16} style={{ height: CONTENT_HEIGHT }}>
                <ProCard
                    colSpan={10}
                    title="코드 그룹"
                    headerBordered
                    bordered
                    style={{ height: "100%" }}
                    bodyStyle={{ padding: 0, display: "flex", flexDirection: "column" }}
                >
                    <ProTable<CodeGroup>
                        size="small"
                        rowKey="group_code"
                        columns={groupColumns}
                        dataSource={filteredGroups}
                        loading={isGroupLoading}
                        search={false}
                        options={false}
                        pagination={false}
                        scroll={{ y: TABLE_SCROLL_Y }}
                        toolBarRender={() => [
                            <Space key="filter" style={{ marginRight: 8 }}>
                                <Typography.Text size="small" type="secondary">
                                    사용중지 포함
                                </Typography.Text>
                                <Switch size="small" checked={showInactiveGroup} onChange={setShowInactiveGroup} />
                            </Space>,
                            <Button
                                key="add"
                                type="primary"
                                size="small"
                                icon={<PlusOutlined />}
                                onClick={() => {
                                    setEditingGroup(null);
                                    setGroupModalVisible(true);
                                }}
                            >
                                추가
                            </Button>,
                        ]}
                        onRow={(record) => ({
                            onClick: () => setSelectedGroup(record),
                            style: {
                                cursor: "pointer",
                                backgroundColor:
                                    selectedGroup?.group_code === record.group_code
                                        ? token.controlItemBgActive
                                        : "inherit",
                            },
                        })}
                    />
                </ProCard>

                <ProCard
                    colSpan={14}
                    title={selectedGroup ? `[${selectedGroup.group_name}] 상세 코드` : "상세 코드"}
                    headerBordered
                    bordered
                    style={{ height: "100%" }}
                    bodyStyle={{ padding: 0, display: "flex", flexDirection: "column" }}
                >
                    {selectedGroup ? (
                        <ProTable<CodeDetail>
                            size="small"
                            rowKey="detail_code"
                            columns={detailColumns}
                            dataSource={filteredDetails}
                            loading={isDetailLoading}
                            search={false}
                            options={false}
                            pagination={false}
                            scroll={{ y: TABLE_SCROLL_Y }}
                            toolBarRender={() => [
                                <Space key="filter" style={{ marginRight: 8 }}>
                                    <Typography.Text size="small" type="secondary">
                                        사용중지 포함
                                    </Typography.Text>
                                    <Switch
                                        size="small"
                                        checked={showInactiveDetail}
                                        onChange={setShowInactiveDetail}
                                    />
                                </Space>,
                                <Button
                                    key="add"
                                    size="small"
                                    icon={<PlusOutlined />}
                                    onClick={() => {
                                        setEditingDetail(null);
                                        setDetailModalVisible(true);
                                    }}
                                >
                                    추가
                                </Button>,
                            ]}
                        />
                    ) : (
                        <div
                            style={{
                                flex: 1,
                                display: "flex",
                                justifyContent: "center",
                                alignItems: "center",
                                color: token.colorTextDisabled,
                            }}
                        >
                            좌측에서 그룹을 선택해주세요.
                        </div>
                    )}
                </ProCard>
            </ProCard>

            <ModalForm
                title={editingGroup ? "코드 그룹 수정" : "새 코드 그룹 추가"}
                open={groupModalVisible}
                onOpenChange={setGroupModalVisible}
                onFinish={async (values) => {
                    await groupMutation.mutateAsync(values);
                    return true;
                }}
                initialValues={editingGroup || { is_active: true }}
                modalProps={{ destroyOnClose: true }}
            >
                <ProFormText
                    name="group_code"
                    label="그룹 코드"
                    disabled={!!editingGroup}
                    rules={[{ required: true }]}
                />
                <ProFormText name="group_name" label="그룹명" rules={[{ required: true }]} />
                <ProFormTextArea name="description" label="설명" />
                <ProFormSwitch name="is_active" label="사용 여부" />
            </ModalForm>

            <ModalForm
                title={editingDetail ? "상세 코드 수정" : "새 상세 코드 추가"}
                open={detailModalVisible}
                onOpenChange={setDetailModalVisible}
                onFinish={async (values) => {
                    await detailMutation.mutateAsync(values);
                    return true;
                }}
                initialValues={editingDetail || { is_active: true, sort_order: 0 }}
                modalProps={{ destroyOnClose: true }}
            >
                <ProFormText
                    name="detail_code"
                    label="상세 코드"
                    disabled={!!editingDetail}
                    rules={[{ required: true }]}
                />
                <ProFormText name="detail_name" label="코드명" rules={[{ required: true }]} />
                <ProFormDigit name="sort_order" label="정렬 순서" />
                <ProFormSwitch name="is_active" label="사용 여부" />
            </ModalForm>
        </PageContainer>
    );
};

export default CodeManagePage;
