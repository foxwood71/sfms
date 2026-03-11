import {
	ModalForm,
	ProForm,
	ProFormSwitch,
	ProFormText,
} from "@ant-design/pro-components";
import { Avatar, Button, Checkbox, Col, Divider, Form, Row, Space, Upload, message, theme } from "antd";
import type { AxiosError } from "axios";
import { useEffect, useState } from "react";
import { EditOutlined, UploadOutlined, UserOutlined } from "@ant-design/icons";
import { http } from "@/shared/api/http";
import type { APIErrorResponse } from "@/shared/api/types";
import type { CreateUserParams, UpdateUserParams, User } from "../types";
import OrgTreeSelect from "./OrgTreeSelect";
import CodeSelect from "./CodeSelect";

interface UserFormModalProps {
	open: boolean;
	onOpenChange: (open: boolean) => void;
	editingUser: User | null;
	initialOrgId?: number;
	onFinish: (values: CreateUserParams | UpdateUserParams) => Promise<boolean>;
}

/**
 * 사용자 등록/수정 모달 컴포넌트
 */
const UserFormModal: React.FC<UserFormModalProps> = ({
	open,
	onOpenChange,
	editingUser,
	initialOrgId,
	onFinish,
}) => {
	const [form] = Form.useForm();
	const { token } = theme.useToken();
	const [profileId, setProfileId] = useState<string | null>(null);

	useEffect(() => {
		if (open) {
			if (editingUser) {
				form.setFieldsValue(editingUser);
				setProfileId(editingUser.profile_id || null);
			} else {
				form.resetFields();
				form.setFieldsValue({
					is_active: true,
					org_id: initialOrgId,
				});
				setProfileId(null);
			}
		}
	}, [open, editingUser, initialOrgId, form]);

	const handleCustomUpload = async (options: { file: File | string | Blob; onSuccess: (res: unknown) => void; onError: (err: Error) => void }) => {
		const { file, onSuccess, onError } = options;
		const formData = new FormData();
		formData.append("file", file);

		try {
			const res = await http.post("/cmm/files/upload", formData, {
				headers: { "Content-Type": "multipart/form-data" },
			});
			const fileId = res.data.data.id;
			setProfileId(fileId);
			onSuccess(res.data);
			message.success("사진 업로드 성공");
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			onError(new Error(err.message));
			message.error("업로드 실패");
		}
	};

	return (
		<ModalForm
			title={editingUser ? "사용자 정보 수정" : "신규 사용자 등록"}
			open={open}
			onOpenChange={onOpenChange}
			form={form}
			onFinish={async (values) => {
				const payload = { ...values, profile_id: profileId };
				return onFinish(payload as any);
			}}
			modalProps={{
				destroyOnClose: true,
				maskClosable: false,
			}}
			width={800}
		>
			<Row gutter={24}>
				<Col span={6} style={{ textAlign: "center" }}>
					<Space direction="vertical" align="center" style={{ width: "100%" }}>
						<Avatar
							size={120}
							src={profileId ? `/api/v1/cmm/files/download/${profileId}` : undefined}
							icon={<UserOutlined />}
							style={{ backgroundColor: token.colorPrimaryBg, border: `1px solid ${token.colorPrimaryBorder}` }}
						/>
						<Upload customRequest={handleCustomUpload as any} showUploadList={false}>
							<Button icon={<UploadOutlined />} size="small">사진 변경</Button>
						</Upload>
					</Space>
				</Col>
				<Col span={18}>
					<Row gutter={16}>
						<Col span={12}>
							<ProFormText
								name="login_id"
								label="아이디"
								placeholder="아이디 입력"
								rules={[{ required: true }]}
								disabled={!!editingUser}
							/>
						</Col>
						<Col span={12}>
							<ProFormText
								name="emp_code"
								label="사번"
								placeholder="사번 입력"
								rules={[{ required: true }]}
							/>
						</Col>
						<Col span={12}>
							<ProFormText
								name="name"
								label="이름"
								placeholder="실명 입력"
								rules={[{ required: true }]}
							/>
						</Col>
						<Col span={12}>
							<ProFormText
								name="email"
								label="이메일"
								placeholder="email@example.com"
								rules={[{ type: "email" }]}
							/>
						</Col>
					</Row>
				</Col>
			</Row>

			<Divider dashed />

			<Row gutter={24}>
				<Col span={12}>
					<Form.Item label="소속 부서" name="org_id" rules={[{ required: true }]}>
						<OrgTreeSelect />
					</Form.Item>
				</Col>
				<Col span={12}>
					<ProFormSwitch name="is_active" label="재직 상태" checkedChildren="재직" unCheckedChildren="퇴사" />
				</Col>
			</Row>

			<Row gutter={24}>
				<Col span={12}>
					<Form.Item label="직위/직급" name="pos">
						<CodeSelect groupCode="POS_TYPE" />
					</Form.Item>
				</Col>
				<Col span={12}>
					<Form.Item label="직책" name="duty">
						<CodeSelect groupCode="DUTY_TYPE" />
					</Form.Item>
				</Col>
			</Row>
		</ModalForm>
	);
};

export default UserFormModal;
