import {
	ModalForm,
	ProFormSelect,
	ProFormSwitch,
	ProFormText,
} from "@ant-design/pro-components";
import { Col, Divider, Form, Row, theme } from "antd";
import type React from "react";
import type { CreateUserParams, UpdateUserParams, User } from "../types";
import OrgTreeSelect from "./OrgTreeSelect";
import CodeSelect from "./CodeSelect";

/**
 * TSDoc: 사용자 생성 및 수정 폼 모달 Props 인터페이스
 */
interface UserFormModalProps {
	/** 모달 오픈 상태 */
	open: boolean;
	/** 오픈 상태 변경 콜백 */
	onOpenChange: (open: boolean) => void;
	/** 수정 대상 사용자 데이터 (null이면 생성 모드) */
	editingUser: User | null;
	/** 초기 조직 ID (목록에서 선택된 조직) */
	initialOrgId?: number;
	/** 저장 완료 시 호출되는 콜백 */
	onFinish: (values: CreateUserParams | UpdateUserParams) => Promise<boolean>;
}

/**
 * 사용자 생성/수정 화면 (High Density Layout)
 * 
 * SFMS UI Standard:
 * - 2단 그리드 레이아웃 (Row/Col)
 * - 고밀도 필드 배치 (Vertical Layout)
 * - 상태 기반 동적 렌더링
 */
const UserFormModal: React.FC<UserFormModalProps> = ({
	open,
	onOpenChange,
	editingUser,
	initialOrgId,
	onFinish,
}) => {
	const { token } = theme.useToken();
	const [form] = Form.useForm();

	// 모드에 따른 제목 설정
	const title = editingUser ? "사용자 정보 수정" : "신규 사용자 등록";

	return (
		<ModalForm
			title={title}
			open={open}
			onOpenChange={onOpenChange}
			form={form}
			onFinish={onFinish}
			initialValues={
				editingUser
					? {
							...editingUser,
							pos: editingUser.metadata?.pos,
							duty: editingUser.metadata?.duty,
						}
					: {
							is_active: true,
							org_id: initialOrgId,
						}
			}
			modalProps={{
				destroyOnClose: true,
				maskClosable: false,
				width: 720, // 2단 그리드를 위해 넓게 설정
			}}
			layout="vertical"
			grid={true} // ProForm Grid 활성화
		>
			<div style={{ marginBottom: 16 }}>
				<Divider orientation="left" style={{ margin: "0 0 16px 0", fontSize: "14px", color: token.colorTextSecondary }}>
					기본 정보
				</Divider>
				<Row gutter={24}>
					<Col span={12}>
						<ProFormText
							name="login_id"
							label="로그인 ID"
							placeholder="소문자, 숫자 조합 (4~20자)"
							rules={[
								{ required: true, message: "로그인 ID를 입력하세요." },
								{ pattern: /^[a-z0-9_]{4,20}$/, message: "4~20자의 영문 소문자, 숫자, _만 가능합니다." }
							]}
							disabled={!!editingUser}
						/>
					</Col>
					<Col span={12}>
						{editingUser ? (
							<div style={{ height: 64, display: 'flex', alignItems: 'center' }}>
								<span style={{ color: token.colorTextDescription, fontSize: '12px' }}>
									※ 로그인 ID는 생성 후 변경할 수 없습니다.
								</span>
							</div>
						) : (
							<ProFormText.Password
								name="password"
								label="초기 비밀번호"
								placeholder="8자 이상, 특수문자 포함 권장"
								rules={[{ required: true, message: "초기 비밀번호를 입력하세요." }, { min: 8, message: "최소 8자 이상이어야 합니다." }]}
							/>
						)}
					</Col>
				</Row>
				<Row gutter={24}>
					<Col span={12}>
						<ProFormText
							name="name"
							label="성명"
							placeholder="실명을 입력하세요"
							rules={[{ required: true, message: "성명을 입력하세요." }]}
						/>
					</Col>
					<Col span={12}>
						<ProFormText
							name="emp_code"
							label="사번"
							placeholder="STP-0000"
							rules={[{ required: true, message: "사번을 입력하세요." }]}
						/>
					</Col>
				</Row>
			</div>

			<div style={{ marginBottom: 16 }}>
				<Divider orientation="left" style={{ margin: "0 0 16px 0", fontSize: "14px", color: token.colorTextSecondary }}>
					인사 / 연락처 정보
				</Divider>
				<Row gutter={24}>
					<Col span={12}>
						<div style={{ marginBottom: 24 }}>
							<label style={{ display: "block", marginBottom: 8, fontSize: "14px", fontWeight: 500 }}>
								소속 부서
							</label>
							<OrgTreeSelect name="org_id" />
						</div>
					</Col>
					<Col span={12}>
						<ProFormText
							name="email"
							label="이메일"
							placeholder="example@sfms.com"
							rules={[
								{ type: "email", message: "올바른 이메일 형식이 아닙니다." },
								{ required: true, message: "이메일을 입력하세요." }
							]}
						/>
					</Col>
				</Row>
				<Row gutter={24}>
					<Col span={12}>
						<div style={{ marginBottom: 24 }}>
							<label style={{ display: "block", marginBottom: 8, fontSize: "14px", fontWeight: 500 }}>
								직위/직급
							</label>
							<CodeSelect groupCode="POS_TYPE" name="pos" />
						</div>
					</Col>
					<Col span={12}>
						<div style={{ marginBottom: 24 }}>
							<label style={{ display: "block", marginBottom: 8, fontSize: "14px", fontWeight: 500 }}>
								직책
							</label>
							<CodeSelect groupCode="DUTY_TYPE" name="duty" />
						</div>
					</Col>
				</Row>
				<Row gutter={24}>
					<Col span={12}>
						<ProFormText
							name="phone"
							label="연락처"
							placeholder="010-0000-0000"
						/>
					</Col>
					<Col span={12}>
						<ProFormSwitch 
							name="is_active" 
							label="재직 상태" 
							checkedChildren="재직" 
							unCheckedChildren="퇴사"
						/>
					</Col>
				</Row>
			</div>
		</ModalForm>
	);
};

export default UserFormModal;
