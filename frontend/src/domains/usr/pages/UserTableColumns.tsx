import { DeleteOutlined, IdcardOutlined, LockOutlined, UnlockOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { Popconfirm, Tag, Tooltip } from "antd";
import type { User } from "@/domains/usr/types";

interface GetUserTableColumnsProps {
	posMap: Record<string, string>;
	dutyMap: Record<string, string>;
	onViewDetail: (record: User) => void;
	onToggleStatus: (id: number) => void;
	onDelete: (id: number) => void;
}

/**
 * 사용자 목록 테이블 컬럼 정의 생성 함수 (관심사 분리)
 */
export const getUserTableColumns = ({
	posMap,
	dutyMap,
	onViewDetail,
	onToggleStatus,
	onDelete,
}: GetUserTableColumnsProps): ProColumns<User>[] => {
	
	const getRoleColor = (code: string) => {
		const upperCode = (code || "").toUpperCase();
		if (upperCode.includes("ADMIN")) return "magenta";
		if (upperCode.includes("MANAGER")) return "blue";
		if (upperCode.includes("USER")) return "green";
		if (upperCode.includes("SYS")) return "purple";
		if (upperCode.includes("DEV")) return "cyan";
		return "orange";
	};

	return [
		{
			title: "로그인 ID",
			dataIndex: "login_id",
			width: 120,
			ellipsis: true,
			sorter: true,
		},
		{
			title: "성명",
			dataIndex: "name",
			width: 100,
			ellipsis: true,
			sorter: true,
			render: (text, record) => (
				<a style={{ fontWeight: 500 }} onClick={() => onViewDetail(record)}>
					{text}
				</a>
			),
		},
		{
			title: "사번",
			dataIndex: "emp_code",
			width: 100,
			ellipsis: true,
			sorter: true,
		},
		{
			title: "부서",
			dataIndex: "org_name",
			width: 140,
			ellipsis: true,
		},
		{
			title: "역할",
			key: "roles",
			width: 160,
			render: (_, r) => (
				<div style={{ display: "flex", flexWrap: "wrap", gap: "2px" }}>
					{r.roles?.map((role) => (
						<Tag
							key={role.id}
							color={getRoleColor(role.code || role.name)}
							size="small"
							style={{ fontSize: "10px", borderRadius: "10px", border: "none" }}
						>
							{role.name}
						</Tag>
					)) || "-"}
				</div>
			),
		},
		{
			title: "직위",
			key: "pos",
			width: 90,
			render: (_, r) => posMap[r.metadata?.pos || ""] || r.metadata?.pos || "-",
		},
		{
			title: "직책",
			key: "duty",
			width: 90,
			render: (_, r) => dutyMap[r.metadata?.duty || ""] || r.metadata?.duty || "-",
		},
		{
			title: "상태",
			dataIndex: "is_active",
			width: 80,
			render: (active) => (
				<Tag color={active ? "green" : "default"}>{active ? "재직" : "퇴사"}</Tag>
			),
		},
		{
			title: "계정",
			dataIndex: "account_status",
			width: 80,
			render: (s) => (
				<Tag color={s === "ACTIVE" ? "blue" : "error"}>
					{s === "ACTIVE" ? "정상" : "차단"}
				</Tag>
			),
		},
		{
			title: "관리",
			valueType: "option",
			width: 120,
			fixed: "right",
			render: (_, record) => [
				<Tooltip key="v" title="상세 정보">
					<a onClick={() => onViewDetail(record)}>
						<IdcardOutlined />
					</a>
				</Tooltip>,
				<Tooltip key="l" title="계정 관리">
					<a style={{ marginLeft: 12 }} onClick={() => onToggleStatus(record.id)}>
						{record.account_status === "ACTIVE" ? (
							<LockOutlined style={{ color: "#faad14" }} />
						) : (
							<UnlockOutlined style={{ color: "#52c41a" }} />
						)}
					</a>
				</Tooltip>,
				<Popconfirm
					key="d"
					title="퇴직 처리"
					description="해당 사용자를 퇴직 처리하시겠습니까?"
					onConfirm={() => onDelete(record.id)}
					okText="처리"
					cancelText="취소"
				>
					<Tooltip title="퇴직 처리">
						<a style={{ color: "#ff4d4f", marginLeft: 12 }}>
							<DeleteOutlined />
						</a>
					</Tooltip>
				</Popconfirm>,
			],
		},
	];
};
