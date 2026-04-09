import { ProForm } from "@ant-design/pro-components";
import { Col, Row, Switch, theme } from "antd";
import type React from "react";

interface AccountStatusSectionProps {
    isReadOnly: boolean;
    watchedActive: boolean;
    watchedStatus: string;
}

const AccountStatusSection: React.FC<AccountStatusSectionProps> = ({
    isReadOnly,
    watchedActive,
    watchedStatus,
}) => {
    const { token } = theme.useToken();

    return (
        <Row gutter={12} style={{ marginTop: 8 }}>
            <Col span={12}>
                <div
                    style={{
                        boxSizing: "border-box",
                        height: "46px",
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
                        <span
                            style={{
                                fontSize: "13px",
                                color: token.colorTextDescription,
                                lineHeight: "1",
                            }}
                        >
                            재직 상태:
                        </span>
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
                        height: "46px",
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
                        <span
                            style={{
                                fontSize: "13px",
                                color: token.colorTextDescription,
                                lineHeight: "1",
                            }}
                        >
                            계정 상태:
                        </span>
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
                        getValueProps={(v: string) => ({ checked: v === "ACTIVE" })}
                        getValueFromEvent={(c: boolean) => (c ? "ACTIVE" : "BLOCKED")}
                    >
                        <Switch size="small" disabled={isReadOnly} />
                    </ProForm.Item>
                </div>
            </Col>
        </Row>
    );
};

export default AccountStatusSection;
