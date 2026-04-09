import { useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import type { AuditLog } from "@/domains/sys/types";
import type { AuditLogFilters } from "../components/AuditLogFilter";

export const useAuditLogPage = () => {
    const queryClient = useQueryClient();

    const [pageSize, setPageSize] = useState(10);
    const [showFilter, setShowFilter] = useState(false);
    const [selectedLog, setSelectedLog] = useState<AuditLog | null>(null);
    const [modalVisible, setModalVisible] = useState(false);
    const [filters, setFilters] = useState<AuditLogFilters>({});

    const handleViewDetail = (record: AuditLog) => {
        setSelectedLog(record);
        setModalVisible(true);
    };

    const handleReload = () => {
        queryClient.invalidateQueries({ queryKey: ["audit-logs"] });
    };

    return {
        // State
        pageSize,
        setPageSize,
        showFilter,
        setShowFilter,
        selectedLog,
        modalVisible,
        setModalVisible,
        filters,
        setFilters,
        
        // Actions
        handleViewDetail,
        handleReload,
    };
};
