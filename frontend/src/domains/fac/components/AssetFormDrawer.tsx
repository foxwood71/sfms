import { BuildOutlined, ClusterOutlined } from "@ant-design/icons";
import {
    DrawerForm,
    ProForm,
    ProFormDigit,
    ProFormSelect,
    ProFormSwitch,
    ProFormText,
    ProFormTextArea,
} from "@ant-design/pro-components";
import { useQuery } from "@tanstack/react-query";
import { Col, Form, Row, Typography, theme } from "antd";
import type React from "react";
import { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import OrgTreeSelect from "@/domains/usr/components/OrgTreeSelect";
import { getFacilityCategoriesApi, getSpaceFunctionsApi, getSpaceTypesApi } from "../api";
import type {
    Facility,
    FacilityCategory,
    FacilityParams,
    SpaceFunction,
    SpaceParams,
    Space as SpaceType,
    SpaceType as SpaceTypeType,
} from "../types";

const { Title, Text } = Typography;

interface AssetFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingNode: { type: "FAC" | "SPC"; data: Facility | SpaceType | null } | null;
    onFinish: (values: FacilityParams | SpaceParams) => Promise<boolean>;
}

/**
 * 시설 및 공간 통합 등록/수정 드로어 (SFMS 차세대 표준 적용)
 */
const AssetFormDrawer: React.FC<AssetFormDrawerProps> = ({ open, onOpenChange, editingNode, onFinish }) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();
    const [form] = Form.useForm();
    const [mode, setMode] = useState<"add" | "edit">("add");

    // useWatch를 사용하여 "not connected" 경고 방지
    const watchedName = Form.useWatch("name", form);

    // 기초 코드 데이터 로딩
    const { data: categories } = useQuery({
        queryKey: ["fac-categories"],
        queryFn: getFacilityCategoriesApi,
        enabled: open,
        staleTime: 5 * 60 * 1000,
    });

    const { data: spaceTypes } = useQuery({
        queryKey: ["space-types"],
        queryFn: getSpaceTypesApi,
        enabled: open,
        staleTime: 5 * 60 * 1000,
    });

    const { data: spaceFunctions } = useQuery({
        queryKey: ["space-functions"],
        queryFn: getSpaceFunctionsApi,
        enabled: open,
        staleTime: 5 * 60 * 1000,
    });

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
                    ...editingNode?.data,
                });
            }
        }
    }, [open, editingNode, form]);

    const isFac = editingNode?.type === "FAC";
    const title =
        mode === "add"
            ? isFac
                ? t("fac.facility.new_facility")
                : t("fac.space.new_space")
            : isFac
              ? t("fac.facility.detail_title")
              : t("fac.space.detail_title");

    const displayHeaderName =
        watchedName || editingNode?.data?.name || (isFac ? t("fac.facility.name") : t("fac.space.name"));

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
            }}
            layout="vertical"
        >
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
                {isFac ? (
                    <BuildOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
                ) : (
                    <ClusterOutlined style={{ fontSize: 32, color: token.colorPrimary }} />
                )}
                <div>
                    <Title level={4} style={{ margin: 0 }}>
                        {displayHeaderName}
                    </Title>
                    <Text type="secondary">{isFac ? "Facility Asset" : "Space Asset"}</Text>
                </div>
            </div>

            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText
                        name="code"
                        label={t("common.code")}
                        placeholder={t("fac.manage.auto_generated")}
                        disabled={true}
                        tooltip={t("fac.manage.code_tooltip")}
                    />
                </Col>
                <Col span={12}>
                    <ProFormText name="name" label={t("common.name")} rules={[{ required: true }]} />
                </Col>
            </Row>

            {isFac ? (
                <>
                    <Row gutter={16}>
                        <Col span={24}>
                            <ProFormSelect
                                name="category_code"
                                label={t("fac.facility.category")}
                                options={
                                    categories?.data?.map((c: FacilityCategory) => ({
                                        label: c.name,
                                        value: c.code,
                                    })) || []
                                }
                                rules={[{ required: true }]}
                            />
                        </Col>
                    </Row>
                    <ProFormText name="address" label={t("fac.facility.address")} />
                </>
            ) : (
                <>
                    <Row gutter={16}>
                        <Col span={12}>
                            <ProFormSelect
                                name="space_type_code"
                                label={t("fac.space.type")}
                                options={
                                    spaceTypes?.data?.map((t: SpaceTypeType) => ({ label: t.name, value: t.code })) ||
                                    []
                                }
                                rules={[{ required: true }]}
                            />
                        </Col>
                        <Col span={12}>
                            <ProFormSelect
                                name="space_func_code"
                                label={t("fac.space.function")}
                                options={
                                    spaceFunctions?.data?.map((f: SpaceFunction) => ({
                                        label: f.name,
                                        value: f.code,
                                    })) || []
                                }
                                rules={[{ required: true }]}
                            />
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
                        <Text>{t("common.status")}</Text>
                        <ProFormSwitch name="is_active" noStyle />
                    </div>
                </Col>
                {!isFac && (
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
                            <Text>{t("fac.space.restricted")}</Text>
                            <ProFormSwitch name="is_restricted" noStyle />
                        </div>
                    </Col>
                )}
            </Row>

            <ProFormTextArea
                name={["metadata_info", "description"]}
                label={t("common.description")}
                style={{ marginTop: 16 }}
            />
        </DrawerForm>
    );
};

export default AssetFormDrawer;
