import { CloseOutlined, EditOutlined, SaveOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormSwitch, ProFormText } from "@ant-design/pro-components";
import { useQuery } from "@tanstack/react-query";
import { Button, Col, Divider, Row, Space, Switch, theme, Select } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import { getCodeDetails } from "@/domains/cmm/api";
import type { User, UserFormValues } from "@/domains/usr/types";
import CodeSelect from "../CodeSelect";
import OrgTreeSelect from "../OrgTreeSelect";
import PasswordChangeModal from "./PasswordChangeModal";
import RoleAssignmentModal from "./RoleAssignmentModal";
import UserIdentitySection from "./UserIdentitySection";

interface UserFormDrawerProps {
    /** 드로어 오픈 상태 */
    open: boolean;
    /** 오픈 상태 변경 콜백 */
    onOpenChange: (open: boolean) => void;
    /** 현재 편집 중인 사용자 (신규 등록 시 null) */
    editingUser: User | null;
    /** 신규 등록 시 기본 선택될 부서 ID */
    initialOrgId?: number;
    /** 저장 실행 콜백 (Zero Any Policy 적용) */
    onFinish: (values: UserFormValues) => Promise<boolean>;
}

/**
 * 사용자 상세 조회 및 등록/수정 통합 드로어 컴포넌트
 */
