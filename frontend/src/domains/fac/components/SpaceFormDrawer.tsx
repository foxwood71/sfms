import { ClusterOutlined, SaveOutlined } from "@ant-design/icons";
import {
    DrawerForm,
    ProForm,
    ProFormDigit,
    ProFormSwitch,
    ProFormText,
    ProFormTextArea,
} from "@ant-design/pro-components";
import type { TreeSelectProps } from "antd";
import { Button, Col, Row, TreeSelect, Typography, theme } from "antd";
import type React from "react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import CodeSelect from "@/domains/usr/components/CodeSelect";
import OrgTreeSelect from "@/domains/usr/components/OrgTreeSelect";
import type { SpaceParams, Space as SpaceType } from "../types";

const { Title, Text } = Typography;

interface SpaceFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingSpace: SpaceType | null;
    facilityName: string;
    parentTreeData: TreeSelectProps["treeData"]; // 부모 선택용 트리 데이터
    onFinish: (values: SpaceParams) => Promise<boolean>;
}

/**
 * 공간 등록/수정용 드로어 컴포넌트 (i18n 적용)
 */
const SpaceFormDrawer: React.FC<SpaceFormDrawerProps> = ({
    open,
    onOpenChange,
    editingSpace,
    facilityName,
    parentTreeData,
    onFinish,
}) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [form] = ProForm.useForm();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

    const watchedName = ProForm.useWatch("name", form);

    useEffect(() => {
        if (open) {
            if (editingSpace?.id) {
                setMode("view");
                form.setFieldsValue(editingSpace);
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({
                    is_active: true,
                    sort_order: 10,
                    is_restricted: false,
                    ...editingSpace, // parent_id 등이 있으면 덮어씌움
                });
            }
        }
    }, [open, editingSpace, form]);

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
                    ? t("fac.space.detail_title")
                    : mode === "edit"
                        ? t("common.edit")
                        : t("fac.space.new_space")
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
                                onClick={() => (editingSpace ? setMode("view") : onOpenChange(false))}
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
            drawerProps={{ destroyOnHidden: true, width: 550 }}
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
                <ClusterOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
                <div>
                    <Title level={4} style={{ margin: 0 }}>
                        {watchedName || t("fac.space.name")}
                    </Title>
                    <Text type="secondary">
                        {facilityName} / {form.getFieldValue("code") || "SPACE_CODE"}
                    </Text>
                </div>
            </div>

            <ProForm.Item name="parent_id" label={t("fac.space.parent")}>
                <TreeSelect
                    showSearch
                    style={{ width: "100%" }}
                    dropdownStyle={{ maxHeight: 400, overflow: "auto" }}
                    placeholder={t("fac.space.parent_placeholder")}
                    allowClear
                    treeDefaultExpandAll
                    treeData={parentTreeData}
                    disabled={isReadOnly}
                    // 자기 자신과 그 하위 노드는 부모로 선택할 수 없도록 처리 (필요 시 로직 보강)
                />
            </ProForm.Item>

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText
                        name="code"
                        label={t("fac.space.code")}
                        disabled={mode !== "add"}
                        rules={[{ required: true }]}
                        fieldProps={fieldStyle}
                    />
                </Col>
                <Col span={12}>
                    <ProFormText
                        name="name"
                        label={t("fac.space.name")}
                        disabled={isReadOnly}
                        rules={[{ required: true }]}
                        fieldProps={fieldStyle}
                    />
                </Col>
            </Row>

            <Row gutter={16}>
                <Col span={12}>
                    <ProForm.Item name="space_type_id" label={t("fac.space.type")}>
                        <CodeSelect groupCode="SPACE_TYPE" disabled={isReadOnly} />
                    </ProForm.Item>
                </Col>
                <Col span={12}>
                    <ProForm.Item name="space_function_id" label={t("fac.space.function")}>
                        <CodeSelect groupCode="SPACE_FUNC" disabled={isReadOnly} />
                    </ProForm.Item>
                </Col>
            </Row>

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormDigit
                        name="area_size"
                        label={t("fac.space.area")}
                        disabled={isReadOnly}
                        fieldProps={fieldStyle}
                    />
                </Col>
                <Col span={12}>
                    <ProFormDigit
                        name="sort_order"
                        label={t("fac.facility.sort_order")}
                        disabled={isReadOnly}
                        fieldProps={fieldStyle}
                    />
                </Col>
            </Row>

            <ProForm.Item name="org_id" label={t("fac.space.org")}>
                <OrgTreeSelect disabled={isReadOnly} />
            </ProForm.Item>

            <Row gutter={16} style={{ marginTop: 8 }}>
                <Col span={12}>
                    <div
                        style={{
                            padding: "8px 16px",
                            borderRadius: 8,
                            background: token.colorFillAlter,
                            display: "flex",
                            justifyContent: "space-between",
                            alignItems: "center",
                        }}
                    >
                        <Text style={{ fontSize: "12px" }}>{t("fac.space.restricted")}</Text>
                        <ProFormSwitch name="is_restricted" noStyle disabled={isReadOnly} />
                    </div>
                </Col>
                <Col span={12}>
                    <div
                        style={{
                            padding: "8px 16px",
                            borderRadius: 8,
                            background: token.colorFillAlter,
                            display: "flex",
                            justifyContent: "space-between",
                            alignItems: "center",
                        }}
                    >
                        <Text style={{ fontSize: "12px" }}>{t("fac.facility.status")}</Text>
                        <ProFormSwitch name="is_active" noStyle disabled={isReadOnly} />
                    </div>
                </Col>
            </Row>

            <ProFormTextArea
                name="description"
                label={t("common.search_placeholder")}
                disabled={isReadOnly}
                style={{ marginTop: 16 }}
                fieldProps={{ autoSize: { minRows: 3 } }}
            />
        </DrawerForm>
    );
};

export default SpaceFormDrawer;
