import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App } from "antd";
import type { AxiosError } from "axios";
import { useCallback, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
    createSpaceApi,
    deleteSpaceApi,
    getFacilitiesApi,
    getSpaceTreeApi,
    updateSpaceApi,
} from "@/domains/fac/api";
import type { SpaceParams, Space as SpaceType } from "@/domains/fac/types";

interface ApiErrorResponse {
    message?: string;
}

export const useSpaceManage = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();

    // 상태 관리
    const [selectedFacilityId, setSelectedFacilityId] = useState<number | null>(null);
    const [selectedKey, setSelectedKey] = useState<React.Key | null>(null);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editingSpace, setEditingSpace] = useState<SpaceType | SpaceParams | null>(null);

    // 시설 목록 조회
    const { data: facilities } = useQuery({
        queryKey: ["facilities"],
        queryFn: getFacilitiesApi,
    });

    // 선택된 시설의 공간 트리 조회
    const { data: spaceRes, isFetching: isTreeLoading } = useQuery({
        queryKey: ["spaces", "tree", selectedFacilityId],
        queryFn: async () => {
            if (!selectedFacilityId) return { data: [], success: true };
            return getSpaceTreeApi(selectedFacilityId);
        },
        enabled: !!selectedFacilityId,
    });

    // 평면 구조 데이터 (선택된 노드 찾기용)
    const flatSpaces = useMemo(() => {
        const flatten = (items: SpaceType[]): SpaceType[] => {
            let result: SpaceType[] = [];
            for (const item of items) {
                result.push(item);
                if (item.children) result = result.concat(flatten(item.children));
            }
            return result;
        };
        return flatten(spaceRes?.data || []);
    }, [spaceRes]);

    const selectedSpace = useMemo(() => {
        if (!selectedKey || selectedKey === "root") return null;
        return flatSpaces.find((s) => s.id === Number(selectedKey)) || null;
    }, [selectedKey, flatSpaces]);

    // 저장 Mutation
    const saveMutation = useMutation({
        mutationFn: (values: SpaceParams) => {
            if (editingSpace && "id" in editingSpace)
                return updateSpaceApi(editingSpace.id, values);
            if (!selectedFacilityId) throw new Error("No facility selected");
            return createSpaceApi({ ...values, facility_id: selectedFacilityId });
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setDrawerOpen(false);
            queryClient.invalidateQueries({ queryKey: ["spaces", "tree", selectedFacilityId] });
        },
        onError: (err: AxiosError<ApiErrorResponse>) => {
            message.error(err.response?.data?.message || t("common.save_failure"));
        },
    });

    // 삭제 Mutation
    const deleteMutation = useMutation({
        mutationFn: (id: number) => deleteSpaceApi(id),
        onSuccess: () => {
            message.success(t("common.delete_success"));
            setSelectedKey(null);
            queryClient.invalidateQueries({ queryKey: ["spaces", "tree", selectedFacilityId] });
        },
        onError: (err: AxiosError<ApiErrorResponse>) => {
            message.error(err.response?.data?.message || t("common.delete_failure"));
        },
    });

    const initialSplitterSize = useMemo(() => {
        const saved = localStorage.getItem("sfms_fac_splitter_size");
        return saved && !Number.isNaN(Number(saved)) ? Number(saved) : "30%";
    }, []);

    const handleSplitterChange = useCallback((sizes: number[]) => {
        if (sizes.length > 0) localStorage.setItem("sfms_fac_splitter_size", String(sizes[0]));
    }, []);

    const handleAddSpace = () => {
        setEditingSpace(null);
        setDrawerOpen(true);
    };

    const handleAddSubSpace = (parentSpace: SpaceType) => {
        setEditingSpace({
            parent_id: parentSpace.id,
            facility_id: parentSpace.facility_id,
        } as SpaceParams);
        setDrawerOpen(true);
    };

    const handleEditSpace = (space: SpaceType) => {
        setEditingSpace(space);
        setDrawerOpen(true);
    };

    return {
        // State
        selectedFacilityId,
        setSelectedFacilityId,
        selectedKey,
        setSelectedKey,
        drawerOpen,
        setDrawerOpen,
        editingSpace,
        
        // Data
        facilities: facilities?.data || [],
        spaceTree: spaceRes?.data || [],
        isTreeLoading,
        selectedSpace,
        initialSplitterSize,
        
        // Actions
        handleSplitterChange,
        handleAddSpace,
        handleAddSubSpace,
        handleEditSpace,
        deleteSpace: (id: number) => deleteMutation.mutate(id),
        isDeleting: deleteMutation.isPending,
        onSaveFinish: async (values: SpaceParams) => {
            await saveMutation.mutateAsync(values);
            return true;
        },
    };
};
