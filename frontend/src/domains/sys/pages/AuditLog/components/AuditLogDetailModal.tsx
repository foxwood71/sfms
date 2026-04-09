import { Button, Descriptions, Divider, Modal, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import type { AuditLog } from "@/domains/sys/types";

interface AuditLogDetailModalProps {
    open: boolean;
    onClose: () => void;
    log: AuditLog | null;
}

const AuditLogDetailModal: React.FC<AuditLogDetailModalProps> = ({ open, onClose, log }) => {
    const { t } = useTranslation();
    const { token } = theme.useToken();

    return (
        <Modal
            title={t("sys.audit.snapshot_title")}
            open={open}
            onCancel={onClose}
            footer={[
                <Button key="close" onClick={onClose}>
                    {t("common.confirm")}
                </Button>,
            ]}
            width={800}
        >
            {log && (
                <div style={{ maxHeight: "600px", overflowY: "auto" }}>
                    <Descriptions title={t("common.detail_info")} bordered size="small" column={2}>
                        <Descriptions.Item label={t("sys.audit.action_type")}>
                            {log.action_type}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.domain")}>
                            {log.target_domain}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.table", "대상 테이블")}>
                            {log.target_table}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.target_id", "대상 ID")}>
                            {log.target_id}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.actor")}>
                            {log.actor_user_id || "-"}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.client_ip")}>
                            {log.client_ip}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.created_at")} span={2}>
                            {log.created_at}
                        </Descriptions.Item>
                        <Descriptions.Item label={t("sys.audit.description")} span={2}>
                            {log.description}
                        </Descriptions.Item>
                    </Descriptions>
                    <Divider orientation="left" style={{ fontSize: "14px" }}>
                        {t("sys.audit.snapshot_data", "데이터 스냅샷")}
                    </Divider>
                    <pre
                        style={{
                            background: token.colorFillAlter,
                            padding: "16px",
                            borderRadius: "8px",
                            fontSize: "12px",
                            border: `1px solid ${token.colorBorderSecondary}`,
                        }}
                    >
                        {JSON.stringify(log.snapshot, null, 2)}
                    </pre>
                </div>
            )}
        </Modal>
    );
};

export default AuditLogDetailModal;
