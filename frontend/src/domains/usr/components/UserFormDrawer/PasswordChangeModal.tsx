import { LockOutlined } from "@ant-design/icons";
import { ModalForm, ProFormText } from "@ant-design/pro-components";
import { App, Space } from "antd";
import type React from "react";
import { changePasswordApi } from "@/domains/usr/api";
import { MESSAGES } from "@/shared/locales/i18n-utils";

interface PasswordChangeModalProps {
    userId: number;
    userName: string;
    open: boolean;
    onOpenChange: (open: boolean) => void;
}

const PasswordChangeModal: React.FC<PasswordChangeModalProps> = ({
    userId,
    userName,
    open,
    onOpenChange,
}) => {
    const { message } = App.useApp();

    return (
        <ModalForm
            title={
                <Space>
                    <LockOutlined />
                    <span>{userName} 비밀번호 재설정</span>
                </Space>
            }
            open={open}
            onOpenChange={onOpenChange}
            width={360}
            modalProps={{ destroyOnHidden: true, centered: true, maskClosable: false }}
            onFinish={async (values) => {
                try {
                    await changePasswordApi(userId, { new_password: values.new_password });
                    message.success(MESSAGES.USR.PWD_RESET_SUCCESS);
                    return true;
                } catch (err) {
                    message.error(MESSAGES.COMMON.SAVE_FAILURE);
                    return false;
                }
            }}
        >
            <ProFormText.Password
                name="new_password"
                label="새 비밀번호"
                placeholder="최소 8자 이상"
                rules={[
                    { required: true, message: "새 비밀번호를 입력해주세요." },
                    { min: 8, message: "비밀번호는 최소 8자 이상이어야 합니다." },
                ]}
                fieldProps={{ autoComplete: "new-password" }}
            />
            <ProFormText.Password
                name="confirm_password"
                label="비밀번호 확인"
                placeholder="다시 한번 입력"
                dependencies={["new_password"]}
                rules={[
                    { required: true, message: "비밀번호 확인을 입력해주세요." },
                    ({ getFieldValue }) => ({
                        validator(_, value) {
                            if (!value || getFieldValue("new_password") === value) {
                                return Promise.resolve();
                            }
                            return Promise.reject(new Error("비밀번호가 일치하지 않습니다."));
                        },
                    }),
                ]}
            />
        </ModalForm>
    );
};

export default PasswordChangeModal;
