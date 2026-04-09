import { CloseOutlined, EditOutlined, SaveOutlined } from "@ant-design/icons";
import { DrawerForm, ProForm, ProFormText } from "@ant-design/pro-components";
import { useQuery } from "@tanstack/react-query";
import { Button, Select, theme } from "antd";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { getCodeDetails } from "@/domains/cmm/api";
import type { CodeDetail } from "@/domains/cmm/types";
import type { User, UserFormValues } from "@/domains/usr/types";
import AccountInfoSection from "./AccountInfoSection";
import AccountStatusSection from "./AccountStatusSection";
import PasswordChangeModal from "./PasswordChangeModal";
import PersonnelInfoSection from "./PersonnelInfoSection";
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
const UserFormDrawer: React.FC<UserFormDrawerProps> = ({ open, onOpenChange, editingUser, initialOrgId, onFinish }) => {
    const { token } = theme.useToken();
    const [form] = ProForm.useForm<UserFormValues>();
    const [mode, setMode] = useState<"view" | "edit" | "add">("view");

    // 모달 상태 관리
    const [pwdModalOpen, setPwdModalOpen] = useState(false);
    const [roleModalOpen, setRoleModalOpen] = useState(false);

    // 폼 값 실시간 감시
    const watchedName = ProForm.useWatch("name", form);
    const watchedPos = ProForm.useWatch("pos", form);
    const watchedDuty = ProForm.useWatch("duty", form);
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
        () => posCodes?.find((c: CodeDetail) => c.detail_code === watchedPos)?.detail_name || "",
        [watchedPos, posCodes],
    );

    const dutyLabel = useMemo(
        () => dutyCodes?.find((c: CodeDetail) => c.detail_code === watchedDuty)?.detail_name || "",
        [watchedDuty, dutyCodes],
    );

    // 드로어 오픈 시 초기화 로직
    useEffect(() => {
        if (open) {
            if (editingUser) {
                setMode("view");
                form.setFieldsValue({
                    login_id: editingUser.login_id,
                    name: editingUser.name,
                    emp_code: editingUser.emp_code,
                    email: editingUser.email,
                    phone: editingUser.phone,
                    org_id: editingUser.org_id ? Number(editingUser.org_id) : undefined,
                    is_active: editingUser.is_active,
                    account_status: editingUser.account_status,
                    profile_image_id: editingUser.profile_image_id,
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
    const fieldStyle = useMemo(
        () => ({
            style: {
                height: "32px",
                color: isReadOnly ? token.colorText : undefined,
                fontWeight: isReadOnly ? 500 : undefined,
            },
        }),
        [isReadOnly, token],
    );

    return (
        <>
            <DrawerForm<UserFormValues>
                title={mode === "view" ? "사용자 상세 정보" : mode === "edit" ? "사용자 정보 수정" : "신규 사용자 등록"}
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

                {/* 1. 프로필 Identity 섹션 */}
                <UserIdentitySection
                    user={editingUser}
                    watchedName={watchedName}
                    posLabel={posLabel}
                    dutyLabel={dutyLabel}
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

                {/* 2. 기본 계정 정보 섹션 */}
                <AccountInfoSection
                    mode={mode}
                    isReadOnly={isReadOnly}
                    fieldStyle={fieldStyle}
                    onEmpCodeChange={(val) => form.setFieldValue("emp_code", val)}
                />

                {/* 3. 인사 / 부서 정보 섹션 */}
                <PersonnelInfoSection
                    isReadOnly={isReadOnly}
                    fieldStyle={fieldStyle}
                />

                {/* 4. 상태 표시 바 섹션 */}
                <AccountStatusSection
                    isReadOnly={isReadOnly}
                    watchedActive={!!watchedActive}
                    watchedStatus={watchedStatus || "ACTIVE"}
                />
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
