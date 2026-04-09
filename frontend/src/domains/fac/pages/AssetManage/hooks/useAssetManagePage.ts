import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App } from "antd";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import {
    createFacilityApi,
    createSpaceApi,
    deleteFacilityApi,
    deleteSpaceApi,
    getFacilitiesApi,
    getSpaceTreeApi,
    updateFacilityApi,
    updateSpaceApi,
} from "@/domains/fac/api";
import type { Facility, FacilityParams, Space, SpaceParams } from "@/domains/fac/types";

export const useAssetManagePage = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();

    // 상태 관리
    const [selectedNode, setSelectedNode] = useState<{ type: "FAC" | "SPC"; id: number } | null>(null);
    const [drawerOpen, setGroupDrawerOpen] = useState(false);
    const [editingNode, setEditingNode] = useState<{ type: "FAC" | "SPC"; data: Facility | Space | null } | null>(null);

    // 데이터 조회
    const { data: facilities, isFetching: isFacLoading } = useQuery({
        queryKey: ["facilities"],
        queryFn: getFacilitiesApi,
    });

    const { data: spaceTree, isFetching: isSpaceLoading } = useQuery({
        queryKey: ["spaces", selectedNode?.type === "FAC" ? selectedNode.id : null],
        queryFn: () => {
            if (!selectedNode?.id) throw new Error("No node selected");
            return getSpaceTreeApi(selectedNode.id);
        },
        enabled: selectedNode?.type === "FAC",
    });

    // 뮤테이션
    const saveMutation = useMutation({
        mutationFn: async (values: FacilityParams | SpaceParams) => {
            if (editingNode?.data?.id) {
                return editingNode.type === "FAC"
                    ? await updateFacilityApi(editingNode.data.id, values as FacilityParams)
                    : await updateSpaceApi(editingNode.data.id, values as SpaceParams);
            }
            return editingNode?.type === "FAC"
                ? await createFacilityApi(values as FacilityParams)
                : await createSpaceApi(values as SpaceParams);
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setGroupDrawerOpen(false);
            queryClient.invalidateQueries({ queryKey: ["facilities"] });
            if (selectedNode?.type === "FAC") {
                queryClient.invalidateQueries({ queryKey: ["spaces", selectedNode.id] });
            }
        },
    });

    const deleteMutation = useMutation({
        mutationFn: (node: { type: "FAC" | "SPC"; id: number }) =>
            node.type === "FAC" ? deleteFacilityApi(node.id) : deleteSpaceApi(node.id),
        onSuccess: () => {
            message.success(t("common.delete_success"));
            setSelectedNode(null);
            queryClient.invalidateQueries({ queryKey: ["facilities"] });
        },
    });

    const handleAddFacility = () => {
        setEditingNode({ type: "FAC", data: null });
        setGroupDrawerOpen(true);
    };

    const handleEditNode = () => {
        if (!selectedNode) return;
        setEditingNode({ type: selectedNode.type, data: null });
        setGroupDrawerOpen(true);
    };

    return {
        // State
        selectedNode,
        setSelectedNode,
        drawerOpen,
        setGroupDrawerOpen,
        editingNode,

        // Data
        facilities: facilities?.data || [],
        spaceTree: spaceTree?.data || [],
        isLoading: isFacLoading || isSpaceLoading,

        // Actions
        handleAddFacility,
        handleEditNode,
        deleteNode: (node: { type: "FAC" | "SPC"; id: number }) => deleteMutation.mutate(node),
        onSaveFinish: async (v: FacilityParams | SpaceParams) => {
            await saveMutation.mutateAsync(v);
            return true;
        },
    };
};