const UserFormDrawer: React.FC<UserFormDrawerProps> = ({
    open,
    onOpenChange,
    editingUser,
    initialOrgId,
    onFinish,
}) => {
    const { token } = theme.useToken();
    const [form] = ProForm.useForm<UserFormValues>();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

    // 모달 상태 관리
    const [pwdModalOpen, setPwdModalOpen] = useState(false);
    const [roleModalOpen, setRoleModalOpen] = useState(false);

    // 폼 값 실시간 감시
    const watchedName = ProForm.useWatch("name", form);
    const watchedPos = ProForm.useWatch("pos", form);
    const watchedRoleIds = ProForm.useWatch("role_ids", form);
    const watchedActive = ProForm.useWatch("is_active", form);
    const watchedStatus = ProForm.useWatch("account_status", form);

    // 기초 코드 조회
    const { data: posCodes } = useQuery({
        queryKey: ["codeDetails", "POS_TYPE"],
        queryFn: () => getCodeDetails("POS_TYPE"),
        enabled: open,
    });
    const { data: dutyCodes } = useQuery({
        queryKey: ["codeDetails", "DUTY_TYPE"],
        queryFn: () => getCodeDetails("DUTY_TYPE"),
        enabled: open,
    });

    const posLabel = useMemo(
        () => posCodes?.find((c) => c.detail_code === watchedPos)?.detail_name || "",
        [watchedPos, posCodes]
    );

    // 드로어 오픈 시 초기화 로직
    useEffect(() => {
        if (open) {
            if (editingUser) {
                setMode("view");
                form.setFieldsValue({
                    ...editingUser,
                    org_id: editingUser.org_id ? Number(editingUser.org_id) : undefined,
                    pos: editingUser.metadata?.pos,
                    duty: editingUser.metadata?.duty,
                    role_ids: editingUser.roles?.map((r) => r.id) || [],
                });
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({
                    is_active: true,
                    account_status: "ACTIVE",
                    org_id: initialOrgId ? Number(initialOrgId) : undefined,
                    role_ids: [],
                });
            }
        }
    }, [open, editingUser, initialOrgId, form]);

    const isReadOnly = mode === "view";

    /**
     * 읽기 모드일 때도 편집 모드와 동일한 높이를 유지하고 
     * 텍스트 가독성을 확보하기 위한 공통 필드 스타일
     */
    const fieldStyle = useMemo(() => ({
        style: {
            height: "32px", // AntD 기본 높이 고정
            color: isReadOnly ? token.colorText : undefined, // 읽기 모드일 때 글자색 명확하게
            fontWeight: isReadOnly ? 500 : undefined,
        }
    }), [isReadOnly, token]);

    return (
        <>
            <DrawerForm<UserFormValues>
                title={
                    mode === "view"
                        ? "사용자 상세 정보"
                        : mode === "edit"
                        ? "사용자 정보 수정"
                        : "신규 사용자 등록"
                }
                open={open}
                onOpenChange={onOpenChange}
                form={form}
                key={editingUser ? `u-drw-${editingUser.id}` : "u-new-drw"}
                onFinish={onFinish}
                submitter={{
                    render: (props) =>
                        mode === "view"
                            ? [
                                    <Button key="close" onClick={() => onOpenChange(false)}>
                                        닫기
                                    </Button>,
                                    <Button
                                        key="edit"
                                        type="primary"
                                        icon={<EditOutlined />}
                                        onClick={() => setMode("edit")}
                                    >
                                        수정하기
                                    </Button>,
                              ]
                            : [
                                    <Button
                                        key="cancel"
                                        onClick={() => (editingUser ? setMode("view") : onOpenChange(false))}
                                        icon={<CloseOutlined />}
                                    >
                                        {editingUser ? "수정 취소" : "취소"}
                                    </Button>,
                                    <Button
                                        key="submit"
                                        type="primary"
                                        icon={<SaveOutlined />}
                                        onClick={() => props.form?.submit()}
                                    >
                                        {editingUser ? "수정 완료" : "등록 완료"}
                                    </Button>,
                              ],
                }}
                drawerProps={{
                    destroyOnHidden: true,
                    maskClosable: isReadOnly,
                    width: 600,
                    styles: { body: { padding: "20px 24px" } },
                }}
                layout="vertical"
            >
                <style>{`
                    /* 읽기 모드일 때 Input 박스의 텍스트 가독성 강화 */
                    .ant-input-disabled, .ant-select-disabled .ant-select-selection-item {
                        color: ${token.colorText} !important;
                        -webkit-text-fill-color: ${token.colorText} !important;
                        font-weight: 500;
                    }
                    /* 읽기 모드일 때 배경색 미세 조정 */
                    .ant-input-disabled, .ant-select-disabled .ant-select-selector {
                        background-color: ${isReadOnly ? token.colorFillQuaternary : undefined} !important;
                    }
                `}</style>

                {/* 1. 프로필 Identity 섹션 (분리됨) */}
                <UserIdentitySection
                    user={editingUser}
                    watchedName={watchedName}
                    posLabel={posLabel}
                    currentRoles={editingUser?.roles || []}
                    isReadOnly={isReadOnly}
                    onImageUpload={(id) => form.setFieldValue("profile_image_id", id)}
                    onOpenRoleModal={() => setRoleModalOpen(true)}
                    onOpenPasswordModal={() => setPwdModalOpen(true)}
                />

                <ProFormText name="profile_image_id" hidden />
                <ProForm.Item name="role_ids" hidden>
                    <Select mode="multiple" />
                </ProForm.Item>

                {/* 2. 기본 계정 정보 */}
                <Divider
                    orientation="left"
                    style={{ margin: "0 0 16px 0", fontSize: "13px", color: token.colorTextSecondary, fontWeight: 600 }}
                >
                    기본 계정 정보
                </Divider>
                <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                    <Col span={12}>
                        <ProFormText
                            name="login_id"
                            label="로그인 ID"
                            disabled={mode !== "add"}
                            fieldProps={fieldStyle}
                            rules={mode === "add" ? [{ required: true, min: 4, message: "4자 이상 입력해주세요" }] : []}
                            placeholder={mode === "add" ? "사용할 ID 입력" : ""}
                        />
                    </Col>
                    <Col span={12}>
                        <ProFormText name="name" label="성명" rules={[{ required: true }]} disabled={isReadOnly} fieldProps={fieldStyle} />
                    </Col>
                </Row>
                <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                    <Col span={12}>
                        <ProFormText
                            name="emp_code"
                            label="사번"
                            rules={[
                                { required: true, message: "사번을 입력해주세요" },
                                { pattern: /^[A-Z0-9_-]+$/, message: "영문 대문자, 숫자, _, -만 입력 가능합니다" },
                            ]}
                            fieldProps={{
                                ...fieldStyle,
                                placeholder: "예: GUMC-001",
                                onChange: (e) => {
                                    const val = e.target.value.toUpperCase().replace(/[^A-Z0-9_-]/g, "");
                                    form.setFieldValue("emp_code", val);
                                },
                            }}
                            disabled={isReadOnly}
                        />
                    </Col>
                    {mode === "add" && (
                        <Col span={12}>
                            <ProFormText.Password
                                name="password"
                                label="초기 비밀번호"
                                rules={[{ required: true, min: 8 }]}
                                fieldProps={{ ...fieldStyle, autoComplete: "new-password" }}
                            />
                        </Col>
                    )}
                </Row>

                {/* 3. 인사 / 부서 정보 */}
                <Divider
                    orientation="left"
                    style={{ margin: "12px 0 16px 0", fontSize: "13px", color: token.colorTextSecondary, fontWeight: 600 }}
                >
                    인사 / 부서 정보
                </Divider>
                <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                    <Col span={24}>
                        <ProForm.Item name="org_id" label="소속 부서" rules={[{ required: true }]}>
                            <OrgTreeSelect disabled={isReadOnly} style={{ height: "32px" }} />
                        </ProForm.Item>
                    </Col>
                </Row>
                <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                    <Col span={12}>
                        <ProForm.Item name="pos" label="직위/직급">
                            <CodeSelect groupCode="POS_TYPE" disabled={isReadOnly} style={{ height: "32px" }} />
                        </ProForm.Item>
                    </Col>
                    <Col span={12}>
                        <ProForm.Item name="duty" label="직책">
                            <CodeSelect groupCode="DUTY_TYPE" disabled={isReadOnly} style={{ height: "32px" }} />
                        </ProForm.Item>
                    </Col>
                </Row>
                <Row gutter={LAYOUT_CONSTANTS.FORM_GUTTER}>
                    <Col span={12}>
                        <ProFormText name="email" label="이메일" rules={[{ type: "email" }]} disabled={isReadOnly} fieldProps={fieldStyle} />
                    </Col>
                    <Col span={12}>
                        <ProFormText name="phone" label="연락처" disabled={isReadOnly} fieldProps={fieldStyle} />
                    </Col>
                </Row>

                {/* 4. 상태 표시 바 */}
                <Row gutter={12} style={{ marginTop: 8 }}>
                    <Col span={12}>
                        <div
                            style={{
                                boxSizing: "border-box",
                                height: "46px", // 명시적인 고정 높이
                                padding: "0 16px",
                                borderRadius: token.borderRadiusLG,
                                border: `1px solid ${watchedActive ? token.colorSuccessBorder : token.colorBorderSecondary}`,
                                background: watchedActive ? token.colorSuccessBg : token.colorFillQuaternary,
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                            }}
                        >
                            <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                                <span style={{ fontSize: "13px", color: token.colorTextDescription, lineHeight: "1" }}>재직 상태:</span>
                                <span
                                    style={{
                                        fontSize: "13px",
                                        fontWeight: 700,
                                        color: watchedActive ? token.colorSuccess : token.colorTextDisabled,
                                        lineHeight: "1",
                                    }}
                                >
                                    {watchedActive ? "재직" : "퇴사"}
                                </span>
                            </div>
                            <ProForm.Item name="is_active" noStyle valuePropName="checked">
                                <Switch size="small" disabled={isReadOnly} />
                            </ProForm.Item>
                        </div>
                    </Col>
                    <Col span={12}>
                        <div
                            style={{
                                boxSizing: "border-box",
                                height: "46px", // 동일한 고정 높이
                                padding: "0 16px",
                                borderRadius: token.borderRadiusLG,
                                border: `1px solid ${watchedStatus === "ACTIVE" ? token.colorInfoBorder : token.colorErrorBorder}`,
                                background: watchedStatus === "ACTIVE" ? token.colorInfoBg : token.colorErrorBg,
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                            }}
                        >
                            <div style={{ display: "flex", alignItems: "center", gap: "4px" }}>
                                <span style={{ fontSize: "13px", color: token.colorTextDescription, lineHeight: "1" }}>계정 상태:</span>
                                <span
                                    style={{
                                        fontSize: "13px",
                                        fontWeight: 700,
                                        color: watchedStatus === "ACTIVE" ? token.colorInfo : token.colorError,
                                        lineHeight: "1",
                                    }}
                                >
                                    {watchedStatus === "ACTIVE" ? "정상" : "차단"}
                                </span>
                            </div>
                            <ProForm.Item
                                name="account_status"
                                noStyle
                                valuePropName="checked"
                                getValueProps={(v) => ({ checked: v === "ACTIVE" })}
                                getValueFromEvent={(c) => (c ? "ACTIVE" : "BLOCKED")}
                            >
                                <Switch size="small" disabled={isReadOnly} />
                            </ProForm.Item>
                        </div>
                    </Col>
                </Row>
            </DrawerForm>

            {/* 별도 컴포넌트로 분리된 모달들 */}
            {editingUser && (
                <>
                    <RoleAssignmentModal
                        userId={editingUser.id}
                        userName={watchedName || editingUser.name}
                        currentRoleIds={watchedRoleIds || []}
                        open={roleModalOpen}
                        onOpenChange={setRoleModalOpen}
                        onSuccess={(newIds) => form.setFieldValue("role_ids", newIds)}
                    />
                    <PasswordChangeModal
                        userId={editingUser.id}
                        userName={watchedName || editingUser.name}
                        open={pwdModalOpen}
                        onOpenChange={setPwdModalOpen}
                    />
                </>
            )}
        </>
    );
};

export default UserFormDrawer;
