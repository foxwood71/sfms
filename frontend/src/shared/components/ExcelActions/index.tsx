import { DownloadOutlined, ExclamationCircleOutlined, FileExcelOutlined, UploadOutlined } from "@ant-design/icons";
import { App, Button, Space, Tooltip, Upload } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import {
    type ExcelColumnMapping,
    type ExcelSheetData,
    exportMultiSheetExcel,
    exportToExcel,
    importFromExcel,
} from "../../utils/excel";

interface ExcelActionsProps<T extends Record<string, unknown>> {
    /** 내보낼 데이터 (단일 시트용) */
    exportData?: T[];
    /** 여러 시트 데이터 (멀티 시트용) */
    sheets?: ExcelSheetData<T>[];
    /** 엑셀 컬럼 매핑 (단일 시트용) */
    columns: ExcelColumnMapping[];
    /** 저장될 파일명 */
    fileName: string;
    /** 데이터 업로드(임포트) 콜백 */
    onImport?: (data: T[]) => void;
    /** 업로드 기능 활성화 여부 */
    uploadEnabled?: boolean;
    /** 처리 중 로딩 상태 */
    loading?: boolean;
}

/**
 * 전역 공통 엑셀 액션 버튼 모듈
 * (Bento Standard UI 준수 + 안전 업로드 로직 + 로딩 피드백)
 */
const ExcelActions = <T extends Record<string, unknown>>({
    exportData = [],
    sheets,
    columns,
    fileName,
    onImport,
    uploadEnabled = true,
    loading = false,
}: ExcelActionsProps<T>): React.ReactElement => {
    const { t } = useTranslation();
    const { message, modal } = App.useApp();

    // 엑셀 다운로드 실행
    const handleDownload = () => {
        if (sheets && sheets.length > 0) {
            exportMultiSheetExcel<T>(sheets, fileName);
            return;
        }

        if (exportData.length === 0) {
            message.warning(t("common.no_data_to_export"));
            return;
        }
        exportToExcel<T>(exportData, columns, fileName);
    };

    // 양식 다운로드 (데이터 없이 헤더만)
    const handleTemplateDownload = () => {
        exportToExcel<T>([], columns, `${fileName}_양식`);
    };

    // 엑셀 업로드 전 파싱 및 최종 확인
    const handleBeforeUpload = async (file: File) => {
        if (loading) return false;

        try {
            // [FIX] importFromExcel에 제네릭 T를 전달하여 onImport 타입과 일치시킴
            const data = await importFromExcel<T>(file);
            if (data.length === 0) {
                message.warning(t("common.no_data_to_import"));
                return false;
            }

            // 안전을 위한 최종 확인 모달
            modal.confirm({
                title: t("common.excel_import_confirm_title"),
                icon: <ExclamationCircleOutlined style={{ color: "#faad14" }} />,
                content: (
                    <div>
                        <p>{t("common.excel_import_summary", { count: data.length })}</p>
                        <p style={{ color: "#ff4d4f", fontWeight: "bold" }}>{t("common.excel_import_confirm_msg")}</p>
                    </div>
                ),
                okText: t("common.confirm"),
                cancelText: t("common.cancel"),
                onOk: () => {
                    onImport?.(data);
                },
            });
        } catch (error) {
            console.error("Excel Import Error:", error);
            message.error(t("common.import_failure"));
        }
        return false; // 실제 HTTP 요청은 중단하고 우리가 로직 제어
    };

    return (
        <Space.Compact>
            {/* 1. 양식 다운로드 */}
            <Tooltip title={t("common.template_download")}>
                <Button type="text" icon={<FileExcelOutlined />} onClick={handleTemplateDownload} disabled={loading} />
            </Tooltip>

            {/* 2. 엑셀 업로드 */}
            {uploadEnabled && onImport && (
                <Upload
                    accept=".xlsx, .xls"
                    showUploadList={false}
                    beforeUpload={handleBeforeUpload}
                    disabled={loading}
                >
                    <Tooltip title={t("common.excel_upload")}>
                        <Button type="text" icon={<UploadOutlined />} loading={loading} />
                    </Tooltip>
                </Upload>
            )}

            {/* 3. 데이터 다운로드 */}
            <Tooltip title={t("common.excel_download")}>
                <Button
                    type="text"
                    icon={<DownloadOutlined />}
                    onClick={handleDownload}
                    disabled={loading || (exportData.length === 0 && (!sheets || sheets.length === 0))}
                />
            </Tooltip>
        </Space.Compact>
    );
};

export default ExcelActions;
