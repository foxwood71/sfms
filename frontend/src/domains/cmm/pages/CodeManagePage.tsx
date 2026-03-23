import { DeleteOutlined, EditOutlined, FilterOutlined, PlusOutlined, SaveOutlined, CloseOutlined, ReloadOutlined } from "@ant-design/icons";
import type { ActionType, ProColumns } from "@ant-design/pro-components";
import {
	PageContainer,
	ProCard,
	ProTable,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App, Button, Empty, Space, Splitter, theme, Tooltip } from "antd";
import type React from "react";
import { useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
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
import CodeDetailDrawer from "../components/CodeDetailDrawer";
import CodeGroupDrawer from "../components/CodeGroupDrawer";
import type { CodeDetail, CodeGroup, CodeGroupParams } from "../types";

/**
 * 공통 코드 관리 페이지 (Refined Single Bento Standard)
 */
const CodeManagePage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const groupActionRef = useRef<ActionType>();
	const detailActionRef = useRef<ActionType>();

	const [selectedGroup, setSelectedGroup] = useState<CodeGroup | null>(null);
	const [groupDrawerOpen, setGroupDrawerOpen] = useState(false);
	const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
	const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
	const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

	const { data: groups, isFetching: isGroupsLoading } = useQuery({
		queryKey: ["codeGroups"],
		queryFn: () => getCodeGroups(true),
	});

	const groupMutation = useMutation({
		mutationFn: (values: CodeGroupParams) => editingGroup ? updateCodeGroup(editingGroup.group_code, values) : createCodeGroup(values),
		onSuccess: () => { message.success(t("common.save_success")); setGroupDrawerOpen(false); queryClient.invalidateQueries({ queryKey: ["codeGroups"] }); },
	});

	const detailMutation = useMutation({
		mutationFn: (values: any) => editingDetail ? updateCodeDetail(selectedGroup!.group_code, editingDetail.detail_code, values) : createCodeDetail({ ...values, group_code: selectedGroup!.group_code }),
		onSuccess: () => { message.success(t("common.save_success")); setDetailDrawerOpen(false); queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup?.group_code] }); detailActionRef.current?.reload(); },
	});

	const groupColumns: ProColumns<CodeGroup>[] = [
		{ title: t("cmm.code.group_name"), dataIndex: "group_name", ellipsis: true },
		{ title: t("cmm.code.group_code"), dataIndex: "group_code", width: 120 },
	];

	const detailColumns: ProColumns<CodeDetail>[] = [
		{ title: t("cmm.code.detail_name"), dataIndex: "detail_name", ellipsis: true },
		{ title: t("cmm.code.detail_code"), dataIndex: "detail_code", width: 100 },
		{ title: t("common.sort_order"), dataIndex: "sort_order", width: 80, hideInSearch: true },
		{ title: t("common.status"), dataIndex: "is_active", width: 80, render: (active) => active ? t("common.active") : t("common.inactive") },
		{
			title: t("common.action"),
			valueType: "option",
			width: 80,
			render: (_, record) => [
				<Button key="edit" type="text" size="small" icon={<EditOutlined />} onClick={() => { setEditingDetail(record); setDetailDrawerOpen(true); }} />,
			],
		},
	];

	return (
		<PageContainer 
			header={{ title: t("cmm.code.title") }}
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
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }
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
                <Splitter style={{ height: "100%", background: "transparent" }}>
                    <Splitter.Panel defaultSize="35%" min="20%">
                        <ProCard 
                            title={t("cmm.code.group_list")}
                            bordered={false}
                            extra={
                                <Space size={4}>
                                    <Button type="text" size="small" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["codeGroups"] })} loading={isGroupsLoading} />
                                    <Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => { setEditingGroup(null); setGroupDrawerOpen(true); }}>{t("common.create")}</Button>
                                </Space>
                            }
                        >
                            <ProTable<CodeGroup>
                                columns={groupColumns}
                                dataSource={groups}
                                rowKey="group_code"
                                search={false}
                                options={false}
                                pagination={false}
                                scroll={{ y: "calc(100vh - 260px)" }}
                                onRow={(record) => ({
                                    onClick: () => setSelectedGroup(record),
                                    style: { cursor: "pointer", background: selectedGroup?.group_code === record.group_code ? token.colorPrimaryBg : "inherit" }
                                })}
                            />
                        </ProCard>
                    </Splitter.Panel>

                    <Splitter.Panel>
                        <ProCard 
                            title={selectedGroup ? `${selectedGroup.group_name} (${selectedGroup.group_code})` : t("cmm.code.detail_list")}
                            bordered={false}
                            extra={selectedGroup && (
                                <Space size={8}>
                                    <Button icon={<EditOutlined />} size="small" onClick={() => { setEditingGroup(selectedGroup); setGroupDrawerOpen(true); }}>{t("cmm.code.edit_group")}</Button>
                                    <Button type="primary" icon={<PlusOutlined />} size="small" onClick={() => { setEditingDetail(null); setDetailDrawerOpen(true); }}>{t("cmm.code.add_detail")}</Button>
                                </Space>
                            )}
                        >
                            {selectedGroup ? (
                                <div style={{ padding: "0 16px" }}>
                                    <ProTable<CodeDetail>
                                        actionRef={detailActionRef}
                                        columns={detailColumns}
                                        request={async () => {
                                            const details = await getCodeDetails(selectedGroup.group_code);
                                            return { data: details, success: true };
                                        }}
                                        params={{ groupCode: selectedGroup.group_code }}
                                        rowKey="detail_code"
                                        search={false}
                                        options={false}
                                        pagination={false}
                                    />
                                </div>
                            ) : (
                                <div style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center", background: token.colorFillQuaternary }}>
                                    <Empty description={t("cmm.code.select_group_prompt")} />
                                </div>
                            )}
                        </ProCard>
                    </Splitter.Panel>
                </Splitter>
            </div>

			<CodeGroupDrawer open={groupDrawerOpen} onOpenChange={setGroupDrawerOpen} editingGroup={editingGroup} onFinish={async (v) => { await groupMutation.mutateAsync(v); return true; }} />
			<CodeDetailDrawer open={detailDrawerOpen} onOpenChange={setDetailDrawerOpen} editingDetail={editingDetail} groupName={selectedGroup?.group_name || ""} onFinish={async (v) => { await detailMutation.mutateAsync(v); return true; }} />
		</PageContainer>
	);
};

export default CodeManagePage;
