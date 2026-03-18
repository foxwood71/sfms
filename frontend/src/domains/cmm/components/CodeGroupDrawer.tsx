import { CloseOutlined, EditOutlined, SaveOutlined, FolderOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormSwitch, ProFormText, ProFormTextArea } from "@ant-design/pro-components";
import { Button, Divider, Space, theme, Switch, Typography } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import type { CodeGroup } from "../types";

const { Title, Text } = Typography;

interface CodeGroupDrawerProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	editingGroup: CodeGroup | null;
	onFinish: (values: Partial<CodeGroup>) => Promise<boolean>;
}

const CodeGroupDrawer: React.FC<CodeGroupDrawerProps> = ({
	open,
	onOpenChange,
	editingGroup,
	onFinish,
}) => {
	const { token } = theme.useToken();
	const [form] = ProForm.useForm<CodeGroup>();
	const [mode, setMode] = useState<"view" | "edit" | "add">("view");

	const isReadOnly = mode === "view";
	const watchedActive = ProForm.useWatch("is_active", form);

	useEffect(() => {
		if (open) {
			if (editingGroup) {
				setMode("view");
				form.setFieldsValue(editingGroup);
			} else {
				setMode("add");
				form.resetFields();
				form.setFieldsValue({ is_active: true });
			}
		}
	}, [open, editingGroup, form]);

	const fieldStyle = useMemo(() => ({
		style: {
			height: "32px",
			color: isReadOnly ? token.colorText : undefined,
			fontWeight: isReadOnly ? 500 : undefined,
		}
	}), [isReadOnly, token]);

	return (
		<DrawerForm<CodeGroup>
			title={mode === "view" ? "코드 그룹 상세" : mode === "edit" ? "코드 그룹 수정" : "새 코드 그룹 등록"}
			open={open}
			onOpenChange={onOpenChange}
			form={form}
			onFinish={onFinish}
			submitter={{
				render: (props) => mode === "view" ? [
					<Button key="close" onClick={() => onOpenChange(false)}>닫기</Button>,
					<Button key="edit" type="primary" icon={<EditOutlined />} onClick={() => setMode("edit")}>수정하기</Button>
				] : [
					<Button key="cancel" onClick={() => (editingGroup ? setMode("view") : onOpenChange(false))} icon={<CloseOutlined />}>
						{editingGroup ? "수정 취소" : "취소"}
					</Button>,
					<Button key="submit" type="primary" icon={<SaveOutlined />} onClick={() => props.form?.submit()}>
						{editingGroup ? "수정 완료" : "등록 완료"}
					</Button>
				],
			}}
			drawerProps={{
				destroyOnHidden: true,
				maskClosable: isReadOnly,
				width: 500,
				styles: { body: { padding: "24px" } },
			}}
			layout="vertical"
		>
			<style>{`
				.ant-input-disabled, .ant-select-disabled .ant-select-selection-item {
					color: ${token.colorText} !important;
					-webkit-text-fill-color: ${token.colorText} !important;
					font-weight: 500;
				}
				.ant-input-disabled, .ant-select-disabled .ant-select-selector {
					background-color: ${isReadOnly ? token.colorFillQuaternary : undefined} !important;
				}
			`}</style>

			{/* 헤더 섹션 */}
			<div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: 32 }}>
				<div style={{ width: 64, height: 64, borderRadius: 12, background: token.colorFillAlter, display: "flex", justifyContent: "center", alignItems: "center" }}>
					<FolderOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
				</div>
				<div>
					<Title level={4} style={{ margin: 0 }}>{form.getFieldValue("group_name") || "새 그룹"}</Title>
					<Text type="secondary">{form.getFieldValue("group_code") || "GROUP_CODE"}</Text>
				</div>
			</div>

			<ProFormText name="group_code" label="그룹 코드" disabled={mode !== "add"} fieldProps={fieldStyle} rules={[{ required: true }]} placeholder="영문 대문자 권장" />
			<ProFormText name="group_name" label="그룹명" disabled={isReadOnly} fieldProps={fieldStyle} rules={[{ required: true }]} />
			<ProFormTextArea name="description" label="설명" disabled={isReadOnly} fieldProps={{ ...fieldStyle, height: "auto" }} />

			{/* 상태 바 */}
			<div style={{ 
				marginTop: 24, padding: "12px 16px", borderRadius: 8, 
				border: `1px solid ${watchedActive ? token.colorSuccessBorder : token.colorBorderSecondary}`,
				background: watchedActive ? token.colorSuccessBg : token.colorFillQuaternary,
				display: "flex", justifyContent: "space-between", alignItems: "center" 
			}}>
				<Text strong style={{ color: watchedActive ? token.colorSuccess : token.colorTextDisabled }}>
					그룹 활성화 상태: {watchedActive ? "사용 중" : "중지됨"}
				</Text>
				<ProForm.Item name="is_active" noStyle valuePropName="checked">
					<Switch size="small" disabled={isReadOnly} />
				</ProForm.Item>
			</div>
		</DrawerForm>
	);
};

export default CodeGroupDrawer;
