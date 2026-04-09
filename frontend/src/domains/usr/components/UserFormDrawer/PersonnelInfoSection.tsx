import { ProForm, ProFormText } from "@ant-design/pro-components";
import { Col, Divider, Row, theme } from "antd";
import type React from "react";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import CodeSelect from "../CodeSelect";
import OrgTreeSelect from "../OrgTreeSelect";

interface PersonnelInfoSectionProps {
    isReadOnly: boolean;
    fieldStyle: { style: React.CSSProperties };
}

const PersonnelInfoSection: React.FC<PersonnelInfoSectionProps> = ({
    isReadOnly,
    fieldStyle,
}) => {
    const { token } = theme.useToken();

    return (
        <>
            <Divider
                orientation="left"
                style={{
                    margin: "12px 0 16px 0",
                    fontSize: "13px",
                    color: token.colorTextSecondary,
                    fontWeight: 600,
                }}
            >
                인사 / 부서 정보
            </Divider>
            <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                <Col span={24}>
                    <ProForm.Item name="org_id" label="소속 부서" rules={[{ required: true }]}>
                        <OrgTreeSelect disabled={isReadOnly} style={{ height: "32px" }} />
                    </ProForm.Item>
                </Col>
            </Row>
            <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                <Col span={12}>
                    <ProForm.Item name="pos" label="직위/직급">
                        <CodeSelect groupCode="POS_TYPE" disabled={isReadOnly} style={{ height: "32px" }} />
                    </ProForm.Item>
                </Col>
                <Col span={12}>
                    <ProForm.Item name="duty" label="직책">
                        <CodeSelect groupCode="DUTY_TYPE" disabled={isReadOnly} style={{ height: "32px" }} />
                    </ProForm.Item>
                </Col>
            </Row>
            <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                <Col span={12}>
                    <ProFormText
                        name="email"
                        label="이메일"
                        rules={[{ type: "email" }]}
                        disabled={isReadOnly}
                        fieldProps={fieldStyle}
                    />
                </Col>
                <Col span={12}>
                    <ProFormText name="phone" label="연락처" disabled={isReadOnly} fieldProps={fieldStyle} />
                </Col>
            </Row>
        </>
    );
};

export default PersonnelInfoSection;
