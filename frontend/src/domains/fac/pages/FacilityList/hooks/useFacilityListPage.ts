import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App } from "antd";
import type { AxiosError } from "axios";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { createFacilityApi, getFacilitiesApi, updateFacilityApi } from "@/domains/fac/api";
import type { Facility, FacilityParams } from "@/domains/fac/types";

interface ApiErrorResponse {
    message?: string;
}

export const useFacilityListPage = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();

    const [showFilter, setShowFilter] = useState(false);
    const [pageSize, setPageSize] = useState(10);
    const [searchText, setSearchValue] = useState("");
    const [showInactive, setShowInactive] = useState(false);
    const [drawerOpen, setDrawerOpen] = useState(false);
    const [editingFacility, setEditingFacility] = useState<Facility | null>(null);

    const { data: facilities, isFetching } = useQuery({
        queryKey: ["facilities", showInactive],
        queryFn: getFacilitiesApi,
    });

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

    const handleAdd = () => {
        setEditingFacility(null);
        setDrawerOpen(true);
    };

    const handleEdit = (record: Facility) => {
        setEditingFacility(record);
        setDrawerOpen(true);
    };

    return {
        // State
        showFilter,
        setShowFilter,
        pageSize,
        setPageSize,
        searchText,
        setSearchValue,
        showInactive,
        setShowInactive,
        drawerOpen,
        setDrawerOpen,
        editingFacility,
        
        // Data
        filteredData,
        isFetching,
        
        // Actions
        handleAdd,
        handleEdit,
        onSaveFinish: async (values: FacilityParams) => {
            await saveMutation.mutateAsync(values);
            return true;
        },
        reload: () => queryClient.invalidateQueries({ queryKey: ["facilities"] }),
    };
};
