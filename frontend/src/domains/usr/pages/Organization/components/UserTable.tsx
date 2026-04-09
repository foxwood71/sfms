import { LineHeightOutlined } from "@ant-design/icons";
import type { ActionType } from "@ant-design/pro-components";
import { ProTable } from "@ant-design/pro-components";
import { useQuery} from "@tanstack/react-query";
import { Button, Dropdown, Select, Space, theme } from "antd";
import type { SizeType } from "antd/es/config-provider/SizeContext";
import type React from "react";
import { useMemo, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import { getCodeDetails } from "@/domains/cmm/api";
import { getUsersApi } from "@/domains/usr/api";
import { getUserTableColumns } from "@/domains/usr/pages/UserTableColumns";
import type { User } from "@/domains/usr/types";

interface UserTableProps {
	orgId: number | undefined;
	onViewUser: (user: User) => void;
}

const UserTable: React.FC<UserTableProps> = ({ orgId, onViewUser }) => {
	const { t } = useTranslation();
	const { token } = theme.useToken();
	const actionRef = useRef<ActionType>(null);

	const [tableSize, setTableSize] = useState<SizeType>("middle");
	const [pageSize, setPageSize] = useState(10);
	const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

	// --- 데이터 조회 ---
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

	const userColumns = useMemo(
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
		<div style={{ flex: 1, overflow: "hidden", padding: "0 20px 20px 20px" }}>
			<ProTable<User>
				actionRef={actionRef}
				columns={userColumns}
				size={tableSize}
				rowKey="id"
				search={false}
				options={{ setting: true, density: false }}
				params={{ org_id: orgId }}
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
				request={async (params) => {
					const res = await getUsersApi({
						org_id: params.org_id,
						page: params.current,
						size: params.pageSize,
					});
					return {
						data: res.data.items,
						success: true,
						total: res.data.total,
					};
				}}
				toolBarRender={() => [
					<Select
						key="pz"
						size="small"
						value={pageSize}
						onChange={setPageSize}
						options={[
							{ value: 10, label: t("user.page_size", { count: 10 }) },
							{ value: 20, label: t("user.page_size", { count: 20 }) },
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
					>
						<Button type="text" size="small" icon={<LineHeightOutlined />} />
					</Dropdown>,
				]}
				pagination={{
					pageSize,
					onChange: (_, size) => setPageSize(size || 10),
				}}
			/>
			{/* 풍선 형태의 Bulk Action Bar */}
			{selectedRowKeys.length > 0 && (
				<div className="bulk-action-balloon">
					<Space size={16}>
						<span style={{ fontWeight: 600, color: token.colorPrimary }}>
							{t("common.selected_count", {
								count: selectedRowKeys.length,
							})}
						</span>
						<div
							style={{
								width: "1px",
								height: "16px",
								background: token.colorBorderSecondary,
							}}
						/>
						<Button type="text" danger size="small" onClick={() => {}}>
							{t("common.bulk_delete")}
						</Button>
						<Button
							type="link"
							size="small"
							onClick={() => setSelectedRowKeys([])}
						>
							{t("common.clear_selection")}
						</Button>
					</Space>
				</div>
			)}
		</div>
	);
};

export default UserTable;
