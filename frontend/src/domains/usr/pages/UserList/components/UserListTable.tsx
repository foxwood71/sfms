import {
	FilterOutlined,
	LineHeightOutlined,
	PlusOutlined,
} from "@ant-design/icons";
import type { ActionType } from "@ant-design/pro-components";
import { ProCard, ProTable } from "@ant-design/pro-components";
import { useQuery } from "@tanstack/react-query";
import {
	Button,
	Col,
	Dropdown,
	Input,
	Row,
	Select,
	Space,
	Switch,
	Tooltip,
	theme,
} from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useEffect, useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getCodeDetails } from "@/domains/cmm/api";
import { getUsersApi } from "@/domains/usr/api";
import { getUserTableColumns } from "@/domains/usr/pages/UserTableColumns";
import type { User } from "@/domains/usr/types";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";

interface UserListTableProps {
	selectedOrgKey: React.Key;
	onAddUser: () => void;
	onViewUser: (user: User) => void;
}

const UserListTable: React.FC<UserListTableProps> = ({
	selectedOrgKey,
	onAddUser,
	onViewUser,
}) => {
	const { t } = useTranslation();
	const { token } = theme.useToken();
	const actionRef = useRef<ActionType>(null);

	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);
	const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
	const [showUserFilter, setShowUserFilter] = useState(false);
	const [userSearchText, setUserSearchText] = useState("");
	const [showInactiveUser, setShowInactiveUser] = useState(false);

	useEffect(() => {
		setTableSize(showUserFilter ? "small" : "middle");
	}, [showUserFilter]);

	// 기초 코드 조회 및 매핑
	const { data: posCodes } = useQuery({
		queryKey: ["codeDetails", "POS_TYPE"],
		queryFn: () => getCodeDetails("POS_TYPE"),
	});
	const { data: dutyCodes } = useQuery({
		queryKey: ["codeDetails", "DUTY_TYPE"],
		queryFn: () => getCodeDetails("DUTY_TYPE"),
	});

	const posMap = useMemo(() => {
		const map: Record<string, string> = {};
		posCodes?.forEach((c) => {
			map[c.detail_code] = c.detail_name;
		});
		return map;
	}, [posCodes]);

	const dutyMap = useMemo(() => {
		const map: Record<string, string> = {};
		dutyCodes?.forEach((c) => {
			map[c.detail_code] = c.detail_name;
		});
		return map;
	}, [dutyCodes]);

	const columns = useMemo(
		() =>
			getUserTableColumns({
				t,
				posMap,
				dutyMap,
				onViewDetail: onViewUser,
				onToggleStatus: () => {},
				onDelete: () => {},
			}),
		[t, posMap, dutyMap, onViewUser],
	);

	return (
		<ProCard
			title={t("user.list_title")}
			bordered={false}
			extra={
				<Space size={8}>
					<Button
						type="text"
						size="small"
						icon={
							<FilterOutlined
								style={{
									color: showUserFilter ? token.colorPrimary : undefined,
								}}
							/>
						}
						onClick={() => setShowUserFilter(!showUserFilter)}
					/>
					<Button
						key="add"
						icon={<PlusOutlined />}
						type="primary"
						size="small"
						onClick={onAddUser}
					>
						{t("common.create")}
					</Button>
				</Space>
			}
		>
			<div style={{ height: "100%", display: "flex", flexDirection: "column" }}>
				{showUserFilter && (
					<div
						style={{
							padding: "12px 20px",
							background: token.colorFillAlter,
							borderBottom: `1px solid ${token.colorBorderSecondary}`,
						}}
					>
						<Row gutter={16} align="middle">
							<Col span={14}>
								<Input.Search
									placeholder={t("common.search_placeholder")}
									allowClear
									size="small"
									value={userSearchText}
									onChange={(e) => setUserSearchText(e.target.value)}
									onSearch={setUserSearchText}
								/>
							</Col>
							<Col span={10}>
								<div
									style={{
										display: "flex",
										justifyContent: "space-between",
										alignItems: "center",
									}}
								>
									<span
										style={{
											fontSize: "12px",
											color: token.colorTextSecondary,
										}}
									>
										{t("user.include_inactive_user")}
									</span>
									<Switch
										size="small"
										checked={showInactiveUser}
										onChange={setShowInactiveUser}
									/>
								</div>
							</Col>
						</Row>
					</div>
				)}
				<div style={{ flex: 1, overflow: "hidden", padding: "0 16px" }}>
					<ProTable<User>
						actionRef={actionRef}
						size={tableSize}
						scroll={{
							x: "max-content",
							y:
								pageSize <= 10
									? undefined
									: showUserFilter
										? LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT_WITH_FILTER
										: LAYOUT_CONSTANTS.TABLE_VIEW_HEIGHT,
						}}
						rowKey="id"
						params={{
							org_id:
								selectedOrgKey === "root" ? undefined : Number(selectedOrgKey),
							keyword: userSearchText,
							is_active: showInactiveUser ? undefined : true,
							pageSize,
						}}
						search={false}
						options={{ setting: true, density: false }}
						rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
						tableAlertRender={({ selectedRowKeys, onCleanSelected }) => (
							<Space size={24}>
								<span>
									{t("common.selected_count", {
										count: selectedRowKeys.length,
									})}
								</span>
								<Button type="link" size="small" onClick={onCleanSelected}>
									{t("common.clear_selection")}
								</Button>
							</Space>
						)}
						tableAlertOptionRender={() => (
							<Space size={16}>
								<Button danger type="link" onClick={() => {}}>
									{t("common.bulk_delete")}
								</Button>
							</Space>
						)}
						toolBarRender={() => [
							<Select
								key="pz"
								size="small"
								value={pageSize}
								onChange={setPageSize}
								options={[
									{ value: 10, label: t("user.page_size", { count: 10 }) },
									{ value: 20, label: t("user.page_size", { count: 20 }) },
									{ value: 50, label: t("user.page_size", { count: 50 }) },
								]}
								style={{ width: 80 }}
							/>,
							<Dropdown
								key="ds"
								menu={{
									items: [
										{
											key: "large",
											label: t("user.density_default"),
											onClick: () => setTableSize("large"),
										},
										{
											key: "middle",
											label: t("user.density_middle"),
											onClick: () => setTableSize("middle"),
										},
										{
											key: "small",
											label: t("user.density_small"),
											onClick: () => setTableSize("small"),
										},
									],
								}}
								placement="bottomRight"
							>
								<Tooltip title={t("user.density")}>
									<Button type="text" icon={<LineHeightOutlined />} />
								</Tooltip>
							</Dropdown>,
						]}
						request={async (params) => {
							const res = await getUsersApi({
								keyword: params.keyword,
								org_id: params.org_id,
								include_children: true,
								is_active: params.is_active,
								page: params.current,
								size: params.pageSize,
							});
							return {
								data: res.data?.items || [],
								success: true,
								total: res.data?.total || 0,
							};
						}}
						columns={columns}
						pagination={{ pageSize, showSizeChanger: false }}
					/>
				</div>
			</div>
		</ProCard>
	);
};

export default UserListTable;
