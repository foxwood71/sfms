import {
    ApartmentOutlined,
    ClusterOutlined,
    CompressOutlined,
    ExpandOutlined,
    FilterOutlined,
    ReloadOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { useQueryClient } from "@tanstack/react-query";
import { Button, Input, Space, Switch, Tooltip, Tree, theme } from "antd";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Organization } from "@/domains/usr/types";

interface OrgTreeProps {
    orgData: Organization[];
    isFetching: boolean;
    selectedKey: React.Key;
    onSelect: (key: React.Key) => void;
    showInactive: boolean;
    onShowInactiveChange: (show: boolean) => void;
}

const OrgTree: React.FC<OrgTreeProps> = ({
    orgData,
    isFetching,
    selectedKey,
    onSelect,
    showInactive,
    onShowInactiveChange,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const queryClient = useQueryClient();

    const [showOrgFilter, setShowOrgFilter] = useState(false);
    const [orgSearchValue, setOrgSearchValue] = useState("");
    const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);
    const [isAllExpanded, setIsAllExpanded] = useState(true);
    const [isInitialLoad, setIsInitialLoad] = useState(true);

    const getAllKeys = useCallback((items: Organization[]): React.Key[] => {
        const keys: React.Key[] = ["root"];
        const collect = (list: Organization[]) => {
            for (const item of list) {
                keys.push(String(item.id));
                if (item.children) collect(item.children);
            }
        };
        collect(items);
        return keys;
    }, []);

    const toggleExpandAll = () => {
        if (isAllExpanded) {
            setExpandedKeys(["root"]);
            setIsAllExpanded(false);
        } else {
            setExpandedKeys(getAllKeys(orgData));
            setIsAllExpanded(true);
        }
    };

    const treeData: DataNode[] = useMemo(() => {
        const mapToTree = (items: Organization[], parentMatched = false): DataNode[] => {
            if (!items) return [];
            return items
                .map((item) => {
                    const isMatched = !orgSearchValue || item.name.toLowerCase().includes(orgSearchValue.toLowerCase());
                    const childrenNodes = item.children ? mapToTree(item.children, parentMatched || isMatched) : [];

                    if (!parentMatched && !isMatched && childrenNodes.length === 0) return null;

                    return {
                        key: String(item.id),
                        title: item.is_active ? (
                            item.name
                        ) : (
                            <span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>
                                {item.name}
                            </span>
                        ),
                        icon: <ClusterOutlined />,
                        children: childrenNodes,
                    } as DataNode;
                })
                .filter((node): node is DataNode => node !== null);
        };
        return [
            {
                key: "root",
                title: t("user.root_org"),
                icon: <ApartmentOutlined />,
                children: mapToTree(orgData),
            },
        ];
    }, [orgData, orgSearchValue, token, t]);

    useEffect(() => {
        if (orgData.length > 0 && isInitialLoad) {
            setExpandedKeys(getAllKeys(orgData));
            setIsInitialLoad(false);
        }
    }, [orgData, isInitialLoad, getAllKeys]);

    return (
        <ProCard
            title={t("org.tree_title")}
            bordered={false}
            extra={
                <Space size={2}>
                    <Tooltip title={isAllExpanded ? t("common.collapse_all") : t("common.expand_all")}>
                        <Button
                            type="text"
                            size="small"
                            icon={isAllExpanded ? <CompressOutlined /> : <ExpandOutlined />}
                            onClick={toggleExpandAll}
                        />
                    </Tooltip>
                    <Button
                        type="text"
                        size="small"
                        icon={
                            <FilterOutlined
                                style={{ color: showOrgFilter ? token.colorPrimary : undefined }}
                            />
                        }
                        onClick={() => setShowOrgFilter(!showOrgFilter)}
                    />
                    <Button
                        type="text"
                        size="small"
                        icon={<ReloadOutlined />}
                        onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })}
                        loading={isFetching}
                    />
                </Space>
            }
        >
            {showOrgFilter && (
                <div
                    style={{
                        padding: "12px 20px",
                        background: token.colorFillAlter,
                        borderBottom: `1px solid ${token.colorBorderSecondary}`,
                    }}
                >
                    <Input.Search
                        placeholder={t("user.search_placeholder")}
                        size="small"
                        allowClear
                        onChange={(e) => setOrgSearchValue(e.target.value)}
                        style={{ marginBottom: 4 }}
                    />
                    <div
                        style={{
                            display: "flex",
                            justifyContent: "space-between",
                            alignItems: "center",
                        }}
                    >
                        <span style={{ fontSize: "11px", color: token.colorTextSecondary }}>
                            {t("user.include_inactive_org")}
                        </span>
                        <Switch size="small" checked={showInactive} onChange={onShowInactiveChange} />
                    </div>
                </div>
            )}
            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                <Tree
                    showIcon
                    blockNode
                    showLine={{ showLeafIcon: false }}
                    treeData={treeData}
                    expandedKeys={expandedKeys}
                    onExpand={(keys) => {
                        setExpandedKeys(keys);
                        setIsAllExpanded(keys.length > 1);
                    }}
                    selectedKeys={[String(selectedKey)]}
                    onSelect={(keys) => {
                        if (keys.length > 0) onSelect(keys[0]);
                    }}
                />
            </div>
        </ProCard>
    );
};

export default OrgTree;
