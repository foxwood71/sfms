import { CloseOutlined, EditOutlined, SaveOutlined, TagOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormDigit, ProFormText } from "@ant-design/pro-components";
import { Button, theme, Switch, Typography, Row, Col } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import type { CodeDetail } from "../types";

const { Title, Text } = Typography;

interface CodeDetailDrawerProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	editingDetail: CodeDetail | null;
	groupName: string;
	onFinish: (values: Partial<CodeDetail>) => Promise<boolean>;
}

const CodeDetailDrawer: React.FC<CodeDetailDrawerProps> = ({
	open,
	onOpenChange,
	editingDetail,
	groupName,
	onFinish,
}) => {
	const { token } = theme.useToken();
	const [form] = ProForm.useForm<CodeDetail>();
	const [mode, setMode] = useState<"view" | "edit" | "add">("view");

	const isReadOnly = mode === "view";
	const watchedActive = ProForm.useWatch("is_active", form);

	useEffect(() => {
		if (open) {
			if (editingDetail) {
				setMode("view");
				form.setFieldsValue(editingDetail);
			} else {
				setMode("add");
				form.resetFields();
				form.setFieldsValue({ is_active: true, sort_order: 10 });
			}
		}
	}, [open, editingDetail, form]);

	const fieldStyle = useMemo(() => ({
		style: {
			height: "32px",
			color: isReadOnly ? token.colorText : undefined,
			fontWeight: isReadOnly ? 500 : undefined,
		}
	}), [isReadOnly, token]);

	return (
		<DrawerForm<CodeDetail>
			title={mode === "view" ? "상세 코드 정보" : mode === "edit" ? "상세 코드 수정" : "새 상세 코드 등록"}
			open={open}
			onOpenChange={onOpenChange}
			form={form}
			onFinish={onFinish}
			submitter={{
				render: (props) => mode === "view" ? [
					<Button key="close" onClick={() => onOpenChange(false)}>닫기</Button>,
					<Button key="edit" type="primary" icon={<EditOutlined />} onClick={() => setMode("edit")}>수정하기</Button>
				] : [
					<Button key="cancel" onClick={() => (editingDetail ? setMode("view") : onOpenChange(false))} icon={<CloseOutlined />}>
						{editingDetail ? "수정 취소" : "취소"}
					</Button>,
					<Button key="submit" type="primary" icon={<SaveOutlined />} onClick={() => props.form?.submit()}>
						{editingDetail ? "수정 완료" : "등록 완료"}
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
					<TagOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
				</div>
				<div>
					<Title level={4} style={{ margin: 0 }}>{form.getFieldValue("detail_name") || "새 코드"}</Title>
					<Text type="secondary">{groupName} ({form.getFieldValue("detail_code") || "DETAIL_CODE"})</Text>
				</div>
			</div>

			<ProFormText name="detail_code" label="상세 코드" disabled={mode !== "add"} fieldProps={fieldStyle} rules={[{ required: true }]} />
			<ProFormText name="detail_name" label="코드명" disabled={isReadOnly} fieldProps={fieldStyle} rules={[{ required: true }]} />
			
			<Row gutter={16}>
				<Col span={12}>
					<ProFormDigit name="sort_order" label="정렬 순서" disabled={isReadOnly} fieldProps={fieldStyle} rules={[{ required: true }]} />
				</Col>
			</Row>

			{/* 상태 바 */}
			<div style={{ 
				marginTop: 24, padding: "12px 16px", borderRadius: 8, 
				border: `1px solid ${watchedActive ? token.colorSuccessBorder : token.colorBorderSecondary}`,
				background: watchedActive ? token.colorSuccessBg : token.colorFillQuaternary,
				display: "flex", justifyContent: "space-between", alignItems: "center" 
			}}>
				<Text strong style={{ color: watchedActive ? token.colorSuccess : token.colorTextDisabled }}>
					코드 활성화 상태: {watchedActive ? "사용 중" : "중지됨"}
				</Text>
				<ProForm.Item name="is_active" noStyle valuePropName="checked">
					<Switch size="small" disabled={isReadOnly} />
				</ProForm.Item>
			</div>
		</DrawerForm>
	);
};

export default CodeDetailDrawer;
