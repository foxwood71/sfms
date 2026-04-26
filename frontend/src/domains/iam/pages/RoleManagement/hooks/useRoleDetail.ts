import { Form } from "antd";
import { useEffect } from "react";
import type { Role, RoleCreate, RoleUpdate } from "../../types/role";

interface UseRoleDetailProps {
  role: Role | null;
  onSave: (data: RoleCreate | RoleUpdate) => void;
}

export const useRoleDetail = ({ role, onSave }: UseRoleDetailProps) => {
  const [form] = Form.useForm();

  // 선택된 역할이 변경될 때마다 폼 값 동기화
  useEffect(() => {
    if (role) {
      form.setFieldsValue({
        ...role,
        permissions: role.permissions || {},
      });
    } else {
      form.resetFields();
      form.setFieldsValue({
        permissions: {},
        is_active: true,
      });
    }
  }, [role, form]);

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields();
      onSave(values);
    } catch (error) {
      console.error("Validation failed:", error);
    }
  };

  return {
    form,
    handleSubmit,
  };
};
