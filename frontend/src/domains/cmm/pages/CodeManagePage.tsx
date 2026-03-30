import {
    AppstoreOutlined,
    DatabaseOutlined,
    EditOutlined,
    FileTextOutlined,
    FilterOutlined,
    FolderOutlined,
    LineHeightOutlined,
    PlusOutlined,
    ReloadOutlined,
    SettingOutlined,
    UserOutlined,
} from "@ant-design/icons";
import type { ActionType, ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App, Button, Dropdown, Empty, Select, Space, Splitter, Switch, Tag, Tooltip, Tree, theme } from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getStandardTableStyle } from "@/shared/constants/layout";
import { createCodeDetail, getCodeDetails, getCodeGroups, updateCodeDetail } from "../api";
import CodeDetailDrawer from "../components/CodeDetailDrawer";
import CodeGroupDrawer from "../components/CodeGroupDrawer";
import type { CodeDetail, CodeGroup } from "../types";

/**
 * 트리 노드 확장 인터페이스 (Generics 대응)
 */
interface CodeGroupNode extends DataNode {
    data?: CodeGroup;
}

/**
 * 공통 코드 관리 페이지 (Refined Bento Standard - Final Tree Navigator)
 */
const CodeManagePage: React.FC = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();
    const { token } = theme.useToken();

    const detailActionRef = useRef<ActionType>(null);

    const [selectedGroup, setSelectedGroup] = useState<CodeGroup | null>(null);
    const [groupDrawerOpen, setGroupDrawerOpen] = useState(false);
    const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
    const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
    const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

    // --- 상태 관리 ---
    const [tableSize, setTableSize] = useState<SizeType>("middle");
    const [detailPageSize, setDetailPageSize] = useState(10);
    const [detailSelectedRowKeys, setDetailSelectedRowKeys] = useState<React.Key[]>([]);
    const [showDetailFilter, setShowDetailFilter] = useState(false);
    const [showInactiveDetail, setShowInactiveDetail] = useState(false);
    const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);

    const { data: groups, isFetching: isGroupsLoading } = useQuery({
        queryKey: ["codeGroups"],
        queryFn: async () => {
            const response = await getCodeGroups(true);
            return response?.data || [];
        },
    });

    // --- 도메인별 그룹화 트리 데이터 생성 ---
    const treeData: CodeGroupNode[] = useMemo(() => {
        if (!groups) return [];

        const domainMap: Record<string, { title: string; icon: React.ReactNode; groups: CodeGroup[] }> = {
            CMM: { title: t("cmm.code.domain_cmm"), icon: <DatabaseOutlined />, groups: [] },
            USR: { title: t("cmm.code.domain_usr"), icon: <UserOutlined />, groups: [] },
            FAC: { title: t("cmm.code.domain_fac"), icon: <AppstoreOutlined />, groups: [] },
            SYS: { title: t("cmm.code.domain_sys"), icon: <SettingOutlined />, groups: [] },
        };

        const result: CodeGroupNode[] = [];
        const otherGroups: CodeGroup[] = [];

        for (const g of groups) {
            if (g.domain_code && domainMap[g.domain_code]) {
                domainMap[g.domain_code].groups.push(g);
            } else {
                otherGroups.push(g);
            }
        }

        for (const [code, info] of Object.entries(domainMap)) {
            if (info.groups.length > 0) {
                result.push({
                    title: info.title,
                    key: `domain-${code}`,
                    icon: info.icon,
                    selectable: false,
                    children: info.groups.map((g) => ({
                        title: `${g.group_name} (${g.group_code})`,
                        key: g.group_code,
                        icon: <FileTextOutlined />,
                        isLeaf: true,
                        data: g,
                    })),
                });
            }
        }

        if (otherGroups.length > 0) {
            result.push({
                title: t("cmm.code.domain_other"),
                key: "domain-OTHER",
                icon: <FolderOutlined />,
                selectable: false,
                children: otherGroups.map((g) => ({
                    title: `${g.group_name} (${g.group_code})`,
                    key: g.group_code,
                    icon: <FileTextOutlined />,
                    isLeaf: true,
                    data: g,
                })),
            });
        }

        return result;
    }, [groups, t]);

    useEffect(() => {
        if (treeData.length > 0 && expandedKeys.length === 0) {
            setExpandedKeys(treeData.map((node) => node.key));
        }
    }, [treeData, expandedKeys]);

    const detailMutation = useMutation<unknown, Error, Partial<CodeDetail>>({
        mutationFn: (values: Partial<CodeDetail>) => {
            if (!selectedGroup) throw new Error("No code group selected");
            return editingDetail
                ? updateCodeDetail(selectedGroup.group_code, editingDetail.detail_code, values)
                : createCodeDetail({ ...values, group_code: selectedGroup.group_code });
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setDetailDrawerOpen(false);
            queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup?.group_code] });
            detailActionRef.current?.reload();
        },
    });

    const detailColumns: ProColumns<CodeDetail>[] = [
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
                    onClick={() => {
                        setEditingDetail(record);
                        setDetailDrawerOpen(true);
                    }}
                />,
            ],
        },
    ];

    return (
        <PageContainer
            header={{ title: t("cmm.code.title") }}
            childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
        >
            <style>{`
                ${getStandardTableStyle(token)}
				.ant-pro-card { height: 100% !important; display: flex !important; flex-direction: column !important; }
				.ant-pro-card-body { flex: 1 !important; display: flex !important; flex-direction: column !important; padding: 0 !important; overflow: hidden !important; }
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
                <Splitter style={{ height: "100%", background: "transparent" }}>
                    <Splitter.Panel defaultSize="25%" min="15%" max="40%">
                        <ProCard
                            title={t("cmm.code.group_list")}
                            bordered={false}
                            extra={
                                <Space size={4}>
                                    <Button
                                        type="text"
                                        size="small"
                                        icon={<ReloadOutlined />}
                                        onClick={() => queryClient.invalidateQueries({ queryKey: ["codeGroups"] })}
                                        loading={isGroupsLoading}
                                    />
                                    <Button
                                        type="primary"
                                        size="small"
                                        icon={<PlusOutlined />}
                                        onClick={() => {
                                            setEditingGroup(null);
                                            setGroupDrawerOpen(true);
                                        }}
                                    >
                                        {t("common.create")}
                                    </Button>
                                </Space>
                            }
                        >
                            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                                <Tree<CodeGroupNode>
                                    showIcon
                                    blockNode
                                    showLine={{ showLeafIcon: false }}
                                    treeData={treeData}
                                    expandedKeys={expandedKeys}
                                    onExpand={setExpandedKeys}
                                    selectedKeys={selectedGroup ? [selectedGroup.group_code] : []}
                                    onSelect={(keys, info) => {
                                        if (keys.length > 0 && info.node.isLeaf && info.node.data) {
                                            setSelectedGroup(info.node.data);
                                        }
                                    }}
                                />
                            </div>
                        </ProCard>
                    </Splitter.Panel>

                    <Splitter.Panel>
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
                                                    style={{ color: showDetailFilter ? token.colorPrimary : undefined }}
                                                />
                                            }
                                            onClick={() => setShowDetailFilter(!showDetailFilter)}
                                        />
                                        <Button
                                            icon={<EditOutlined />}
                                            size="small"
                                            onClick={() => {
                                                setEditingGroup(selectedGroup);
                                                setGroupDrawerOpen(true);
                                            }}
                                        >
                                            {t("cmm.code.edit_group")}
                                        </Button>
                                        <Button
                                            type="primary"
                                            icon={<PlusOutlined />}
                                            size="small"
                                            onClick={() => {
                                                setEditingDetail(null);
                                                setDetailDrawerOpen(true);
                                            }}
                                        >
                                            {t("cmm.code.add_detail")}
                                        </Button>
                                    </Space>
                                )
                            }
                        >
                            <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
                                {showDetailFilter && (
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
                                                checked={showInactiveDetail}
                                                onChange={setShowInactiveDetail}
                                            />
                                        </div>
                                    </div>
                                )}

                                {selectedGroup ? (
                                    <div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
                                        <ProTable<CodeDetail>
                                            actionRef={detailActionRef}
                                            columns={detailColumns}
                                            size={tableSize}
                                            rowKey="detail_code"
                                            rowSelection={{
                                                selectedRowKeys: detailSelectedRowKeys,
                                                onChange: setDetailSelectedRowKeys,
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
                                                const filteredData = showInactiveDetail
                                                    ? details
                                                    : details.filter((d: CodeDetail) => d.is_active);
                                                return { data: filteredData || [], success: true };
                                            }}
                                            params={{
                                                groupCode: selectedGroup.group_code,
                                                showInactive: showInactiveDetail,
                                            }}
                                            search={false}
                                            options={{ setting: true, density: false }}
                                            pagination={{
                                                pageSize: detailPageSize,
                                                onChange: (_, size) => setDetailPageSize(size || 10),
                                            }}
                                            toolBarRender={() => [
                                                <Select
                                                    key="dpz"
                                                    size="small"
                                                    value={detailPageSize}
                                                    onChange={setDetailPageSize}
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
                    </Splitter.Panel>
                </Splitter>
            </div>

            <CodeGroupDrawer
                open={groupDrawerOpen}
                onOpenChange={setGroupDrawerOpen}
                editingGroup={editingGroup}
                onFinish={async () => {
                    queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
                    return true;
                }}
            />
            <CodeDetailDrawer
                open={detailDrawerOpen}
                onOpenChange={setDetailDrawerOpen}
                editingDetail={editingDetail}
                groupName={selectedGroup?.group_name || ""}
                onFinish={async (v) => {
                    await detailMutation.mutateAsync(v);
                    return true;
                }}
            />
        </PageContainer>
    );
};

export default CodeManagePage;
