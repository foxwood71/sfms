import { DeleteOutlined, EditOutlined, PlusOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import {
	ModalForm,
	PageContainer,
	ProCard,
	ProFormDigit,
	ProFormSwitch,
	ProFormText,
	ProFormTextArea,
	ProTable,
} from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Button, message, Popconfirm, Space, Tag, theme } from "antd";
import axios from "axios";
import type React from "react";
import { useState } from "react";
import {
	createCodeDetail,
	createCodeGroup,
	deleteCodeDetail,
	deleteCodeGroup,
	getCodeDetails,
	getCodeGroups,
	updateCodeDetail,
	updateCodeGroup,
} from "../api";
import type { CodeDetail, CodeGroup } from "../types";

const CodeManagePage: React.FC = () => {
	
	const maxRowsWithoutScroll = 18; // 스크롤 없이 보여줄 최대 행 수 (그룹)

	const queryClient = useQueryClient();
	const { token } = theme.useToken();

	// 상태 관리
	const [selectedGroup, setSelectedGroup] = useState<string | null>(null);
	const [groupModalVisible, setGroupModalVisible] = useState(false);
	const [detailModalVisible, setDetailModalVisible] = useState(false);
	const [editingGroup, setEditingGroup] = useState<CodeGroup | null>(null);
	const [editingDetail, setEditingDetail] = useState<CodeDetail | null>(null);

	// [🔥 핵심 수정 1] 전체 카드 높이
	// 상단 헤더 공간 등을 고려해 넉넉히 잡습니다.
	const CONTENT_HEIGHT = "calc(100vh - 180px)";

	// [🔥 핵심 수정 2] 테이블 스크롤 높이 (이것이 카드보다 확실히 작아야 함!)
	// 기존 320px -> 420px로 변경하여 220px의 여유 공간을 확보합니다.
	// 이제 툴바, 헤더, 가로 스크롤바가 생겨도 카드를 넘치지 않습니다.
	const TABLE_SCROLL_Y = "calc(100vh - 370px)";

	// 1. 데이터 조회
	const { data: groups, isLoading: isGroupLoading } = useQuery({
		queryKey: ["codeGroups"],
		queryFn: getCodeGroups,
	});

	const { data: details, isLoading: isDetailLoading } = useQuery({
		queryKey: ["codeDetails", selectedGroup],
		queryFn: () => {
			if (!selectedGroup) return [];
			return getCodeDetails(selectedGroup);
		},
		enabled: !!selectedGroup,
	});

	// 2. 에러 핸들러
	const handleAxiosError = (error: unknown, prefix: string) => {
		let detail = "알 수 없는 오류가 발생했습니다.";
		if (axios.isAxiosError(error)) {
			detail = error.response?.data?.detail || error.message;
		} else if (error instanceof Error) {
			detail = error.message;
		}
		message.error(`${prefix}: ${detail}`);
	};

	// 3. 뮤테이션 (저장/수정)
	const groupMutation = useMutation({
		mutationFn: (data: Partial<CodeGroup>) =>
			editingGroup
				? updateCodeGroup(editingGroup.group_code, data)
				: createCodeGroup(data as CodeGroup),
		onSuccess: () => {
			message.success("그룹 정보가 저장되었습니다.");
			setGroupModalVisible(false);
			queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
		},
		onError: (err) => handleAxiosError(err, "그룹 저장 실패"),
	});

	const detailMutation = useMutation({
		mutationFn: (data: Partial<CodeDetail>) => {
			if (!selectedGroup) {
				throw new Error("그룹 코드가 누락되었습니다.");
			}
			return editingDetail
				? updateCodeDetail(selectedGroup, editingDetail.detail_code, data)
				: createCodeDetail({
						...data,
						group_code: selectedGroup,
					} as CodeDetail);
		},
		onSuccess: () => {
			message.success("상세 코드가 저장되었습니다.");
			setDetailModalVisible(false);
			queryClient.invalidateQueries({
				queryKey: ["codeDetails", selectedGroup],
			});
		},
		onError: (err) => handleAxiosError(err, "코드 저장 실패"),
	});

	// 4. 삭제 처리
	const onDeleteGroup = async (code: string) => {
		try {
			await deleteCodeGroup(code);
			message.success("그룹이 삭제되었습니다.");
			if (selectedGroup === code) setSelectedGroup(null);
			queryClient.invalidateQueries({ queryKey: ["codeGroups"] });
		} catch (err) {
			handleAxiosError(err, "그룹 삭제 실패");
		}
	};

	const onDeleteDetail = async (detailCode: string) => {
		if (!selectedGroup) {
			message.error("그룹 정보가 유효하지 않습니다.");
			return;
		}
		try {
			await deleteCodeDetail(selectedGroup, detailCode);
			message.success("코드가 삭제되었습니다.");
			queryClient.invalidateQueries({
				queryKey: ["codeDetails", selectedGroup],
			});
		} catch (err) {
			handleAxiosError(err, "코드 삭제 실패");
		}
	};

	// 5. 컬럼 정의 (너비 넓힌 버전 유지)
	const groupColumns: ProColumns<CodeGroup>[] = [
		{ title: "그룹 코드", dataIndex: "group_code", width: 140, copyable: true },
		{ title: "그룹명", dataIndex: "group_name", ellipsis: true },
		{
			title: "상태",
			dataIndex: "is_active",
			width: 60,
			align: "center",
			render: (val) => (
				<Tag color={val ? "green" : "red"}>{val ? "사용" : "중지"}</Tag>
			),
		},
		{
			title: "작업",
			//valueType: "option",
			fixed: undefined,
			width: 70,
			align: "center",
			render: (_, record) => (
				// Space로 감싸서 줄바꿈 방지
				<Space size={0}>
					<EditOutlined
						key="edit"
						onClick={(e) => {
							e.stopPropagation();
							setEditingGroup(record);
							setGroupModalVisible(true);
						}}
						style={{
							padding: 4,
							cursor: "pointer",
							color: token.colorTextSecondary,
						}}
					/>
					<Popconfirm
						key="del"
						title="삭제?"
						onConfirm={() => onDeleteGroup(record.group_code)}
						okText="예"
						cancelText="아니오"
					>
						<DeleteOutlined
							style={{ padding: 4, color: token.colorError, cursor: "pointer" }}
						/>
					</Popconfirm>
				</Space>
			),
		},
	];

	const detailColumns: ProColumns<CodeDetail>[] = [
		{ title: "상세 코드", dataIndex: "detail_code", width: 180 },
		{ title: "코드명", dataIndex: "detail_name" },
		{ title: "정렬", dataIndex: "sort_order", width: 60, align: "center" },
		{
			title: "상태",
			dataIndex: "is_active",
			width: 60,
			render: (val) => (
				<Tag color={val ? "blue" : "default"}>{val ? "활성" : "비활성"}</Tag>
			),
		},
		{
			title: "작업",
			//valueType: "option",
			fixed: undefined,
			width: 70,
			align: "center",
			render: (_, record) => (
				<Space size={0}>
					<EditOutlined
						key="edit"
						onClick={() => {
							setEditingDetail(record);
							setDetailModalVisible(true);
						}}
						style={{
							padding: 4,
							cursor: "pointer",
							color: token.colorTextSecondary,
						}}
					/>
					<Popconfirm
						key="del"
						title="삭제?"
						onConfirm={() => onDeleteDetail(record.detail_code)}
						okText="예"
						cancelText="아니오"
					>
						<DeleteOutlined
							style={{ padding: 4, color: token.colorError, cursor: "pointer" }}
						/>
					</Popconfirm>
				</Space>
			),
		},
	];

	return (
		<PageContainer
			fixedHeader
			header={{ title: "공통 코드 관리" }}
			// [🔥 핵심 수정 3] 전체 레이아웃 스크롤 방지
			style={{ overflow: "hidden" }}
			token={{
				paddingInlinePageContainerContent: 24,
				paddingBlockPageContainerContent: 0,
			}}
		>
			<ProCard
				ghost
				gutter={16}
				style={{
					height: CONTENT_HEIGHT,
					marginTop: 16,
				}}
			>
				{/* 좌측 패널: 코드 그룹 */}
				<ProCard
					colSpan={10}
					title="코드 그룹"
					headerBordered
					bordered
					boxShadow
					style={{ height: "100%" }}
					// [🔥 핵심 수정 4] 카드 본문 스크롤 방지 (overflow: hidden)
					bodyStyle={{
						padding: 0,
						overflow: "hidden",
						height: "100%",
						display: "flex",
						flexDirection: "column",
					}}
				>
					<ProTable<CodeGroup>
						size="small"
						rowKey="group_code"
						columns={groupColumns}
						dataSource={groups}
						loading={isGroupLoading}
						search={false}
						options={false}
						pagination={false}
						//scroll={{ y: TABLE_SCROLL_Y }}
						{...(groups && groups.length> maxRowsWithoutScroll && {scroll: { y: TABLE_SCROLL_Y }})}  
						toolBarRender={() => [
							<Button
								key="add"
								type="primary"
								size="small"
								icon={<PlusOutlined />}
								onClick={() => {
									setEditingGroup(null);
									setGroupModalVisible(true);
								}}
							>
								추가
							</Button>,
						]}
						onRow={(record) => ({
							onClick: () => setSelectedGroup(record.group_code),
							style: {
								cursor: "pointer",
								backgroundColor:
									selectedGroup === record.group_code
										? token.controlItemBgActive
										: "inherit",
							},
						})}
					/>
				</ProCard>

				{/* 우측 패널: 상세 코드 */}
				<ProCard
					colSpan={14}
					title={selectedGroup ? `[${selectedGroup}] 상세 코드` : "상세 코드"}
					headerBordered
					bordered
					boxShadow
					style={{ height: "100%" }}
					// [🔥 핵심 수정 5] 우측도 동일하게 스크롤 방지
					bodyStyle={{
						padding: 0,
						overflow: "hidden",
						height: "100%",
						display: "flex",
						flexDirection: "column",
					}}
				>
					{selectedGroup ? (
						<ProTable<CodeDetail>
							size="small"
							rowKey="detail_code"
							columns={detailColumns}
							dataSource={details}
							loading={isDetailLoading}
							search={false}
							options={false}
							pagination={false}
							// scroll={{ y: TABLE_SCROLL_Y }}
							{...(details && details.length> maxRowsWithoutScroll && {scroll: { y: TABLE_SCROLL_Y }})}  // 데이터가 많을 때만 스크롤 적용
							toolBarRender={() => [
								<Button
									key="add"
									size="small"
									icon={<PlusOutlined />}
									onClick={() => {
										setEditingDetail(null);
										setDetailModalVisible(true);
									}}
								>
									추가
								</Button>,
							]}
						/>
					) : (
						<div
							style={{
								flex: 1,
								display: "flex",
								justifyContent: "center",
								alignItems: "center",
								color: token.colorTextDisabled,
							}}
						>
							좌측에서 그룹을 선택해주세요.
						</div>
					)}
				</ProCard>
			</ProCard>

			{/* 모달 부분은 기존과 동일하므로 아래에 이어서 작성되어 있습니다 */}
			<ModalForm
				title={editingGroup ? "코드 그룹 수정" : "새 코드 그룹 추가"}
				open={groupModalVisible}
				onOpenChange={setGroupModalVisible}
				onFinish={async (values) => {
					await groupMutation.mutateAsync(values);
					return true;
				}}
				initialValues={editingGroup || { is_active: true }}
				modalProps={{ destroyOnClose: true }}
			>
				<ProFormText
					name="group_code"
					label="그룹 코드"
					disabled={!!editingGroup}
					rules={[{ required: true }]}
				/>
				<ProFormText
					name="group_name"
					label="그룹명"
					rules={[{ required: true }]}
				/>
				<ProFormTextArea name="description" label="설명" />
				<ProFormSwitch name="is_active" label="사용 여부" />
			</ModalForm>

			<ModalForm
				title={editingDetail ? "상세 코드 수정" : "새 상세 코드 추가"}
				open={detailModalVisible}
				onOpenChange={setDetailModalVisible}
				onFinish={async (values) => {
					await detailMutation.mutateAsync(values);
					return true;
				}}
				initialValues={editingDetail || { is_active: true, sort_order: 0 }}
				modalProps={{ destroyOnClose: true }}
			>
				<ProFormText
					name="detail_code"
					label="상세 코드"
					disabled={!!editingDetail}
					rules={[{ required: true }]}
				/>
				<ProFormText
					name="detail_name"
					label="코드명"
					rules={[{ required: true }]}
				/>
				<ProFormDigit name="sort_order" label="정렬 순서" />
				<ProFormSwitch name="is_active" label="활성 여부" />
			</ModalForm>
		</PageContainer>
	);
};

export default CodeManagePage;
