import { FolderOpenOutlined, HistoryOutlined } from "@ant-design/icons";
import type { ProColumns } from "@ant-design/pro-components";
import { PageContainer, ProCard, ProTable } from "@ant-design/pro-components";
import { Space, Tag } from "antd";
import type React from "react";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";

/**
 * 시설 및 공간 자료/이력 관리 페이지 (Bento Standard v1.1)
 */
const FacilityHistoryPage: React.FC = () => {
    const { t } = useTranslation();
    const [activeTab, setActiveTab] = useState("docs");

    // 문서 탭 컬럼 정의
    const docColumns: ProColumns[] = [
        {
            title: t("fac.history.file_type"),
            dataIndex: "type",
            width: 120,
            render: (dom) => <Tag color="blue">{dom}</Tag>,
        },
        {
            title: t("fac.history.file_name"),
            dataIndex: "name",
        },
        {
            title: t("fac.history.upload_date"),
            dataIndex: "date",
            width: 150,
        },
        {
            title: t("fac.history.uploader"),
            dataIndex: "user",
            width: 120,
        },
    ];

    // 이력 탭 컬럼 정의
    const historyColumns: ProColumns[] = [
        {
            title: t("sys.audit.created_at"),
            dataIndex: "at",
            width: 180,
        },
        {
            title: t("sys.audit.actor"),
            dataIndex: "actor",
            width: 120,
        },
        {
            title: t("sys.audit.action_type"),
            dataIndex: "action",
            width: 100,
        },
        {
            title: t("sys.audit.description"),
            dataIndex: "desc",
        },
    ];

    return (
        <PageContainer
            header={{ title: t("fac.history.title") }}
            childrenContentStyle={{
                height: LAYOUT_CONSTANTS.CONTENT_HEIGHT,
                overflow: "hidden",
            }}
        >
            <ProCard
                tabs={{
                    activeKey: activeTab,
                    onChange: setActiveTab,
                    items: [
                        {
                            key: "docs",
                            label: (
                                <Space>
                                    <FolderOpenOutlined />
                                    {t("fac.history.doc_tab")}
                                </Space>
                            ),
                            children: (
                                <ProTable
                                    headerTitle={t("fac.history.doc_tab")}
                                    search={false}
                                    toolBarRender={false}
                                    pagination={{ pageSize: 10 }}
                                    columns={docColumns}
                                    dataSource={[]} // 실제 연동 시 API 연결
                                />
                            ),
                        },
                        {
                            key: "history",
                            label: (
                                <Space>
                                    <HistoryOutlined />
                                    {t("fac.history.history_tab")}
                                </Space>
                            ),
                            children: (
                                <ProTable
                                    headerTitle={t("fac.history.history_tab")}
                                    search={false}
                                    toolBarRender={false}
                                    columns={historyColumns}
                                    dataSource={[]} // 감사 로그 필터링 연동 예정
                                />
                            ),
                        },
                    ],
                }}
            />
        </PageContainer>
    );
};

export default FacilityHistoryPage;
