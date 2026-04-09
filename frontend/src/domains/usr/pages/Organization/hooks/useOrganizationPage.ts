import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useCallback, useMemo, useState } from "react";
import { getOrganizationsApi } from "@/domains/usr/api";
import type { Organization, User } from "@/domains/usr/types";

export const useOrganizationPage = () => {
    const queryClient = useQueryClient();

    // --- 상태 관리 ---
    const [selectedKey, setSelectedKey] = useState<React.Key>("root");
    const [activeTab, setActiveTab] = useState<string>("suborgs");
    const [showInactiveOrg, setShowInactiveOrg] = useState(false);

    const [orgDrawerOpen, setOrgDrawerOpen] = useState(false);
    const [isOrgAdding, setIsOrgAdding] = useState(false);
    const [userDrawerOpen, setUserDrawerOpen] = useState(false);
    const [editingUser, setEditingUser] = useState<User | null>(null);
    const [editingOrg, setEditingOrg] = useState<Organization | null>(null);

    // --- 데이터 조회 ---
    const { data: orgResponse, isFetching: isOrgFetching } = useQuery({
        queryKey: ["organizations", "tree", showInactiveOrg],
        queryFn: () => getOrganizationsApi("tree", showInactiveOrg ? undefined : true),
    });

    const findOrgInTree = useCallback((items: Organization[], idStr: string): Organization | null => {
        for (const item of items) {
            if (String(item.id) === idStr) return item;
            if (item.children) {
                const found = findOrgInTree(item.children, idStr);
                if (found) return found;
            }
        }
        return null;
    }, []);

    const selectedOrg = useMemo(() => {
        if (!selectedKey || selectedKey === "root" || !orgResponse?.data) return null;
        return findOrgInTree(orgResponse.data, String(selectedKey));
    }, [selectedKey, orgResponse, findOrgInTree]);

    const subOrgData = useMemo(() => {
        if (!orgResponse?.data) return [];
        if (selectedKey === "root") return orgResponse.data;
        return selectedOrg?.children || [];
    }, [orgResponse, selectedKey, selectedOrg]);

    const handleEditOrg = (record: Organization) => {
        setEditingOrg(record);
        setIsOrgAdding(false);
        setOrgDrawerOpen(true);
    };

    const handleAddOrg = () => {
        setIsOrgAdding(true);
        setOrgDrawerOpen(true);
        setEditingOrg(null);
    };

    const handleViewUser = (user: User) => {
        setEditingUser(user);
        setUserDrawerOpen(true);
    };

    const handleAddUser = () => {
        setEditingUser(null);
        setUserDrawerOpen(true);
    };

    return {
        // State
        selectedKey,
        setSelectedKey,
        activeTab,
        setActiveTab,
        showInactiveOrg,
        setShowInactiveOrg,
        orgDrawerOpen,
        setOrgDrawerOpen,
        isOrgAdding,
        userDrawerOpen,
        setUserDrawerOpen,
        editingUser,
        editingOrg,
        
        // Data
        orgData: orgResponse?.data || [],
        isOrgFetching,
        subOrgData,
        selectedOrg,
        
        // Actions
        handleEditOrg,
        handleAddOrg,
        handleViewUser,
        handleAddUser,
        invalidateUsers: () => queryClient.invalidateQueries({ queryKey: ["users"] }),
    };
};
