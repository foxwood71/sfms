import { CloseOutlined, EditOutlined, FolderOutlined, SaveOutlined, SettingOutlined } from "@ant-design/icons";
import {
    DrawerForm,
    ProForm,
    ProFormDigit,
    ProFormSelect,
    ProFormText,
    ProFormTextArea,
} from "@ant-design/pro-components";
import { Button, Card, Col, Divider, Row, Space, Switch, Typography, theme } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
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
 * Bento Standard v1.1 및 도메인 분류 필드 추가
 */
const CodeGroupDrawer: React.FC<CodeGroupDrawerProps> = ({ open, onOpenChange, editingGroup, onFinish }) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [form] = ProForm.useForm<CodeGroupParams>();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

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
                    domain_code: "CMM",
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
        <DrawerForm<CodeGroupParams>
            title={
                mode === "view"
                    ? t("cmm.code.detail_title")
                    : mode === "edit"
                      ? t("cmm.code.edit_group")
                      : t("cmm.code.new_group")
            }
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            onFinish={onFinish}
            submitter={{
                render: (props) =>
                    mode === "view"
                        ? [
                              <Button key="close" onClick={() => onOpenChange(false)}>
                                  {t("common.confirm")}
                              </Button>,
                              <Button key="edit" type="primary" icon={<EditOutlined />} onClick={() => setMode("edit")}>
                                  {t("common.edit")}
                              </Button>,
                          ]
                        : [
                              <Button
                                  key="cancel"
                                  onClick={() => (editingGroup ? setMode("view") : onOpenChange(false))}
                                  icon={<CloseOutlined />}
                              >
                                  {editingGroup ? t("common.cancel") : t("common.cancel")}
                              </Button>,
                              <Button
                                  key="submit"
                                  type="primary"
                                  icon={<SaveOutlined />}
                                  onClick={() => props.form?.submit()}
                              >
                                  {editingGroup ? t("common.save") : t("common.confirm")}
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
                        {watchedName || t("cmm.code.new_group")}
                    </Title>
                    <Text type="secondary">{watchedCode || "GROUP_CODE"}</Text>
                </div>
            </div>

            <Row gutter={16}>
                <Col span={24}>
                    <ProFormSelect
                        name="domain_code"
                        label="도메인 분류"
                        disabled={mode === "view"}
                        placeholder="코드가 속할 도메인을 선택하세요"
                        rules={[{ required: true }]}
                        fieldProps={fieldStyle}
                        options={[
                            { value: "CMM", label: t("cmm.code.domain_cmm") },
                            { value: "USR", label: t("cmm.code.domain_usr") },
                            { value: "FAC", label: t("cmm.code.domain_fac") },
                            { value: "SYS", label: t("cmm.code.domain_sys") },
                        ]}
                    />
                </Col>
            </Row>

            <Row gutter={16} style={{ marginTop: 16 }}>
                <Col span={12}>
                    <ProFormText
                        name="group_code"
                        label={t("cmm.code.group_code")}
                        disabled={mode !== "add"}
                        fieldProps={fieldStyle}
                        rules={[{ required: true }]}
                        placeholder="영문 대문자"
                    />
                </Col>
                <Col span={12}>
                    <ProFormText
                        name="group_name"
                        label={t("cmm.code.group_name")}
                        disabled={mode === "view"}
                        fieldProps={fieldStyle}
                        rules={[{ required: true }]}
                    />
                </Col>
            </Row>

            <ProFormTextArea
                name="description"
                label={t("common.description")}
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
                                    <ProForm.Item name="is_active" noStyle valuePropName="checked">
                                        {" "}
                                        {/* is_active 중복 참조 방지를 위해 로직 확인 필요 */}
                                        <ProForm.Item name="is_seq_used" noStyle valuePropName="checked">
                                            <Switch size="small" disabled={mode === "view"} />
                                        </ProForm.Item>
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
                <Text
                    strong
                    style={{
                        color: watchedActive ? token.colorSuccess : token.colorTextDisabled,
                    }}
                >
                    그룹 활성화 상태: {watchedActive ? t("common.active") : t("common.inactive")}
                </Text>
                <ProForm.Item name="is_active" noStyle valuePropName="checked">
                    <Switch size="small" disabled={mode === "view"} />
                </ProForm.Item>
            </div>
        </DrawerForm>
    );
};

export default CodeGroupDrawer;
