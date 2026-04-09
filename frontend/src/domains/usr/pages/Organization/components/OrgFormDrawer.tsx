import { DrawerForm, ProFormSwitch, ProFormText, ProFormTextArea } from "@ant-design/pro-components";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { App, Form } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { createOrganizationApi, updateOrganizationApi } from "@/domains/usr/api";
import type { CreateOrgParams, Organization, UpdateOrgParams } from "@/domains/usr/types";
import OrgTreeSelect from "@/domains/usr/components/OrgTreeSelect";

interface OrgFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    isAdding: boolean;
    editingOrg: Organization | null;
    initialParentId?: string | null;
}

const OrgFormDrawer: React.FC<OrgFormDrawerProps> = ({
    open,
    onOpenChange,
    isAdding,
    editingOrg,
    initialParentId,
}) => {
    const { t } = useTranslation();
    const { message } = App.useApp();
    const queryClient = useQueryClient();
    const [form] = Form.useForm();

    const saveOrgMutation = useMutation({
        mutationFn: (values: CreateOrgParams | UpdateOrgParams) => {
            const payload = { ...values, parent_id: values.parent_id ? Number(values.parent_id) : null };
            return isAdding
                ? createOrganizationApi(payload as CreateOrgParams)
                : updateOrganizationApi(Number(editingOrg?.id), payload as UpdateOrgParams);
        },
        onSuccess: () => {
            message.success(t("common.save_success"));
            onOpenChange(false);
            queryClient.invalidateQueries({ queryKey: ["organizations"] });
        },
    });

    return (
        <DrawerForm<CreateOrgParams>
            title={isAdding ? t("org.new_org") : t("org.edit_group")}
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            initialValues={
                isAdding
                    ? { parent_id: initialParentId, is_active: true }
                    : editingOrg || { is_active: true }
            }
            onFinish={async (v) => {
                await saveOrgMutation.mutateAsync(v);
                return true;
            }}
            drawerProps={{ destroyOnClose: true, width: 500 }}
        >
            <Form.Item name="parent_id" label={t("org.parent")}>
                <OrgTreeSelect />
            </Form.Item>
            <ProFormText name="name" label={t("org.name")} rules={[{ required: true }]} />
            <ProFormText name="code" label={t("org.code")} rules={[{ required: true }]} disabled={!isAdding} />
            <ProFormTextArea name="description" label={t("common.description")} />
            <ProFormSwitch name="is_active" label={t("common.status")} />
        </DrawerForm>
    );
};

export default OrgFormDrawer;
