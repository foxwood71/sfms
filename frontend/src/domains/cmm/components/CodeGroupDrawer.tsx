import { CloseOutlined, EditOutlined, FolderOutlined, SaveOutlined, SettingOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormDigit, ProFormText, ProFormTextArea } from "@ant-design/pro-components";
import { Button, Card, Col, Divider, Row, Space, Switch, Typography, theme } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import type { CodeGroup, CodeGroupParams } from "../types";

const { Title, Text } = Typography;

interface CodeGroupDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingGroup: CodeGroup | null;
    onFinish: (values: CodeGroupParams) => Promise<boolean>;
}

/**
 * 공통 코드 그룹 관리 드로어
 * Bento Standard v1.1 및 Zero Any Policy 적용
 */
const CodeGroupDrawer: React.FC<CodeGroupDrawerProps> = ({ open, onOpenChange, editingGroup, onFinish }) => {
    const { token } = theme.useToken();
    const [form] = ProForm.useForm<CodeGroup>();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

    // form.getFieldValue 대신 useWatch를 사용하여 "not connected" 경고 방지
    const watchedName = ProForm.useWatch("group_name", form);
    const watchedCode = ProForm.useWatch("group_code", form);
    const watchedActive = ProForm.useWatch("is_active", form);

    useEffect(() => {
        if (open) {
            if (editingGroup) {
                setMode("view");
                form.setFieldsValue(editingGroup);
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({
                    is_active: true,
                    code_length: 3,
                    is_seq_used: false,
                });
            }
        }
    }, [open, editingGroup, form]);

    const fieldStyle = useMemo(
        () => ({
            style: {
                height: "32px",
                color: mode === "view" ? token.colorText : undefined,
                fontWeight: mode === "view" ? 500 : undefined,
            },
        }),
        [mode, token],
    );

    return (
        <DrawerForm<CodeGroup>
            title={mode === "view" ? "코드 그룹 상세" : mode === "edit" ? "코드 그룹 수정" : "새 코드 그룹 등록"}
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            onFinish={onFinish}
            submitter={{
                render: (props) =>
                    mode === "view"
                        ? [
                              <Button key="close" onClick={() => onOpenChange(false)}>
                                  닫기
                              </Button>,
                              <Button key="edit" type="primary" icon={<EditOutlined />} onClick={() => setMode("edit")}>
                                  수정하기
                              </Button>,
                          ]
                        : [
                              <Button
                                  key="cancel"
                                  onClick={() => (editingGroup ? setMode("view") : onOpenChange(false))}
                                  icon={<CloseOutlined />}
                              >
                                  {editingGroup ? "수정 취소" : "취소"}
                              </Button>,
                              <Button
                                  key="submit"
                                  type="primary"
                                  icon={<SaveOutlined />}
                                  onClick={() => props.form?.submit()}
                              >
                                  {editingGroup ? "수정 완료" : "등록 완료"}
                              </Button>,
                          ],
            }}
            drawerProps={{
                destroyOnClose: true,
                maskClosable: mode === "view",
                width: 550,
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
					background-color: ${mode === "view" ? token.colorFillQuaternary : undefined} !important;
				}
			`}</style>

            {/* 헤더 섹션 */}
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "16px",
                    marginBottom: 32,
                    padding: "16px",
                    background: token.colorFillAlter,
                    borderRadius: 12,
                }}
            >
                <div
                    style={{
                        width: 48,
                        height: 48,
                        borderRadius: 10,
                        background: token.colorPrimaryBg,
                        display: "flex",
                        justifyContent: "center",
                        alignItems: "center",
                    }}
                >
                    <FolderOutlined style={{ fontSize: 24, color: token.colorPrimary }} />
                </div>
                <div>
                    <Title level={4} style={{ margin: 0 }}>
                        {watchedName || "새 그룹"}
                    </Title>
                    <Text type="secondary">{watchedCode || "GROUP_CODE"}</Text>
                </div>
            </div>

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText
                        name="group_code"
                        label="그룹 코드"
                        disabled={mode !== "add"}
                        fieldProps={fieldStyle}
                        rules={[{ required: true }]}
                        placeholder="영문 대문자"
                    />
                </Col>
                <Col span={12}>
                    <ProFormText
                        name="group_name"
                        label="그룹 명칭"
                        disabled={mode === "view"}
                        fieldProps={fieldStyle}
                        rules={[{ required: true }]}
                    />
                </Col>
            </Row>

            <ProFormTextArea
                name="description"
                label="상세 설명"
                disabled={mode === "view"}
                fieldProps={{
                    style: {
                        color: mode === "view" ? token.colorText : undefined,
                        fontWeight: mode === "view" ? 500 : undefined,
                    },
                    autoSize: { minRows: 3, maxRows: 6 },
                }}
            />

            <div style={{ marginTop: 24 }}>
                <Divider orientation="left" style={{ margin: "0 0 16px 0" }}>
                    <Space size={4}>
                        <SettingOutlined /> <Text strong>코드 생성 규격 설정</Text>
                    </Space>
                </Divider>

                {/* bordered 대신 variant="outlined" 사용 (v5 대응) */}
                <Card
                    size="small"
                    variant="outlined"
                    styles={{ body: { padding: "16px" } }}
                    style={{ background: token.colorFillQuaternary }}
                >
                    <Row gutter={24} align="middle">
                        <Col span={12}>
                            <ProFormDigit
                                name="code_length"
                                label="권장 코드 길이"
                                min={0}
                                max={20}
                                disabled={mode === "view"}
                                fieldProps={{ ...fieldStyle, style: { width: "100%" } }}
                                tooltip="분류 코드로 사용할 영문 약어의 길이입니다. (예: STP=3자)"
                            />
                        </Col>
                        <Col span={12}>
                            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                                <Text strong style={{ fontSize: "14px" }}>
                                    자산코드 순번 사용
                                </Text>
                                <Space>
                                    <ProForm.Item name="is_seq_used" noStyle valuePropName="checked">
                                        <Switch size="small" disabled={mode === "view"} />
                                    </ProForm.Item>
                                    <Text type="secondary">분류코드 + 001 형식 사용</Text>
                                </Space>
                            </div>
                        </Col>
                    </Row>
                </Card>
            </div>

            {/* 상태 바 */}
            <div
                style={{
                    marginTop: 32,
                    padding: "12px 16px",
                    borderRadius: 8,
                    border: `1px solid ${watchedActive ? token.colorSuccessBorder : token.colorBorderSecondary}`,
                    background: watchedActive ? token.colorSuccessBg : token.colorFillQuaternary,
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                }}
            >
                <Text strong style={{ color: watchedActive ? token.colorSuccess : token.colorTextDisabled }}>
                    그룹 활성화 상태: {watchedActive ? "사용 중" : "중지됨"}
                </Text>
                <ProForm.Item name="is_active" noStyle valuePropName="checked">
                    <Switch size="small" disabled={mode === "view"} />
                </ProForm.Item>
            </div>
        </DrawerForm>
    );
};

export default CodeGroupDrawer;
