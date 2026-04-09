import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App } from "antd";
import type { AxiosError } from "axios";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { APIErrorResponse } from "@/shared/api/types";
import { createUserApi, getOrganizationsApi, updateUserApi } from "@/domains/usr/api";
import type { CreateUserParams, UpdateUserParams, User, UserFormValues } from "@/domains/usr/types";

export const useUserListPage = () => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();

    const [drawerVisible, setDrawerVisible] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [selectedKey, setSelectedKey] = useState<React.Key>("root");
    const [showInactiveOrg, setShowInactiveOrg] = useState(false);

    // 데이터 조회
    const { data: orgResponse, isFetching: isOrgFetching } = useQuery({
        queryKey: ["organizations", "tree", showInactiveOrg],
        queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
    });

    const saveMutation = useMutation({
        mutationFn: (values: UserFormValues) => {
            const { pos, duty, role_ids, ...rest } = values;
            
            if (editingUser) {
                const payload: UpdateUserParams = {
                    ...rest,
                    role_ids,
                    metadata: { 
                        ...(editingUser.metadata as Record<string, any> || {}), 
                        pos, 
                        duty 
                    },
                };
                return updateUserApi(editingUser.id, payload);
            }
            
            const payload: CreateUserParams = {
                ...rest,
                role_ids,
                metadata: { pos, duty },
            };
            return createUserApi(payload);
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            setDrawerVisible(false);
            queryClient.invalidateQueries({ queryKey: ["users"] });
        },
        onError: (err: AxiosError<APIErrorResponse>) =>
            message.error(err.response?.data?.message || t("common.save_failure")),
    });

    const handleAddUser = () => {
        setEditingUser(null);
        setDrawerVisible(true);
    };

    const handleViewUser = (user: User) => {
        setEditingUser(user);
        setDrawerVisible(true);
    };

    return {
        // State
        drawerVisible,
        setDrawerVisible,
        editingUser,
        selectedKey,
        setSelectedKey,
        showInactiveOrg,
        setShowInactiveOrg,
        
        // Data
        orgData: orgResponse?.data || [],
        isOrgFetching,
        
        // Actions
        handleAddUser,
        handleViewUser,
        onSaveFinish: async (values: UserFormValues) => {
            await saveMutation.mutateAsync(values);
            return true;
        },
    };
};
