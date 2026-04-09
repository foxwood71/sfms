import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { App } from "antd";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import {
	createCodeDetail,
	getCodeGroups,
	updateCodeDetail,
} from "@/domains/cmm/api";
import type { CodeDetail, CodeGroup } from "@/domains/cmm/types";

export const useCodeManagePage = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();

	const [selectedGroup, setSelectedGroup] = useState<CodeGroup | null>(null);
	const [groupDrawerOpen, setGroupDrawerOpen] = useState(false);
	const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
	const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
	const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

	const { data: groups, isFetching: isGroupsLoading } = useQuery({
		queryKey: ["codeGroups"],
		queryFn: async () => {
			const response = await getCodeGroups(true);
			return response?.data || [];
		},
	});

	const detailMutation = useMutation<unknown, Error, Partial<CodeDetail>>({
		mutationFn: (values: Partial<CodeDetail>) => {
			if (!selectedGroup) throw new Error("No code group selected");
			return editingDetail
				? updateCodeDetail(
						selectedGroup.group_code,
						editingDetail.detail_code,
						values,
					)
				: createCodeDetail({ ...values, group_code: selectedGroup.group_code });
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setDetailDrawerOpen(false);
			queryClient.invalidateQueries({
				queryKey: ["codeDetails", selectedGroup?.group_code],
			});
		},
	});

	const handleAddGroup = () => {
		setEditingGroup(null);
		setGroupDrawerOpen(true);
	};

	const handleEditGroup = () => {
		setEditingGroup(selectedGroup);
		setGroupDrawerOpen(true);
	};

	const handleAddDetail = () => {
		setEditingDetail(null);
		setDetailDrawerOpen(true);
	};

	const handleEditDetail = (record: CodeDetail) => {
		setEditingDetail(record);
		setDetailDrawerOpen(true);
	};

	return {
		// State
		selectedGroup,
		setSelectedGroup,
		groupDrawerOpen,
		setGroupDrawerOpen,
		detailDrawerOpen,
		setDetailDrawerOpen,
		editingGroup,
		editingDetail,

		// Data
		groups: groups || [],
		isGroupsLoading,

		// Actions
		handleAddGroup,
		handleEditGroup,
		handleAddDetail,
		handleEditDetail,
		onDetailSaveFinish: async (v: Partial<CodeDetail>) => {
			await detailMutation.mutateAsync(v);
			return true;
		},
		invalidateGroups: async () => {
			queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
			return true;
		},
	};
};
