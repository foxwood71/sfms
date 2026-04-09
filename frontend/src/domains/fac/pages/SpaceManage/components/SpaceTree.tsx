import {
    ApartmentOutlined,
    ClusterOutlined,
    FilterOutlined,
    PlusOutlined,
    ReloadOutlined,
} from "@ant-design/icons";
import { ProCard } from "@ant-design/pro-components";
import { useQueryClient } from "@tanstack/react-query";
import { Button, Input, Space, Tooltip, Tree, theme } from "antd";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Space as SpaceType } from "@/domains/fac/types";

interface SpaceTreeNode extends DataNode {
    id: number;
    facility_id: number;
}

interface SpaceTreeProps {
    facilityId: number | null;
    rootTitle: string;
    spaceData: SpaceType[];
    isFetching: boolean;
    selectedKey: React.Key | null;
    onSelect: (key: React.Key | null) => void;
    onAddSpace: () => void;
    onAddSubSpace: (parentSpace: SpaceType) => void;
}

const SpaceTree: React.FC<SpaceTreeProps> = ({
    facilityId,
    rootTitle,
    spaceData,
    isFetching,
    selectedKey,
    onSelect,
    onAddSpace,
    onAddSubSpace,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const queryClient = useQueryClient();

    const [showFilter, setShowFilter] = useState(false);
    const [searchValue, setSearchValue] = useState("");

    const treeData = useMemo(() => {
        const mapNodes = (items: SpaceType[]): SpaceTreeNode[] => {
            return items
                .map((item) => {
                    const children = item.children ? mapNodes(item.children) : [];
                    const isMatched = item.name
                        .toLowerCase()
                        .includes(searchValue.toLowerCase());
                    if (searchValue && !isMatched && children.length === 0) return null;

                    return {
                        key: item.id,
                        id: item.id,
                        facility_id: item.facility_id,
                        title: item.is_active ? (
                            item.name
                        ) : (
                            <span
                                style={{
                                    color: token.colorTextDisabled,
                                    textDecoration: "line-through",
                                }}
                            >
                                {item.name}
                            </span>
                        ),
                        icon: <ClusterOutlined />,
                        children,
                    } as SpaceTreeNode;
                })
                .filter((node): node is SpaceTreeNode => node !== null);
        };

        return [
            {
                key: "root",
                title: rootTitle,
                icon: <ApartmentOutlined />,
                children: mapNodes(spaceData),
            },
        ];
    }, [spaceData, rootTitle, searchValue, token]);

    const selectedSpace = useMemo(() => {
        if (!selectedKey || selectedKey === "root") return null;
        const findInTree = (items: SpaceType[]): SpaceType | null => {
            for (const item of items) {
                if (item.id === Number(selectedKey)) return item;
                if (item.children) {
                    const found = findInTree(item.children);
                    if (found) return found;
                }
            }
            return null;
        };
        return findInTree(spaceData);
    }, [selectedKey, spaceData]);

    if (!facilityId) return null;

    return (
        <ProCard
            title={t("fac.space.tree_title")}
            headerBordered
            extra={
                <Space size={2}>
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
                            onClick={() =>
                                queryClient.invalidateQueries({
                                    queryKey: ["spaces", "tree", facilityId],
                                })
                            }
                            loading={isFetching}
                        />
                    </Tooltip>
                    <Tooltip title={t("common.add")}>
                        <Button
                            type="primary"
                            size="small"
                            icon={<PlusOutlined />}
                            onClick={onAddSpace}
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
                }}
            >
                {showFilter && (
                    <div
                        style={{
                            padding: "12px",
                            background: token.colorFillAlter,
                            marginBottom: 12,
                            borderRadius: token.borderRadiusLG,
                            margin: "0 16px 8px 16px",
                        }}
                    >
                        <Input.Search
                            placeholder="공간명 검색..."
                            size="small"
                            allowClear
                            onChange={(e) => setSearchValue(e.target.value)}
                        />
                    </div>
                )}
                <div style={{ flex: 1, overflowY: "auto", padding: "0 16px" }}>
                    <Tree
                        showLine
                        showIcon
                        blockNode
                        defaultExpandAll
                        treeData={treeData}
                        selectedKeys={selectedKey ? [selectedKey] : []}
                        onSelect={(keys) => {
                            if (keys.length > 0) onSelect(keys[0]);
                        }}
                    />
                </div>
                {selectedSpace && (
                    <div
                        style={{
                            padding: "12px 16px",
                            borderTop: `1px solid ${token.colorBorderSecondary}`,
                            background: token.colorBgLayout,
                        }}
                    >
                        <Button
                            type="dashed"
                            block
                            icon={<PlusOutlined />}
                            onClick={() => onAddSubSpace(selectedSpace)}
                        >
                            {selectedSpace.name} {t("fac.space.add_sub")}
                        </Button>
                    </div>
                )}
            </div>
        </ProCard>
    );
};

export default SpaceTree;
