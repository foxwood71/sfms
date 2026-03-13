import { LockOutlined, SafetyOutlined, UploadOutlined, UserOutlined } from "@ant-design/icons";
import { Avatar, Button, message, Space, Tag, Typography, Upload, theme } from "antd";
import type React from "react";
import { useAuthStore } from "@/shared/stores/useAuthStore";
import { http } from "@/shared/api/http";
import type { User } from "@/domains/usr/types";
import type { Role } from "@/domains/iam/types";

const { Text } = Typography;

interface UserIdentitySectionProps {
    /** 표시할 사용자 정보 */
    user: User | null;
    /** 현재 폼에서 감시 중인 이름 */
    watchedName?: string;
    /** 현재 폼에서 감시 중인 직위 레이블 */
    posLabel?: string;
    /** 현재 할당된 역할 리스트 */
    currentRoles: Role[];
    /** 읽기 전용 여부 (수정 모드 아닐 때) */
    isReadOnly: boolean;
    /** 이미지 업로드 완료 콜백 */
    onImageUpload: (imageId: string) => void;
    /** 역할 설정 버튼 클릭 콜백 */
    onOpenRoleModal: () => void;
    /** 비밀번호 설정 버튼 클릭 콜백 */
    onOpenPasswordModal: () => void;
}

/**
 * 사용자 상세 드로어 상단 프로필 Identity 섹션
 */
const UserIdentitySection: React.FC<UserIdentitySectionProps> = ({
    user,
    watchedName,
    posLabel,
    currentRoles,
    isReadOnly,
    onImageUpload,
    onOpenRoleModal,
    onOpenPasswordModal,
}) => {
    const { token } = theme.useToken();
    const accessToken = useAuthStore((state) => state.accessToken);

    // 이미지 URL 생성 (보안 토큰 포함)
    const imageUrl = user?.profile_image_id 
        ? `/api/v1/cmm/attachments/${user.profile_image_id}/download?token=${accessToken}` 
        : undefined;

    const getRoleColor = (code: string) => {
        const upperCode = (code || "").toUpperCase();
        if (upperCode.includes("ADMIN")) return "magenta";
        if (upperCode.includes("MANAGER")) return "blue";
        if (upperCode.includes("USER")) return "green";
        if (upperCode.includes("SYS")) return "purple";
        if (upperCode.includes("DEV")) return "cyan";
        return "orange";
    };

    return (
        <div style={{ 
            display: "flex", 
            alignItems: "center", 
            marginBottom: 24, 
            padding: "24px 32px", 
            background: `linear-gradient(135deg, ${token.colorFillAlter} 0%, ${token.colorBgContainer} 100%)`, 
            borderRadius: token.borderRadiusLG, 
            border: `1px solid ${token.colorBorderSecondary}` 
        }}>
            <Avatar 
                size={80} 
                icon={<UserOutlined />} 
                src={imageUrl} 
                style={{ 
                    border: `3px solid ${token.colorWhite}`, 
                    boxShadow: token.boxShadowTertiary, 
                    flexShrink: 0, 
                    marginRight: 28 
                }} 
            />
            <div style={{ flex: 1 }}>
                <div style={{ display: "flex", alignItems: "baseline", marginBottom: 12 }}>
                    <span style={{ fontWeight: 800, fontSize: "24px", color: token.colorTextHeading, marginRight: 8 }}>
                        {watchedName || (user ? user.name : "신규 사용자")}
                    </span>
                    {posLabel && (
                        <Text type="secondary" style={{ fontSize: "18px", fontWeight: 500 }}>
                            {posLabel}
                        </Text>
                    )}
                </div>

                {!isReadOnly && (
                    <Space size={8} style={{ marginBottom: 12 }}>
                        <Upload 
                            customRequest={async (options) => {
                                const formData = new FormData();
                                formData.append("file", options.file);
                                try {
                                    const res = await http.post(
                                        `/cmm/upload?domain_code=USR&resource_type=PROFILE&ref_id=${user?.id || 0}`, 
                                        formData, 
                                        { headers: { "Content-Type": "multipart/form-data" } }
                                    );
                                    const newId = res.data?.data?.id;
                                    onImageUpload(newId);
                                    message.success("사진이 업로드되었습니다.");
                                    options.onSuccess?.(res.data);
                                } catch (err) {
                                    message.error("사진 업로드에 실패했습니다.");
                                    options.onError?.(err as any);
                                }
                            }} 
                            showUploadList={false}
                        >
                            <Button type="primary" ghost size="small" icon={<UploadOutlined />} style={{ fontSize: "11px" }}>
                                사진 변경
                            </Button>
                        </Upload>
                        <Button size="small" icon={<SafetyOutlined />} onClick={onOpenRoleModal} style={{ fontSize: "11px" }}>
                            역할 설정
                        </Button>
                        <Button size="small" icon={<LockOutlined />} onClick={onOpenPasswordModal} style={{ fontSize: "11px" }}>
                            비밀번호 재설정
                        </Button>
                    </Space>
                )}

                <div style={{ display: "flex", flexWrap: "wrap", gap: "4px" }}>
                    {currentRoles.length > 0 ? (
                        currentRoles.map((r) => (
                            <Tag 
                                key={r.id} 
                                color={getRoleColor(r.code || r.name)} 
                                size="small" 
                                style={{ borderRadius: "10px", fontSize: "10px", margin: 0, border: "none" }}
                            >
                                {r.name}
                            </Tag>
                        ))
                    ) : (
                        user && <span style={{ fontSize: "11px", color: token.colorTextDisabled }}>할당된 역할 없음</span>
                    )}
                </div>
            </div>
        </div>
    );
};

export default UserIdentitySection;
