import {
	ApartmentOutlined,
	ClusterOutlined,
	DeleteOutlined,
	EditOutlined,
	PlusOutlined,
	ReloadOutlined,
	SearchOutlined,
	TeamOutlined,
} from "@ant-design/icons";
import { PageContainer } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Card,
	Empty,
	Input,
	Popconfirm,
	Space,
	Splitter,
	Tooltip,
	Tree,
	Typography,
	theme,
} from "antd";
import type { TreeDataNode } from "antd";
import type { AxiosError } from "axios";
import React, { useEffect, useMemo, useState } from "react";
import type { APIErrorResponse } from "../../../shared/api/types";
import {
	createOrganizationApi,
	deleteOrganizationApi,
	getOrganizationsApi,
	updateOrganizationApi,
} from "../api";
import OrgFormCard from "../components/OrgFormCard";
import type { CreateOrgParams, Organization, UpdateOrgParams } from "../types";

const { Title, Text } = Typography;

/**
 * 조직도 관리 페이지
 * - 전체 조직 구조를 트리 형태로 시각화하고 개별 조직의 정보를 관리합니다.
 */
const OrganizationPage: React.FC = () => {
	const { token } = theme.useToken();
	const { message } = App.useApp();
	const queryClient = useQueryClient();

	const [selectedKey, setSelectedKey] = useState<number | string | null>(null);
	const [isEditing, setIsEditing] = useState(false);
	const [isAdding, setIsAdding] = useState(false);
	const [searchValue, setSearchValue] = useState("");
	const [showSearch, setShowSearch] = useState(false);
	const [expandedKeys, setExpandedKeys] = useState<(string | number)[]>(["root"]);

	// [데이터 조회] 전체 조직 목록
	const {
		data: orgResponse,
		isLoading,
		refetch,
	} = useQuery({
		queryKey: ["organizations"],
		queryFn: () => getOrganizationsApi("tree", false),
	});

	// [유틸] 트리 데이터 평탄화 (검색 및 선택용)
	const flatData = useMemo(() => {
		const flatten = (items: Organization[]): Organization[] => {
			let result: Organization[] = [];
			for (const item of items) {
				result.push(item);
				if (item.children) result = result.concat(flatten(item.children));
			}
			return result;
		};
		return orgResponse?.data ? flatten(orgResponse.data) : [];
	}, [orgResponse]);

	const allKeys = useMemo(() => ["root", ...flatData.map((o) => o.id)], [flatData]);

	useEffect(() => {
		if (searchValue && flatData.length > 0) {
			const match = flatData.find((org) =>
				org.name.toLowerCase().includes(searchValue.toLowerCase()),
			);
			if (match) setSelectedKey(match.id);
		}
	}, [searchValue, flatData]);

	const selectedOrg = useMemo(() => {
		if (selectedKey === null || selectedKey === "root") return null;
		return flatData.find((org) => org.id === selectedKey) || null;
	}, [selectedKey, flatData]);

	const treeData = useMemo((): TreeDataNode[] => {
		const mapToTree = (items: Organization[], parentMatched = false): TreeDataNode[] => {
			return items
				.map((item) => {
					const isMatched =
						!searchValue || item.name.toLowerCase().includes(searchValue.toLowerCase());
					const childrenNodes = item.children
						? mapToTree(item.children, parentMatched || isMatched)
						: [];
					const hasVisibleChildren = childrenNodes.length > 0;
					if (!parentMatched && !isMatched && !hasVisibleChildren) return null;

					return {
						key: item.id,
						title: (
							<Tooltip title={item.name} placement="right" mouseEnterDelay={0.5}>
								<span style={{ whiteSpace: "nowrap", display: "inline-block" }}>
									{item.is_active ? (
										item.name
									) : (
										<span
											style={{
												color: token.colorTextDisabled,
												textDecoration: "line-through",
												opacity: 0.6,
												fontStyle: "italic",
											}}
										>
											{item.name} (비활성)
										</span>
									)}
								</span>
							</Tooltip>
						),
						icon:
							item.children && item.children.length > 0 ? (
								<ClusterOutlined />
							) : (
								<ApartmentOutlined />
							),
						children: childrenNodes,
					};
				})
				.filter((node): node is TreeDataNode => node !== null);
		};
		return [
			{
				key: "root",
				title: "전체 조직도",
				icon: <TeamOutlined />,
				children: orgResponse?.data ? mapToTree(orgResponse.data) : [],
			},
		];
	}, [orgResponse, searchValue, token]);

	// [수정] 친절한 에러 메시지 처리
	const saveMutation = useMutation({
		mutationFn: (values: CreateOrgParams | UpdateOrgParams) => {
			const payload = { ...values, code: values.code?.toUpperCase() };
			if (isAdding) return createOrganizationApi(payload as CreateOrgParams);
			if (selectedKey && typeof selectedKey === "number")
				return updateOrganizationApi(selectedKey, payload as UpdateOrgParams);
			throw new Error("대상 조직이 선택되지 않았습니다.");
		},
		onSuccess: async (response) => {
			message.success("조직 정보가 안전하게 저장되었습니다.");
			await queryClient.invalidateQueries({ queryKey: ["organizations"] });
			if (isAdding && response.data?.id) {
				setSelectedKey(response.data.id);
			}
			setIsAdding(false);
			setIsEditing(false);
		},
		onError: (error: unknown) => {
			const err = error as AxiosError<APIErrorResponse>;
			const errorMsg = err.response?.data?.message || err.message || "알 수 없는 오류가 발생했습니다.";
			message.error(`저장에 실패했습니다: ${errorMsg}`);
		},
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteOrganizationApi(id),
		onSuccess: async () => {
			message.success("조직이 삭제되었습니다.");
			setSelectedKey(null);
			setIsEditing(false);
			await queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (error: unknown) => {
			const err = error as AxiosError<APIErrorResponse>;
			const errorMsg =
				err.response?.data?.message || err.message || "삭제 권한이 없거나 하위 데이터가 존재합니다.";
			message.error(`삭제 실패: ${errorMsg}`);
		},
	});

	const handleAdd = () => {
		setIsAdding(true);
		setIsEditing(true);
	};
	const handleCancel = () => {
		if (isAdding) {
			setIsAdding(false);
			setSelectedKey(null);
		}
		setIsEditing(false);
	};
	const toggleExpandAll = () =>
		expandedKeys.length > 1 ? setExpandedKeys(["root"]) : setExpandedKeys(allKeys);
	const closeSearch = () => {
		setShowSearch(false);
		setSearchValue("");
	};

	const isDisabled = !isEditing;

	return (
		<PageContainer
			header={{
				title: "조직도 관리",
				extra: [
					<Button key="refresh" icon={<ReloadOutlined />} onClick={() => refetch()} loading={isLoading} />,
					<Button key="expand" onClick={toggleExpandAll}>
						{expandedKeys.length > 1 ? "모두 접기" : "모두 펼치기"}
					</Button>,
					<Button key="add" type="primary" icon={<PlusOutlined />} onClick={handleAdd} disabled={isEditing}>
						새 조직 추가
					</Button>,
				],
			}}
		>
			<div style={{ height: "calc(100vh - 180px)" }}>
				<Splitter>
					<Splitter.Panel defaultSize="25%" min="200px">
						<Card
							styles={{ body: { padding: 12 } }}
							style={{ height: "100%", display: "flex", flexDirection: "column" }}
						>
							<div
								style={{
									marginBottom: 16,
									display: "flex",
									justifyContent: "space-between",
									alignItems: "center",
								}}
							>
								{showSearch ? (
									<Input.Search
										placeholder="조직명 검색..."
										size="small"
										autoFocus
										onSearch={(v) => setSearchValue(v)}
										onChange={(e) => setSearchValue(e.target.value)}
										onBlur={() => !searchValue && closeSearch()}
										style={{ width: "100%" }}
									/>
								) : (
									<>
										<Text strong type="secondary" style={{ fontSize: 12 }}>
											ORGANIZATION TREE
										</Text>
										<Button type="text" size="small" icon={<SearchOutlined />} onClick={() => setShowSearch(true)} />
									</>
								)}
							</div>
							<div style={{ flex: 1, overflow: "auto" }}>
								<Tree
									showIcon
									blockNode
									treeData={treeData}
									selectedKeys={selectedKey ? [selectedKey] : []}
									expandedKeys={expandedKeys}
									onExpand={(keys) => setExpandedKeys(keys)}
									onSelect={(keys) => {
										if (keys.length > 0) {
											setSelectedKey(keys[0]);
											setIsAdding(false);
											setIsEditing(false);
										}
									}}
								/>
							</div>
						</Card>
					</Splitter.Panel>
					<Splitter.Panel>
						<div style={{ padding: "0 0 0 16px", height: "100%" }}>
							{isAdding || selectedOrg ? (
								<Card
									title={
										<Space>
											{isAdding ? <PlusOutlined /> : <EditOutlined />}
											<Title level={5} style={{ margin: 0 }}>
												{isAdding ? "새 조직 등록" : `[${selectedOrg?.code}] ${selectedOrg?.name}`}
											</Title>
										</Space>
									}
									extra={
										<Space>
											{isDisabled ? (
												<>
													<Popconfirm
														title="조직 삭제"
														description="정말 이 조직을 삭제하시겠습니까? (하위 조직이 있으면 불가능합니다)"
														onConfirm={() => selectedOrg && deleteMutation.mutate(selectedOrg.id)}
														okText="삭제"
														cancelText="취소"
														okButtonProps={{ danger: true }}
													>
														<Button danger icon={<DeleteOutlined />}>
															삭제
														</Button>
													</Popconfirm>
													<Button type="primary" onClick={() => setIsEditing(true)}>
														수정
													</Button>
												</>
											) : (
												<>
													<Button onClick={handleCancel}>취소</Button>
													<Button type="primary" onClick={() => saveMutation.mutate(selectedOrg as any)}>
														저장
													</Button>
												</>
											)
										}
										</Space>
									}
									style={{ height: "100%" }}
								>
									<OrgFormCard
										initialValues={isAdding ? { parent_id: selectedKey === "root" ? null : (selectedKey as number), is_active: true } : (selectedOrg as Organization)}
										disabled={isDisabled}
										onFinish={(v) => saveMutation.mutate(v as any)}
									/>
								</Card>
							) : (
								<Card style={{ height: "100%", display: "flex", alignItems: "center", justifyContent: "center" }}>
									<Empty description="조직도에서 부서를 선택하거나 새 조직을 추가해 주세요." />
								</Card>
							)}
						</div>
					</Splitter.Panel>
				</Splitter>
			</div>
		</PageContainer>
	);
};

export default OrganizationPage;
