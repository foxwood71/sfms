import { DeleteOutlined, EditOutlined, FilterOutlined, PlusOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import {
	PageContainer,
	ProCard,
	ProTable,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	Button,
	message,
	Popconfirm,
	Space,
	Splitter,
	Switch,
	Tag,
	Typography,
	theme,
} from "antd";
import axios from "axios";
import type React from "react";
import { useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import {
	createCodeDetail,
	createCodeGroup,
	deleteCodeDetail,
	deleteCodeGroup,
	getAllCodeDetails, // 추가
	getCodeDetails,
	getCodeGroups,
	updateCodeDetail,
	updateCodeGroup,
} from "../api";
import type { CodeDetail, CodeGroup } from "../types";
import CodeGroupDrawer from "../components/CodeGroupDrawer";
import CodeDetailDrawer from "../components/CodeDetailDrawer";
import ExcelActions from "@/shared/components/ExcelActions";
import type { ExcelColumnMapping } from "@/shared/utils/excel";

/**
 * 공통 코드 관리 페이지
 * Bento Standard v1.0 + Drawer 기반
 */
const CodeManagePage: React.FC = () => {
	const { t } = useTranslation();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	// 엑셀 매핑 정의
	const groupExcelColumns: ExcelColumnMapping[] = [
		{ dataIndex: "group_code", title: "그룹 코드" },
		{ dataIndex: "group_name", title: "그룹명" },
		{ dataIndex: "description", title: "설명" },
		{ dataIndex: "is_active", title: "사용여부" },
	];

	const detailExcelColumns: ExcelColumnMapping[] = [
		{ dataIndex: "group_code", title: "그룹 코드" },
		{ dataIndex: "detail_code", title: "상세 코드" },
		{ dataIndex: "detail_name", title: "코드명" },
		{ dataIndex: "sort_order", title: "정렬순서" },
		{ dataIndex: "is_active", title: "사용여부" },
	];

	// 상태 관리
	const [selectedGroup, setSelectedGroup] = useState<CodeGroup | null>(null);
	const [showInactiveGroup, setShowInactiveGroup] = useState(true);
	const [showInactiveDetail, setShowInactiveDetail] = useState(true);
	const [showGroupFilter, setShowGroupFilter] = useState(false);
	const [showDetailFilter, setShowDetailFilter] = useState(false);

	// 드로어 상태
	const [groupDrawerOpen, setGroupDrawerOpen] = useState(false);
	const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
	const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
	const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

	// Splitter 초기 크기 결정 (localStorage)
	const initialSplitterSize = useMemo(() => {
		const saved = localStorage.getItem("sfms_cmm_splitter_size");
		return saved && !isNaN(Number(saved)) ? Number(saved) : "35%";
	}, []);

	const handleSplitterChange = (sizes: number[]) => {
		if (sizes.length > 0) {
			localStorage.setItem("sfms_cmm_splitter_size", String(sizes[0]));
		}
	};

	// [공통 에러 핸들러]
	const handleAxiosError = (error: unknown, prefix: string) => {
		let detail = t("common.unknown_error");
		if (axios.isAxiosError(error)) {
			detail = error.response?.data?.message || error.message;
		}
		message.error(`${prefix}: ${detail}`);
	};

	// 1. 데이터 조회
	const { data: groupResponse, isLoading: isGroupLoading } = useQuery({
		queryKey: ["codeGroups"],
		queryFn: () => getCodeGroups(),
	});

	// 전체 상세 코드 조회 (엑셀용)
	const { data: allDetailsResponse } = useQuery({
		queryKey: ["codeDetails", "all"],
		queryFn: () => getAllCodeDetails(),
		initialData: [],
	});

	const filteredGroups = useMemo(() => {
		const allGroups = [...(groupResponse?.data || [])].sort((a, b) =>
			a.group_code.localeCompare(b.group_code),
		);
		return showInactiveGroup ? allGroups : allGroups.filter((g) => g.is_active);
	}, [groupResponse, showInactiveGroup]);

	const { data: rawDetails, isLoading: isDetailLoading } = useQuery({
		queryKey: ["codeDetails", selectedGroup?.group_code],
		queryFn: () => {
			if (!selectedGroup) return [];
			return getCodeDetails(selectedGroup.group_code);
		},
		enabled: !!selectedGroup,
	});

	const filteredDetails = useMemo(() => {
		if (!rawDetails) return [];
		const sorted = [...rawDetails].sort(
			(a, b) =>
				(a.sort_order || 0) - (b.sort_order || 0) ||
				a.detail_code.localeCompare(b.detail_code),
		);
		return showInactiveDetail ? sorted : sorted.filter((d) => d.is_active);
	}, [rawDetails, showInactiveDetail]);

	// 2. 뮤테이션
	const groupMutation = useMutation({
		mutationFn: (data: Partial<CodeGroup>) => {
			const formattedData = { ...data, group_code: data.group_code?.toUpperCase() };
			return editingGroup
				? updateCodeGroup(editingGroup.group_code, formattedData)
				: createCodeGroup(formattedData as CodeGroup);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setGroupDrawerOpen(false);
			queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
		},
		onError: (err) => handleAxiosError(err, t("common.save_failure")),
	});

	const detailMutation = useMutation({
		mutationFn: (data: Partial<CodeDetail>) => {
			if (!selectedGroup) throw new Error("그룹 코드가 누락되었습니다.");
			const formattedData = {
				...data,
				detail_code: data.detail_code?.toUpperCase(),
				group_code: selectedGroup.group_code,
			};
			return editingDetail
				? updateCodeDetail(selectedGroup.group_code, editingDetail.detail_code, formattedData)
				: createCodeDetail(formattedData as CodeDetail);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setDetailDrawerOpen(false);
			queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup?.group_code] });
		},
		onError: (err) => handleAxiosError(err, t("common.save_failure")),
	});

	// 3. 삭제 처리
	const onDeleteGroup = async (code: string) => {
		try {
			await deleteCodeGroup(code);
			message.success(t("common.delete_success"));
			if (selectedGroup?.group_code === code) setSelectedGroup(null);
			queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
		} catch (err) { handleAxiosError(err, t("common.delete_failure")); }
	};

	const onDeleteDetail = async (detailCode: string) => {
		if (!selectedGroup) return;
		try {
			await deleteCodeDetail(selectedGroup.group_code, detailCode);
			message.success(t("common.delete_success"));
			queryClient.invalidateQueries({ queryKey: ["codeDetails", selectedGroup.group_code] });
		} catch (err) { handleAxiosError(err, t("common.delete_failure")); }
	};

	// 4. 컬럼 정의
	const groupColumns: ProColumns<CodeGroup>[] = [
		{ title: "그룹 코드", dataIndex: "group_code", width: 140 },
		{ title: "그룹명", dataIndex: "group_name", ellipsis: true },
		{
			title: "상태",
			dataIndex: "is_active",
			width: 60,
			align: "center",
			render: (val) => <Tag color={val ? "green" : "red"}>{val ? "사용" : "중지"}</Tag>,
		},
		{
			title: "작업",
			width: 70,
			align: "center",
			render: (_, record) => (
				<Space size={0}>
					<EditOutlined
						onClick={(e) => { e.stopPropagation(); setEditingGroup(record); setGroupDrawerOpen(true); }}
						style={{ padding: 4, cursor: "pointer", color: token.colorPrimary }}
					/>
					<Popconfirm title={t("common.delete_confirm_msg")} onConfirm={() => onDeleteGroup(record.group_code)}>
						<DeleteOutlined style={{ padding: 4, color: token.colorError, cursor: "pointer" }} />
					</Popconfirm>
				</Space>
			),
		},
	];

	const detailColumns: ProColumns<CodeDetail>[] = [
		{ title: "상세 코드", dataIndex: "detail_code", width: 150 },
		{ title: "코드명", dataIndex: "detail_name" },
		{ title: "정렬", dataIndex: "sort_order", width: 60, align: "center" },
		{
			title: "상태",
			dataIndex: "is_active",
			width: 60,
			render: (val) => <Tag color={val ? "green" : "red"}>{val ? "사용" : "중지"}</Tag>,
		},
		{
			title: "작업",
			width: 70,
			align: "center",
			render: (_, record) => (
				<Space size={0}>
					<EditOutlined
						onClick={() => { setEditingDetail(record); setDetailDrawerOpen(true); }}
						style={{ padding: 4, cursor: "pointer", color: token.colorPrimary }}
					/>
					<Popconfirm title={t("common.delete_confirm_msg")} onConfirm={() => onDeleteDetail(record.detail_code)}>
						<DeleteOutlined style={{ padding: 4, color: token.colorError, cursor: "pointer" }} />
					</Popconfirm>
				</Space>
			),
		},
	];

	return (
		<PageContainer 
			header={{ 
				title: t("menu.cmm-codes"),
				extra: [
					<ExcelActions 
						key="excel"
						sheets={[
							{ 
								sheetName: t("common.sheet_name_groups"), 
								data: groupResponse?.data || [], 
								columns: groupExcelColumns 
							},
							{ 
								sheetName: t("common.sheet_name_details"), 
								data: allDetailsResponse || [], 
								columns: detailExcelColumns 
							},
						]}
						columns={detailExcelColumns} 
						fileName={t("common.excel_filename_all_codes")}
						uploadEnabled={!!selectedGroup}
						onImport={(data) => {
							console.log(t("common.excel_import_details"), data);
						}}
					/>
				]
			}}
			childrenContentStyle={{ padding: 0, height: LAYOUT_CONSTANTS.CONTENT_HEIGHT, overflow: "hidden" }}
		>
			<style>{`
				.ant-pro-card-body { 
					overflow: hidden !important; 
					display: flex; 
					flex-direction: column; 
					height: 100%; 
					padding: 12px 0 0 0 !important;
				}
				.ant-table-wrapper { height: 100%; display: flex; flex-direction: column; overflow: hidden; }
				.ant-spin-nested-loading, .ant-spin-container, .ant-table { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
				.ant-table-container { flex: 1; display: flex; flex-direction: column; overflow: hidden; }
				.group-table .ant-table-body { flex: 1 !important; overflow-y: ${filteredGroups.length > 10 ? "auto" : "hidden"} !important; }
				.detail-table .ant-table-body { flex: 1 !important; overflow-y: ${filteredDetails.length > 10 ? "auto" : "hidden"} !important; }
				.ant-table-body::-webkit-scrollbar { width: 6px; }
				.ant-table-body::-webkit-scrollbar-thumb { background: transparent; border-radius: 3px; }
				.ant-table-body:hover::-webkit-scrollbar-thumb { background: rgba(0, 0, 0, 0.15); }
			`}</style>

			<Splitter style={{ height: "100%", background: "transparent", gap: 2 }} onResizeEnd={handleSplitterChange}>
				{/* 좌측 패널 */}
				<Splitter.Panel defaultSize={initialSplitterSize} min="20%" max="50%">
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard
							title="코드 그룹"
							headerBordered
							headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
							extra={
								<Space>
									<Button type="text" icon={<FilterOutlined style={{ color: showGroupFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowGroupFilter(!showGroupFilter)} />
									<Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => { setEditingGroup(null); setGroupDrawerOpen(true); }}>{t("common.create")}</Button>
								</Space>
							}
						>
							{showGroupFilter && (
								<div style={{ padding: "8px 16px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}`, borderRadius: 8, margin: "0 16px 8px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
									<Typography.Text size="small" type="secondary">{t("org.include_inactive")}</Typography.Text>
									<Switch size="small" checked={showInactiveGroup} onChange={setShowInactiveGroup} />
								</div>
							)}
							<div className="group-table" style={{ flex: 1, overflow: "hidden", padding: "0 16px" }}>
								<ProTable<CodeGroup>
									size="small"
									rowKey="group_code"
									columns={groupColumns}
									dataSource={filteredGroups}
									loading={isGroupLoading}
									search={false}
									options={false}
									pagination={false}
									scroll={{ y: filteredGroups.length > 10 ? "calc(100vh - 380px)" : undefined }}
									onRow={(record) => ({
										onClick: () => setSelectedGroup(record),
										style: { cursor: "pointer", backgroundColor: selectedGroup?.group_code === record.group_code ? token.controlItemBgActive : "inherit" },
									})}
								/>
							</div>
						</ProCard>
					</div>
				</Splitter.Panel>

				{/* 우측 패널 */}
				<Splitter.Panel>
					<div style={{ height: "100%", background: token.colorBgContainer, borderRadius: 12, overflow: "hidden" }}>
						<ProCard
							title={selectedGroup ? `[${selectedGroup.group_name}] 상세 코드` : "상세 코드"}
							headerBordered
							headStyle={{ height: LAYOUT_CONSTANTS.HEADER_HEIGHT }}
							extra={
								selectedGroup && (
									<Space>
										<Button type="text" icon={<FilterOutlined style={{ color: showDetailFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowDetailFilter(!showDetailFilter)} />
										<Button type="primary" size="small" icon={<PlusOutlined />} onClick={() => { setEditingDetail(null); setDetailDrawerOpen(true); }}>{t("common.create")}</Button>
									</Space>
								)
							}
						>
							{selectedGroup ? (
								<div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
									{showDetailFilter && (
										<div style={{ padding: "8px 16px", background: token.colorFillAlter, borderBottom: `1px solid ${token.colorBorderSecondary}`, borderRadius: 8, margin: "0 16px 8px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
											<Typography.Text size="small" type="secondary">{t("org.include_inactive")}</Typography.Text>
											<Switch size="small" checked={showInactiveDetail} onChange={setShowInactiveDetail} />
										</div>
									)}
									<div className="detail-table" style={{ flex: 1, overflow: "hidden", padding: "0 16px" }}>
										<ProTable<CodeDetail>
											size="small"
											rowKey="detail_code"
											columns={detailColumns}
											dataSource={filteredDetails}
											loading={isDetailLoading}
											search={false}
											options={false}
											pagination={false}
											scroll={{ y: filteredDetails.length > 10 ? "calc(100vh - 380px)" : undefined }}
										/>
									</div>
								</div>
							) : (
								<div style={{ flex: 1, display: "flex", justifyContent: "center", alignItems: "center", color: token.colorTextDisabled, height: "100%" }}>
									{t("common.select_placeholder")}
								</div>
							)}
						</ProCard>
					</div>
				</Splitter.Panel>
			</Splitter>

			{/* 드로어 컴포넌트 연결 */}
			<CodeGroupDrawer 
				open={groupDrawerOpen} 
				onOpenChange={setGroupDrawerOpen} 
				editingGroup={editingGroup} 
				onFinish={async (values) => { await groupMutation.mutateAsync(values); return true; }} 
			/>
			<CodeDetailDrawer 
				open={detailDrawerOpen} 
				onOpenChange={setDetailDrawerOpen} 
				editingDetail={editingDetail} 
				groupName={selectedGroup?.group_name || ""} 
				onFinish={async (values) => { await detailMutation.mutateAsync(values); return true; }} 
			/>
		</PageContainer>
	);
};

export default CodeManagePage;
