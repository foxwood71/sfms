import { ClockCircleOutlined, EditOutlined, UploadOutlined, UserOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormSwitch, ProFormText } from "@ant-design/pro-components";
import { Avatar, Button, Checkbox, Col, Divider, message, Row, Space, theme, Upload } from "antd";
import dayjs from "dayjs";
import type React from "react";
import { useEffect, useState } from "react";
import { http } from "@/shared/api/http"; // 공용 http 클라이언트 임포트
import { useAuthStore } from "@/shared/stores/useAuthStore";
import type { CreateUserParams, UpdateUserParams, User } from "../types";
import CodeSelect from "./CodeSelect";
import OrgTreeSelect from "./OrgTreeSelect";

/**
 * TSDoc: 사용자 생성 및 수정 폼 드로어 Props 인터페이스
 */
interface UserFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingUser: User | null;
    initialOrgId?: number;
    onFinish: (values: any) => Promise<boolean>;
}

/**
 * 사용자 생성/수정 화면 (Right Drawer Layout)
 */
const UserFormDrawer: React.FC<UserFormDrawerProps> = ({ open, onOpenChange, editingUser, initialOrgId, onFinish }) => {
    const { token } = theme.useToken();
    const [form] = ProForm.useForm();
    const accessToken = useAuthStore((state) => state.accessToken);

    const [changePassword, setChangePassword] = useState(false);
    const [imageUrl, setImageUrl] = useState<string | undefined>(undefined);

    // [수정] 대상 사용자가 바뀌거나 드로어가 열릴 때 사진 주소를 동기화합니다.
    useEffect(() => {
        if (open) {
            if (editingUser?.profile_image_id) {
                setImageUrl(`/api/v1/cmm/attachments/${editingUser.profile_image_id}/download?token=${accessToken}`);
            } else {
                setImageUrl(undefined);
            }
            setChangePassword(false); // 비밀번호 변경 체크박스도 초기화
        }
    }, [open, editingUser, accessToken]);

    // 모드에 따른 제목 설정
    const title = editingUser ? "사용자 정보 상세 및 수정" : "신규 사용자 등록";

    // [해결책] customRequest를 통한 정밀한 업로드 제어 (http 클라이언트 사용)
    const handleCustomUpload = async (options: any) => {
        const { file, onSuccess, onError } = options;
        const formData = new FormData();
        formData.append("file", file);

        try {
            // 이미 인증 헤더가 포함된 http 클라이언트를 사용합니다.
            const res = await http.post(
                `/cmm/upload?domain_code=USR&resource_type=PROFILE&ref_id=${editingUser?.id || 0}`,
                formData,
                {
                    headers: { "Content-Type": "multipart/form-data" },
                },
            );

            const attachmentId = res.data?.data?.id;
            if (attachmentId) {
                form.setFieldValue("profile_image_id", attachmentId);
                setImageUrl(`/api/v1/cmm/attachments/${attachmentId}/download?token=${accessToken}`);
                onSuccess(res.data);
                message.success("사진 업로드 성공");
            }
        } catch (err: any) {
            onError(err);
            const errorMsg = err.response?.data?.message || err.message || "업로드 실패";
            message.error(`사진 업로드 실패: ${errorMsg}`);
        }
    };

    return (
        <DrawerForm
            title={title}
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            key={editingUser ? `edit-${editingUser.id}` : `new-${initialOrgId}`}
            onFinish={async (values) => {
                if (editingUser && !changePassword) {
                    delete values.new_password;
                }
                return onFinish(values);
            }}
            initialValues={
                editingUser
                    ? {
                          ...editingUser,
                          org_id: editingUser.org_id !== undefined ? Number(editingUser.org_id) : undefined,
                          pos: editingUser.metadata?.pos,
                          duty: editingUser.metadata?.duty,
                      }
                    : {
                          is_active: true,
                          org_id: initialOrgId !== undefined ? Number(initialOrgId) : undefined,
                      }
            }
            drawerProps={{
                destroyOnClose: true,
                maskClosable: false,
                width: 640,
            }}
            layout="vertical"
        >
            {/* 1. 프로필 이미지 영역 */}
            <div
                style={{
                    display: "flex",
                    alignItems: "center",
                    marginBottom: 24,
                    padding: "16px",
                    background: token.colorFillAlter,
                    borderRadius: token.borderRadiusLG,
                }}
            >
                <Space size={20}>
                    <Avatar size={80} icon={<UserOutlined />} src={imageUrl} />
                    <div>
                        <div style={{ fontWeight: 600, fontSize: "16px", marginBottom: 8 }}>
                            {editingUser ? `${editingUser.name} (${editingUser.login_id})` : "신규 프로필"}
                        </div>
                        <ProForm.Item name="profile_image_id" hidden noStyle />
                        <Upload
                            name="file"
                            customRequest={handleCustomUpload}
                            showUploadList={false}
                            disabled={!accessToken}
                        >
                            <Button icon={<UploadOutlined />} size="small" loading={!accessToken}>
                                {accessToken ? "사진 변경" : "인증 대기 중..."}
                            </Button>
                        </Upload>
                    </div>
                </Space>
            </div>

            <div style={{ marginBottom: 24 }}>
                <Divider
                    orientation="left"
                    style={{ margin: "0 0 16px 0", fontSize: "14px", color: token.colorTextSecondary }}
                >
                    기본 계정 정보
                </Divider>
                <Row gutter={16}>
                    <Col span={12}>
                        <ProFormText
                            name="login_id"
                            label="로그인 ID"
                            placeholder="아이디 입력"
                            rules={[{ required: true, message: "로그인 ID를 입력하세요." }]}
                            disabled={!!editingUser}
                        />
                    </Col>
                    <Col span={12}>
                        {editingUser ? (
                            <div style={{ padding: "4px 0" }}>
                                <Checkbox
                                    checked={changePassword}
                                    onChange={(e) => setChangePassword(e.target.checked)}
                                >
                                    비밀번호 변경
                                </Checkbox>
                                {changePassword && (
                                    <ProFormText.Password
                                        name="new_password"
                                        placeholder="새 비밀번호 입력"
                                        rules={[{ required: true, message: "비밀번호를 입력하세요." }]}
                                        noStyle
                                    />
                                )}
                            </div>
                        ) : (
                            <ProFormText.Password
                                name="password"
                                label="비밀번호"
                                placeholder="8자 이상 입력"
                                rules={[{ required: true, message: "비밀번호를 입력하세요." }]}
                            />
                        )}
                    </Col>
                </Row>
                <Row gutter={16}>
                    <Col span={12}>
                        <ProFormText
                            name="name"
                            label="성명"
                            placeholder="성명을 입력하세요"
                            rules={[{ required: true, message: "성명을 입력하세요." }]}
                        />
                    </Col>
                    <Col span={12}>
                        <ProFormText
                            name="emp_code"
                            label="사번"
                            placeholder="사번 입력"
                            rules={[{ required: true, message: "사번을 입력하세요." }]}
                        />
                    </Col>
                </Row>
            </div>

            <div style={{ marginBottom: 24 }}>
                <Divider
                    orientation="left"
                    style={{ margin: "0 0 16px 0", fontSize: "14px", color: token.colorTextSecondary }}
                >
                    인사 / 부서 정보
                </Divider>
                <Row gutter={16}>
                    <Col span={24}>
                        <ProForm.Item
                            name="org_id"
                            label="소속 부서"
                            rules={[{ required: true, message: "부서를 선택하세요." }]}
                        >
                            <OrgTreeSelect />
                        </ProForm.Item>
                    </Col>
                </Row>
                <Row gutter={16}>
                    <Col span={12}>
                        <ProForm.Item name="pos" label="직위/직급">
                            <CodeSelect groupCode="POS_TYPE" />
                        </ProForm.Item>
                    </Col>
                    <Col span={12}>
                        <ProForm.Item name="duty" label="직책">
                            <CodeSelect groupCode="DUTY_TYPE" />
                        </ProForm.Item>
                    </Col>
                </Row>
                <Row gutter={16}>
                    <Col span={24}>
                        <ProFormText
                            name="email"
                            label="이메일"
                            placeholder="이메일 입력"
                            rules={[{ type: "email", message: "이메일 형식이 올바르지 않습니다." }]}
                        />
                    </Col>
                </Row>
                <Row gutter={16}>
                    <Col span={12}>
                        <ProFormText name="phone" label="연락처" placeholder="연락처 입력" />
                    </Col>
                    <Col span={12}>
                        <ProFormSwitch
                            name="is_active"
                            label="재직 상태"
                            checkedChildren="재직"
                            unCheckedChildren="퇴사"
                        />
                    </Col>
                </Row>
            </div>

            {editingUser && (
                <div
                    style={{
                        marginTop: 24,
                        padding: "16px",
                        borderTop: `1px solid ${token.colorBorderSecondary}`,
                        fontSize: "12px",
                        color: token.colorTextDescription,
                    }}
                >
                    <Row gutter={16}>
                        <Col span={12}>
                            <Space>
                                <ClockCircleOutlined />
                                <span>
                                    생성:{" "}
                                    {editingUser.created_at
                                        ? dayjs(editingUser.created_at).format("YYYY-MM-DD HH:mm")
                                        : "-"}
                                </span>
                            </Space>
                        </Col>
                        <Col span={12}>
                            <Space>
                                <EditOutlined />
                                <span>
                                    수정:{" "}
                                    {editingUser.updated_at
                                        ? dayjs(editingUser.updated_at).format("YYYY-MM-DD HH:mm")
                                        : "-"}
                                </span>
                            </Space>
                        </Col>
                    </Row>
                </div>
            )}
        </DrawerForm>
    );
};

export default UserFormDrawer;
