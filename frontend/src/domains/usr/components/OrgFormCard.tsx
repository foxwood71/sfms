import { ProForm, ProFormDigit, ProFormSwitch, ProFormText, ProFormTextArea } from "@ant-design/pro-components";
import { Col, Row } from "antd";
import type { FormInstance } from "antd";
import React, { useEffect } from "react";
import type { Organization, CreateOrgParams } from "../types";
import OrgTreeSelect from "./OrgTreeSelect";

/**
 * 조직 정보 입력 폼 컴포넌트 Props
 */
interface OrgFormCardProps {
	/** 초기값 */
	initialValues?: Organization | CreateOrgParams | null;
	/** 비활성화 여부 */
	disabled?: boolean;
	/** 폼 인스턴스 (외부 제어용) */
	form?: FormInstance;
	/** 완료 콜백 (내부 submitter 사용 시) */
	onFinish?: (values: any) => Promise<void> | void;
}

/**
 * 조직(부서) 상세 정보 및 수정을 위한 폼 카드 내부 컴포넌트
 * - ProForm을 사용하여 고밀도 레이아웃을 구현합니다.
 */
const OrgFormCard: React.FC<OrgFormCardProps> = ({
	initialValues,
	disabled = false,
	form: externalForm,
	onFinish,
}) => {
	const [internalForm] = ProForm.useForm();
	const form = externalForm || internalForm;

	// initialValues가 변경될 때마다 폼 값을 업데이트합니다.
	useEffect(() => {
		if (initialValues) {
			form.setFieldsValue(initialValues);
		} else {
			form.resetFields();
		}
	}, [initialValues, form]);

	return (
		<ProForm
			form={form}
			submitter={false} // 버튼은 외부(Card extra)에서 제어
			layout="vertical"
			onFinish={onFinish}
			disabled={disabled}
		>
			<Row gutter={16}>
				<Col span={12}>
					<ProFormText
						name="name"
						label="조직명"
						placeholder="부서 또는 조직명을 입력하세요"
						rules={[{ required: true, message: "조직명은 필수입니다." }]}
					/>
				</Col>
				<Col span={12}>
					<ProFormText
						name="code"
						label="조직 코드"
						placeholder="영문 대문자 코드 (예: DEPT_01)"
						rules={[
							{ required: true, message: "조직 코드는 필수입니다." },
							{ pattern: /^[A-Z0-9_]+$/, message: "영문 대문자, 숫자, 언더바(_)만 가능합니다." },
						]}
						fieldProps={{
							onChange: (e) => {
								const val = e.target.value.toUpperCase();
								form.setFieldValue("code", val);
							},
						}}
					/>
				</Col>
			</Row>

			<Row gutter={16}>
				<Col span={24}>
					<ProForm.Item name="parent_id" label="상위 조직">
						<OrgTreeSelect placeholder="최상위 조직인 경우 비워두세요" allowClear />
					</ProForm.Item>
				</Col>
			</Row>

			<Row gutter={16}>
				<Col span={12}>
					<ProFormDigit
						name="sort_order"
						label="정렬 순서"
						initialValue={0}
						min={0}
						fieldProps={{ precision: 0 }}
					/>
				</Col>
				<Col span={12}>
					<ProFormSwitch
						name="is_active"
						label="사용 여부"
						checkedChildren="활성"
						unCheckedChildren="비활성"
					/>
				</Col>
			</Row>

			<Row gutter={16}>
				<Col span={24}>
					<ProFormTextArea
						name="description"
						label="설명 (비고)"
						placeholder="조직에 대한 추가 설명을 입력하세요"
						fieldProps={{ autoSize: { minRows: 3, maxRows: 5 } }}
					/>
				</Col>
			</Row>
		</ProForm>
	);
};

export default OrgFormCard;
