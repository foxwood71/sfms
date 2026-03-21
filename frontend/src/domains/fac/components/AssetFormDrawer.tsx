import { SaveOutlined, BuildOutlined, ClusterOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormText, ProFormTextArea, ProFormDigit, ProFormSwitch } from "@ant-design/pro-components";
import { Button, Col, Row, Space, Typography, theme, TreeSelect, Form } from "antd";
import type React from "react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import OrgTreeSelect from "@/domains/usr/components/OrgTreeSelect";
import CodeSelect from "@/domains/usr/components/CodeSelect";

const { Title, Text } = Typography;

interface AssetFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingNode: { type: "FAC" | "SPC", data: any } | null;
    onFinish: (values: any) => Promise<boolean>;
}

/**
 * 시설 및 공간 통합 등록/수정 드로어
 */
const AssetFormDrawer: React.FC<AssetFormDrawerProps> = ({
    open,
    onOpenChange,
    editingNode,
    onFinish,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [form] = Form.useForm();
    const [mode, setMode] = useState<"add" | "edit">("add");

    // 폼 내부의 name 필드 실시간 감시 (경고 방지)
    const nameValue = Form.useWatch("name", form);

    // 드로어가 열릴 때 폼 초기화
    useEffect(() => {
        if (open) {
            if (editingNode?.data?.id) {
                setMode("edit");
                form.setFieldsValue(editingNode.data);
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({ 
                    is_active: true, 
                    sort_order: 10,
                    ...editingNode?.data 
                });
            }
        }
    }, [open, editingNode, form]);

    const isFac = editingNode?.type === "FAC";
    const title = mode === "add" 
        ? (isFac ? t("fac.facility.new_facility") : t("fac.space.new_space"))
        : (isFac ? t("fac.facility.detail_title") : t("fac.space.detail_title"));

    // 타이틀에 표시할 이름 결정
    const displayHeaderName = nameValue || editingNode?.data?.name || (isFac ? t("fac.facility.name") : t("fac.space.name"));

    return (
        <DrawerForm
            title={title}
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            onFinish={onFinish}
            drawerProps={{ 
                destroyOnClose: true, 
                width: 550,
                afterOpenChange: (visible) => {
                    if (!visible) form.resetFields();
                }
            }}
            layout="vertical"
        >
            <div style={{ display: "flex", alignItems: "center", gap: "16px", marginBottom: 32, padding: "16px", background: token.colorFillAlter, borderRadius: 12 }}>
                {isFac ? <BuildOutlined style={{ fontSize: 32, color: token.colorPrimary }} /> : <ClusterOutlined style={{ fontSize: 32, color: token.colorPrimary }} />}
                <div>
                    <Title level={4} style={{ margin: 0 }}>
                        {displayHeaderName}
                    </Title>
                    <Text type="secondary">{isFac ? "Facility Asset" : "Space Asset"}</Text>
                </div>
            </div>

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText name="code" label={t("common.code")} rules={[{ required: true }]} disabled={mode === "edit"} />
                </Col>
                <Col span={12}>
                    <ProFormText name="name" label={t("common.name")} rules={[{ required: true }]} />
                </Col>
            </Row>

            {isFac ? (
                // 시설 전용 필드
                <ProFormText name="address" label={t("fac.facility.address")} />
            ) : (
                // 공간 전용 필드
                <>
                    <Row gutter={16}>
                        <Col span={12}>
                            <ProForm.Item name="space_type_id" label={t("fac.space.type")}>
                                <CodeSelect groupCode="SPACE_TYPE" />
                            </ProForm.Item>
                        </Col>
                        <Col span={12}>
                            <ProForm.Item name="space_function_id" label={t("fac.space.function")}>
                                <CodeSelect groupCode="SPACE_FUNC" />
                            </ProForm.Item>
                        </Col>
                    </Row>
                    <Row gutter={16}>
                        <Col span={12}>
                            <ProFormDigit name="area_size" label={t("fac.space.area")} />
                        </Col>
                        <Col span={12}>
                            <ProFormDigit name="sort_order" label={t("fac.facility.sort_order")} />
                        </Col>
                    </Row>
                    <ProForm.Item name="org_id" label={t("fac.space.org")}>
                        <OrgTreeSelect />
                    </ProForm.Item>
                </>
            )}

            <Row gutter={16} style={{ marginTop: 8 }}>
                <Col span={12}>
                    <div style={{ padding: "8px 16px", borderRadius: 8, background: token.colorFillAlter, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                        <Text>{t("common.status")}</Text>
                        <ProFormSwitch name="is_active" noStyle />
                    </div>
                </Col>
                {!isFac && (
                    <Col span={12}>
                        <div style={{ padding: "8px 16px", borderRadius: 8, background: token.colorFillAlter, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                            <Text>{t("fac.space.restricted")}</Text>
                            <ProFormSwitch name="is_restricted" noStyle />
                        </div>
                    </Col>
                )}
            </Row>

            <ProFormTextArea name={["metadata_info", "description"]} label={t("common.description")} style={{ marginTop: 16 }} />
        </DrawerForm>
    );
};

export default AssetFormDrawer;
