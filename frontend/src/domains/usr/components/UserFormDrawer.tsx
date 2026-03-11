import { ClockCircleOutlined, EditOutlined, LockOutlined, UploadOutlined, UserOutlined, SafetyOutlined, ExclamationCircleOutlined, SaveOutlined, CloseOutlined } from "@ant-design/icons";
import { DrawerForm, ModalForm, ProForm, ProFormSelect, ProFormSwitch, ProFormText } from "@ant-design/pro-components";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Avatar, Button, Col, Divider, message, Row, Space, theme, Upload, Tag, Typography, Switch, Select } from "antd";
import dayjs from "dayjs";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { http } from "@/shared/api/http";
import { useAuthStore } from "@/shared/stores/useAuthStore";
import { changePasswordApi } from "../api";
import { getRolesApi, assignUserRolesApi } from "../../iam/api/auth";
import { getCodeDetails } from "../../cmm/api";
import type { User } from "../types";
import CodeSelect from "./CodeSelect";
import OrgTreeSelect from "./OrgTreeSelect";

const { Text } = Typography;

interface UserFormDrawerProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    editingUser: User | null;
    initialOrgId?: number;
    onFinish: (values: any) => Promise<boolean>;
}

const UserFormDrawer: React.FC<UserFormDrawerProps> = ({ open, onOpenChange, editingUser, initialOrgId, onFinish }) => {
    const { token } = theme.useToken();
    const [form] = ProForm.useForm();
    const queryClient = useQueryClient();
    const accessToken = useAuthStore((state) => state.accessToken);

    const [mode, setMode] = useState<"view" | "edit" | "add">("view");
    
    // 실시간 값 감시
    const watchedName = ProForm.useWatch("name", form);
    const watchedPos = ProForm.useWatch("pos", form);
    const watchedRoleIds = ProForm.useWatch("role_ids", form);
    const watchedImageId = ProForm.useWatch("profile_image_id", form);
    
    const watchedActive = ProForm.useWatch("is_active", form) ?? editingUser?.is_active;
    const watchedStatus = ProForm.useWatch("account_status", form) ?? editingUser?.account_status;

    const [pwdModalVisible, setPwdModalVisible] = useState(false);
    const [roleModalVisible, setRoleModalVisible] = useState(false);
    const [tempRoleIds, setTempRoleIds] = useState<number[]>([]);

    const { data: posCodes } = useQuery({ queryKey: ["codeDetails", "POS_TYPE"], queryFn: () => getCodeDetails("POS_TYPE"), enabled: open });
    const { data: dutyCodes } = useQuery({ queryKey: ["codeDetails", "DUTY_TYPE"], queryFn: () => getCodeDetails("DUTY_TYPE"), enabled: open });
    const { data: rolesData } = useQuery({ queryKey: ["iam-roles"], queryFn: getRolesApi, enabled: open });

    const posLabel = useMemo(() => posCodes?.find(c => c.detail_code === watchedPos)?.detail_name || "", [watchedPos, posCodes]);

    /**
     * 이미지 URL 실시간 계산 (어떤 모드에서도 끊김 없이 표시)
     */
    const imageUrl = useMemo(() => {
        const id = watchedImageId || editingUser?.profile_image_id;
        if (!id || !accessToken) return undefined;
        return `/api/v1/cmm/attachments/${id}/download?token=${accessToken}`;
    }, [watchedImageId, editingUser?.profile_image_id, accessToken]);

    const getRoleColor = (code: string) => {
        const upperCode = (code || "").toUpperCase();
        if (upperCode.includes("ADMIN")) return "magenta";
        if (upperCode.includes("MANAGER")) return "blue";
        if (upperCode.includes("USER")) return "green";
        if (upperCode.includes("SYS")) return "purple";
        if (upperCode.includes("DEV")) return "cyan";
        const presetColors = ["orange", "gold", "lime", "geekblue", "volcano"];
        const index = (code || "").split("").reduce((acc, char) => acc + char.charCodeAt(0), 0) % presetColors.length;
        return presetColors[index];
    };

    useEffect(() => {
        if (open) {
            if (editingUser) {
                setMode("view");
                const roles = editingUser.roles || []; 
                form.setFieldsValue({
                    ...editingUser,
                    org_id: editingUser.org_id !== undefined ? Number(editingUser.org_id) : undefined,
                    pos: editingUser.metadata?.pos,
                    duty: editingUser.metadata?.duty,
                    role_ids: roles.map(r => r.id),
                    profile_image_id: editingUser.profile_image_id,
                });
            } else {
                setMode("add");
                form.resetFields();
                form.setFieldsValue({ is_active: true, account_status: "ACTIVE", org_id: initialOrgId !== undefined ? Number(initialOrgId) : undefined, role_ids: [] });
            }
        }
    }, [open, editingUser, initialOrgId, form]);

    const isReadOnly = mode === "view";

    const currentRoles = useMemo(() => {
        if (watchedRoleIds && rolesData) return rolesData.filter((r: any) => watchedRoleIds.includes(r.id));
        return editingUser?.roles || [];
    }, [watchedRoleIds, rolesData, editingUser]);

    const handleAddRole = (roleId: number) => {
        if (!tempRoleIds.includes(roleId)) setTempRoleIds([...tempRoleIds, roleId]);
    };

    const handleRemoveRole = (roleId: number) => {
        setTempRoleIds(tempRoleIds.filter(id => id !== roleId));
    };

    return (
        <DrawerForm
            title={mode === "view" ? "사용자 상세 정보" : mode === "edit" ? "사용자 정보 수정" : "신규 사용자 등록"}
            open={open}
            onOpenChange={onOpenChange}
            form={form}
            key={editingUser ? `u-drawer-${editingUser.id}` : "u-new-drawer"}
            onFinish={onFinish}
            submitter={{
                render: (props) => mode === "view" ? [
                    <Button key="close" onClick={() => onOpenChange(false)}>닫기</Button>,
                    <Button key="edit" type="primary" icon={<EditOutlined />} onClick={() => setMode("edit")}>수정하기</Button>
                ] : [
                    <Button key="cancel" onClick={() => editingUser ? setMode("view") : onOpenChange(false)} icon={<CloseOutlined />}>{editingUser ? "수정 취소" : "취소"}</Button>,
                    <Button key="submit" type="primary" icon={<SaveOutlined />} onClick={() => props.form?.submit()}>{editingUser ? "수정 완료" : "등록 완료"}</Button>
                ]
            }}
            drawerProps={{ destroyOnClose: true, maskClosable: isReadOnly, width: 600, styles: { body: { padding: "20px 24px" } } }}
            layout="vertical"
        >
            <ProFormText name="profile_image_id" hidden />
            <ProForm.Item name="role_ids" hidden><Select mode="multiple" /></ProForm.Item>

            {/* 1. 프로필 Identity 영역 */}
            <div style={{ display: "flex", alignItems: "center", marginBottom: 24, padding: "24px 32px", background: `linear-gradient(135deg, ${token.colorFillAlter} 0%, ${token.colorBgContainer} 100%)`, borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}` }}>
                <Avatar 
                    key={watchedImageId || "no-img"}
                    size={80} 
                    icon={<UserOutlined />} 
                    src={imageUrl} 
                    style={{ border: `3px solid ${token.colorWhite}`, boxShadow: token.boxShadowTertiary, flexShrink: 0, marginRight: 28 }} 
                />
                <div style={{ flex: 1 }}>
                    <div style={{ display: "flex", alignItems: "baseline", marginBottom: 12 }}>
                        <span style={{ fontWeight: 800, fontSize: "24px", color: token.colorTextHeading, marginRight: 8 }}>{watchedName || (editingUser ? "" : "신규 사용자")}</span>
                        {posLabel && <Text type="secondary" style={{ fontSize: "18px", fontWeight: 500 }}>{posLabel}</Text>}
                    </div>
                    {!isReadOnly && (
                        <Space size={8} style={{ marginBottom: 12 }}>
                            <Upload customRequest={async (o) => {
                                const formData = new FormData(); formData.append("file", o.file);
                                try {
                                    const res = await http.post(`/cmm/upload?domain_code=USR&resource_type=PROFILE&ref_id=${editingUser?.id || 0}`, formData, { headers: { "Content-Type": "multipart/form-data" } });
                                    const id = res.data?.data?.id;
                                    form.setFieldValue("profile_image_id", id);
                                    message.success("사진 업로드 성공"); o.onSuccess?.(res.data);
                                } catch (err) { message.error("실패"); o.onError?.(err as any); }
                            }} showUploadList={false}><Button type="primary" ghost size="small" icon={<UploadOutlined />} style={{ fontSize: "11px" }}>사진 변경</Button></Upload>
                            <Button size="small" icon={<SafetyOutlined />} onClick={() => { 
                                const currentIds = form.getFieldValue("role_ids") || (editingUser?.roles?.map(r => r.id)) || [];
                                setTempRoleIds(currentIds); 
                                setRoleModalVisible(true); 
                            }} style={{ fontSize: "11px" }}>역할 설정</Button>
                            <Button size="small" icon={<LockOutlined />} onClick={() => setPwdModalVisible(true)} style={{ fontSize: "11px" }}>비밀번호 재설정</Button>
                        </Space>
                    )}
                    <div style={{ display: "flex", flexWrap: "wrap", gap: "4px" }}>
                        {currentRoles.length > 0 ? currentRoles.map((r: any) => (
                            <Tag key={r.id} color={getRoleColor(r.code || r.name)} size="small" style={{ borderRadius: "10px", fontSize: "10px", margin: 0, border: "none" }}>{r.name}</Tag>
                        )) : editingUser && <span style={{ fontSize: "11px", color: token.colorTextDisabled }}>할당된 역할 없음</span>}
                    </div>
                </div>
            </div>

            {/* 2. 기본 계정 정보 */}
            <Divider orientation="left" style={{ margin: "0 0 16px 0", fontSize: "13px", color: token.colorTextSecondary, fontWeight: 600 }}>기본 계정 정보</Divider>
            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText 
                        name="login_id" 
                        label="로그인 ID" 
                        disabled={mode !== "add"} 
                        rules={mode === "add" ? [{ required: true, min: 4, message: "4자 이상 입력해주세요" }] : []}
                        placeholder={mode === "add" ? "사용할 ID 입력" : ""}
                    />
                </Col>
                <Col span={12}><ProFormText name="name" label="성명" rules={[{ required: true }]} disabled={isReadOnly} /></Col>
            </Row>
            <Row gutter={16}>
                <Col span={12}>
                    <ProFormText 
                        name="emp_code" 
                        label="사번" 
                        rules={[
                            { required: true, message: "사번을 입력해주세요" },
                            { pattern: /^[A-Z0-9_-]+$/, message: "영문 대문자, 숫자, _, -만 입력 가능합니다" }
                        ]} 
                        fieldProps={{
                            placeholder: "예: GUMC-001_A",
                            onChange: (e) => {
                                const val = e.target.value.toUpperCase().replace(/[^A-Z0-9_-]/g, "");
                                form.setFieldValue("emp_code", val);
                            }
                        }}
                        disabled={isReadOnly} 
                    />
                </Col>
                {mode === "add" && <Col span={12}><ProFormText.Password name="password" label="초기 비밀번호" rules={[{ required: true, min: 8 }]} /></Col>}
            </Row>

            {/* 3. 인사 / 부서 정보 */}
            <Divider orientation="left" style={{ margin: "12px 0 16px 0", fontSize: "13px", color: token.colorTextSecondary, fontWeight: 600 }}>인사 / 부서 정보</Divider>
            <Row gutter={16}>
                <Col span={24}><ProForm.Item name="org_id" label="소속 부서" rules={[{ required: true }]}><OrgTreeSelect disabled={isReadOnly} /></ProForm.Item></Col>
            </Row>
            <Row gutter={16}>
                <Col span={12}><ProForm.Item name="pos" label="직위/직급"><CodeSelect groupCode="POS_TYPE" disabled={isReadOnly} /></ProForm.Item></Col>
                <Col span={12}><ProForm.Item name="duty" label="직책"><CodeSelect groupCode="DUTY_TYPE" disabled={isReadOnly} /></ProForm.Item></Col>
            </Row>
            <Row gutter={16}>
                <Col span={12}><ProFormText name="email" label="이메일" rules={[{ type: "email" }]} disabled={isReadOnly} /></Col>
                <Col span={12}><ProFormText name="phone" label="연락처" disabled={isReadOnly} /></Col>
            </Row>

            {/* 4. 상태 박스 */}
            <Row gutter={12} style={{ marginTop: 8 }}>
                <Col span={12}>
                    <div style={{ 
                        height: "48px", padding: "0 16px", borderRadius: token.borderRadiusLG, border: `1px solid ${watchedActive ? token.colorSuccessBorder : token.colorBorderSecondary}`,
                        background: watchedActive ? token.colorSuccessBg : token.colorFillQuaternary,
                        display: "flex", justifyContent: "space-between", alignItems: "center"
                    }}>
                        <Space size={4}>
                            <span style={{ fontSize: "13px", color: token.colorTextDescription }}>재직 상태:</span>
                            <span style={{ fontSize: "13px", fontWeight: 700, color: watchedActive ? token.colorSuccess : token.colorTextDisabled }}>{watchedActive ? "재직" : "퇴사"}</span>
                        </Space>
                        <ProFormSwitch name="is_active" noStyle fieldProps={{ size: "small", disabled: isReadOnly }} />
                    </div>
                </Col>
                <Col span={12}>
                    <div style={{ 
                        height: "48px", padding: "0 16px", borderRadius: token.borderRadiusLG, border: `1px solid ${watchedStatus === "ACTIVE" ? token.colorInfoBorder : token.colorErrorBorder}`,
                        background: watchedStatus === "ACTIVE" ? token.colorInfoBg : token.colorErrorBg,
                        display: "flex", justifyContent: "space-between", alignItems: "center"
                    }}>
                        <Space size={4}>
                            <span style={{ fontSize: "13px", color: token.colorTextDescription }}>계정 상태:</span>
                            <span style={{ fontSize: "13px", fontWeight: 700, color: watchedStatus === "ACTIVE" ? token.colorInfo : token.colorError }}>{watchedStatus === "ACTIVE" ? "정상" : "차단"}</span>
                        </Space>
                        <ProForm.Item name="account_status" noStyle valuePropName="checked" getValueProps={(v) => ({ checked: v === "ACTIVE" })} getValueFromEvent={(c) => c ? "ACTIVE" : "BLOCKED"}>
                            <Switch size="small" disabled={isReadOnly} />
                        </ProForm.Item>
                    </div>
                </Col>
            </Row>

            {editingUser && (
                <div style={{ marginTop: 24, padding: "12px 0", borderTop: `1px solid ${token.colorBorderSecondary}`, fontSize: "11px", color: token.colorTextDescription }}>
                    <Row gutter={16}>
                        <Col span={12}><Space><ClockCircleOutlined /><span>생성: {dayjs(editingUser.created_at).format("YYYY-MM-DD HH:mm")}</span></Space></Col>
                        <Col span={12}><Space><EditOutlined /><span>수정: {dayjs(editingUser.updated_at).format("YYYY-MM-DD HH:mm")}</span></Space></Col>
                    </Row>
                </div>
            )}

            {/* 역할 설정 팝업 */}
            <ModalForm title={`${watchedName} 역할 관리`} open={roleModalVisible} onOpenChange={setRoleModalVisible} width={420} modalProps={{ destroyOnClose: true, centered: true }}
                onFinish={async () => { if (!editingUser) return false; try { await assignUserRolesApi(editingUser.id, tempRoleIds); message.success("업데이트 완료"); form.setFieldValue("role_ids", tempRoleIds); queryClient.invalidateQueries({ queryKey: ["users"] }); return true; } catch (err) { message.error("실패"); return false; } }}>
                <div style={{ marginBottom: 20 }}>
                    <Text type="secondary" style={{ fontSize: "12px", display: "block", marginBottom: 8 }}>역할 선택하여 추가</Text>
                    <Select placeholder="부여할 역할을 선택하세요" style={{ width: "100%" }} onChange={(val) => handleAddRole(val)} value={null} options={rolesData?.filter(r => !tempRoleIds.includes(r.id)).map((r: any) => ({ label: r.name, value: r.id }))} />
                </div>
                <div style={{ background: token.colorFillQuaternary, padding: "16px", borderRadius: token.borderRadiusLG, border: `1px solid ${token.colorBorderSecondary}`, minHeight: "100px" }}>
                    <Text strong style={{ fontSize: "13px", display: "block", marginBottom: 12 }}>부여된 역할 목록</Text>
                    <div style={{ display: "flex", flexWrap: "wrap", gap: "8px" }}>
                        {tempRoleIds.length > 0 ? tempRoleIds.map(id => { 
                            const role = rolesData?.find(r => r.id === id); 
                            return (<Tag key={id} color={getRoleColor(role?.code || role?.name || "")} closable onClose={() => handleRemoveRole(id)} style={{ padding: "4px 10px", borderRadius: "12px", border: "none" }}>{role?.name}</Tag>); 
                        }) : (<div style={{ width: "100%", textAlign: "center", padding: "12px 0", color: token.colorTextDisabled }}><ExclamationCircleOutlined style={{ marginRight: 4 }} /> 할당된 역할이 없습니다.</div>)}
                    </div>
                </div>
            </ModalForm>

            {/* 비밀번호 재설정 팝업 */}
            <ModalForm title="비밀번호 재설정" open={pwdModalVisible} onOpenChange={setPwdModalVisible} width={360} modalProps={{ destroyOnClose: true, centered: true }} onFinish={async (values) => { if (!editingUser) return false; try { await changePasswordApi(editingUser.id, { new_password: values.new_password }); message.success("변경 완료"); return true; } catch (err) { message.error("실패"); return false; } }}>
                <ProFormText.Password name="new_password" label="새 비밀번호" rules={[{ required: true, min: 8 }]} />
                <ProFormText.Password name="confirm_new_password" label="확인" dependencies={["new_password"]} rules={[{ required: true }, ({ getFieldValue }) => ({ validator(_, value) { if (!value || getFieldValue("new_password") === value) return Promise.resolve(); return Promise.reject(new Error("불일치")); } })]} />
            </ModalForm>
        </DrawerForm>
    );
};

export default UserFormDrawer;
