import { BuildOutlined, SaveOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormDigit, ProFormText, ProFormTextArea } from "@ant-design/pro-components";
import { Button, Col, Row, Space, Switch, Typography, theme } from "antd";
import type React from "react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Facility, FacilityParams } from "../types";

const { Title, Text } = Typography;

interface FacilityFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingFacility: Facility | null;
    onFinish: (values: FacilityParams) => Promise<boolean>;
}

/**
 * 시설물 등록/수정용 드로어 컴포넌트 (i18n 적용)
 */
const FacilityFormDrawer: React.FC<FacilityFormDrawerProps> = ({ open, onOpenChange, editingFacility, onFinish }) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [form] = ProForm.useForm();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

    const watchedName = ProForm.useWatch("name", form);
    const watchedActive = ProForm.useWatch("is_active", form);

    useEffect(() => {
        if (open) {
            if (editingFacility) {
                setMode("view");
                form.setFieldsValue(editingFacility);
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({ is_active: true, sort_order: 10 });
            }
        }
    }, [open, editingFacility, form]);

    const isReadOnly = mode === "view";
    const fieldStyle = {
        style: {
            height: "32px",
            color: isReadOnly ? token.colorText : undefined,
            fontWeight: isReadOnly ? 500 : undefined,
        },
    };

    return (
        <DrawerForm
            title={
                mode === "view"
                    ? t("fac.facility.detail_title")
                    : mode === "edit"
                        ? t("common.edit")
                        : t("fac.facility.new_facility")
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
                            <Button key="edit" type="primary" onClick={() => setMode("edit")}>
                                {t("common.edit")}
                            </Button>,
                        ]
                        : [
                            <Button
                                key="cancel"
                                onClick={() => (editingFacility ? setMode("view") : onOpenChange(false))}
                            >
                                {t("common.cancel")}
                            </Button>,
                            <Button
                                key="submit"
                                type="primary"
                                icon={<SaveOutlined />}
                                onClick={() => props.form?.submit()}
                            >
                                {t("common.save")}
                            </Button>,
                        ],
            }}
            drawerProps={{ destroyOnHidden: true, width: 500 }}
            layout="vertical"
        >
            <style>{`
                .ant-input-disabled, .ant-select-disabled .ant-select-selection-item {
                    color: ${token.colorText} !important;
                    -webkit-text-fill-color: ${token.colorText} !important;
                }
            `}</style>

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
                <BuildOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
                <div>
                    <Title level={4} style={{ margin: 0 }}>
                        {watchedName || t("fac.facility.name")}
                    </Title>
                    <Text type="secondary">{form.getFieldValue("code") || "FACILITY_CODE"}</Text>
                </div>
            </div>

            <ProFormText
                name="code"
                label={t("fac.facility.code")}
                disabled={mode !== "add"}
                rules={[{ required: true }]}
                fieldProps={fieldStyle}
            />
            <ProFormText
                name="name"
                label={t("fac.facility.name")}
                disabled={isReadOnly}
                rules={[{ required: true }]}
                fieldProps={fieldStyle}
            />
            <ProFormText
                name="address"
                label={t("fac.facility.address")}
                disabled={isReadOnly}
                fieldProps={fieldStyle}
            />

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormDigit
                        name="sort_order"
                        label={t("fac.facility.sort_order")}
                        disabled={isReadOnly}
                        fieldProps={fieldStyle}
                    />
                </Col>
                <Col span={12}>
                    <ProForm.Item name="is_active" label={t("fac.facility.status")}>
                        <Space>
                            <Switch
                                checked={watchedActive}
                                disabled={isReadOnly}
                                size="small"
                                onChange={(val) => form.setFieldValue("is_active", val)}
                            />
                            <Text>{watchedActive ? t("common.active") : t("common.inactive")}</Text>
                        </Space>
                    </ProForm.Item>
                </Col>
            </Row>

            <ProFormTextArea
                name="description"
                label={t("common.search_placeholder")}
                disabled={isReadOnly}
                fieldProps={{ autoSize: { minRows: 3 } }}
            />
        </DrawerForm>
    );
};

export default FacilityFormDrawer;
