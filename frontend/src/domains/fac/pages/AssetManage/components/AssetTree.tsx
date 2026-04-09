import {
    BankOutlined,
    ClusterOutlined,
    FilterOutlined,
    PlusOutlined,
    ReloadOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { useQueryClient } from "@tanstack/react-query";
import { Button, Space, Tree } from "antd";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Facility, Space as SpaceType } from "@/domains/fac/types";

export interface AssetTreeNode {
    key: string;
    title: string;
    icon: React.ReactNode;
    type: "FAC" | "SPC";
    id: number;
    data: Facility | SpaceType;
    children?: AssetTreeNode[];
}

interface AssetTreeProps {
    facilities: Facility[];
    spaceTree: SpaceType[];
    selectedNodeId: number | null;
    selectedNodeType: "FAC" | "SPC" | null;
    isFetching: boolean;
    onSelect: (node: { type: "FAC" | "SPC"; id: number }) => void;
    onAddFacility: () => void;
}

const AssetTree: React.FC<AssetTreeProps> = ({
    facilities,
    spaceTree,
    selectedNodeId,
    selectedNodeType,
    isFetching,
    onSelect,
    onAddFacility,
}) => {
    const { t } = useTranslation();
    const queryClient = useQueryClient();
    const [showFilter, setShowFilter] = useState(false);

    const treeData = useMemo((): AssetTreeNode[] => {
        if (!facilities) return [];
        return facilities.map((fac: Facility) => ({
            key: `FAC-${fac.id}`,
            title: fac.name,
            icon: <BankOutlined />,
            type: "FAC",
            id: fac.id,
            data: fac,
            children:
                selectedNodeId === fac.id && selectedNodeType === "FAC" && spaceTree
                    ? spaceTree.map((s: SpaceType) => ({
                        key: `SPC-${s.id}`,
                        title: s.name,
                        icon: <ClusterOutlined />,
                        type: "SPC",
                        id: s.id,
                        data: s,
                    }))
                    : [],
        }));
    }, [facilities, spaceTree, selectedNodeId, selectedNodeType]);

    return (
        <ProCard
            title={t("fac.manage.tree_title")}
            bordered={false}
            extra={
                <Space size={4}>
                    <Button
                        type="text"
                        size="small"
                        icon={<FilterOutlined />}
                        onClick={() => setShowFilter(!showFilter)}
                    />
                    <Button
                        type="text"
                        size="small"
                        icon={<ReloadOutlined />}
                        onClick={() => queryClient.invalidateQueries({ queryKey: ["facilities"] })}
                        loading={isFetching}
                    />
                    <Button
                        type="primary"
                        size="small"
                        icon={<PlusOutlined />}
                        onClick={onAddFacility}
                    >
                        {t("common.create")}
                    </Button>
                </Space>
            }
        >
            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                <Tree
                    showIcon
                    blockNode
                    treeData={treeData}
                    onSelect={(_, info) => {
                        if (info.selected) {
                            const node = info.node as unknown as AssetTreeNode;
                            if (node.type && node.id) {
                                onSelect({ type: node.type, id: node.id });
                            }
                        }
                    }}
                />
            </div>
        </ProCard>
    );
};

export default AssetTree;
