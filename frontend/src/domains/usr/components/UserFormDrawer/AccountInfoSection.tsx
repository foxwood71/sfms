import { ProFormText } from "@ant-design/pro-components";
import { Col, Divider, Row, theme } from "antd";
import type React from "react";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";

interface AccountInfoSectionProps {
    mode: "view" | "edit" | "add";
    isReadOnly: boolean;
    fieldStyle: { style: React.CSSProperties };
    onEmpCodeChange: (val: string) => void;
}

const AccountInfoSection: React.FC<AccountInfoSectionProps> = ({
    mode,
    isReadOnly,
    fieldStyle,
    onEmpCodeChange,
}) => {
    const { token } = theme.useToken();

    return (
        <>
            <Divider
                orientation="left"
                style={{
                    margin: "0 0 16px 0",
                    fontSize: "13px",
                    color: token.colorTextSecondary,
                    fontWeight: 600,
                }}
            >
                기본 계정 정보
            </Divider>
            <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                <Col span={12}>
                    <ProFormText
                        name="login_id"
                        label="로그인 ID"
                        disabled={mode !== "add"}
                        fieldProps={fieldStyle}
                        rules={
                            mode === "add"
                                ? [
                                      {
                                          required: true,
                                          min: 4,
                                          message: "4자 이상 입력해주세요",
                                      },
                                  ]
                                : []
                        }
                        placeholder={mode === "add" ? "사용할 ID 입력" : ""}
                    />
                </Col>
                <Col span={12}>
                    <ProFormText
                        name="name"
                        label="성명"
                        rules={[{ required: true }]}
                        disabled={isReadOnly}
                        fieldProps={fieldStyle}
                    />
                </Col>
            </Row>
            <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                <Col span={12}>
                    <ProFormText
                        name="emp_code"
                        label="사번"
                        rules={[
                            { required: true, message: "사번을 입력해주세요" },
                            {
                                pattern: /^[A-Z0-9_-]+$/,
                                message: "영문 대문자, 숫자, _, -만 입력 가능합니다",
                            },
                        ]}
                        fieldProps={{
                            ...fieldStyle,
                            placeholder: "예: GUMC-001",
                            onChange: (e) => {
                                const val = e.target.value.toUpperCase().replace(/[^A-Z0-9_-]/g, "");
                                onEmpCodeChange(val);
                            },
                        }}
                        disabled={isReadOnly}
                    />
                </Col>
                {mode === "add" && (
                    <Col span={12}>
                        <ProFormText.Password
                            name="password"
                            label="초기 비밀번호"
                            rules={[{ required: true, min: 8 }]}
                            fieldProps={{ ...fieldStyle, autoComplete: "new-password" }}
                        />
                    </Col>
                )}
            </Row>
        </>
    );
};

export default AccountInfoSection;
