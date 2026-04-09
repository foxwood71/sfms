import {
    AppstoreOutlined,
    DatabaseOutlined,
    FileTextOutlined,
    FolderOutlined,
    PlusOutlined,
    ReloadOutlined,
    SettingOutlined,
    UserOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { useQueryClient } from "@tanstack/react-query";
import { Button, Space, Tree } from "antd";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { CodeGroup } from "@/domains/cmm/types";

interface CodeGroupNode extends DataNode {
    data?: CodeGroup;
}

interface CodeGroupTreeProps {
    groups: CodeGroup[];
    isLoading: boolean;
    selectedGroupCode: string | undefined;
    onSelectGroup: (group: CodeGroup) => void;
    onAddGroup: () => void;
}

const CodeGroupTree: React.FC<CodeGroupTreeProps> = ({
    groups,
    isLoading,
    selectedGroupCode,
    onSelectGroup,
    onAddGroup,
}) => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);

    const treeData: CodeGroupNode[] = useMemo(() => {
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

    return (
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
                        loading={isLoading}
                    />
                    <Button
                        type="primary"
                        size="small"
                        icon={<PlusOutlined />}
                        onClick={onAddGroup}
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
                    selectedKeys={selectedGroupCode ? [selectedGroupCode] : []}
                    onSelect={(keys, info) => {
                        if (keys.length > 0 && info.node.isLeaf && info.node.data) {
                            onSelectGroup(info.node.data);
                        }
                    }}
                />
            </div>
        </ProCard>
    );
};

export default CodeGroupTree;
