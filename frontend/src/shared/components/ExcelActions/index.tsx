import { DownloadOutlined, UploadOutlined, FileExcelOutlined, ExclamationCircleOutlined } from "@ant-design/icons";
import { Button, Space, Upload, App, Tooltip } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { exportToExcel, importFromExcel, exportMultiSheetExcel, type ExcelColumnMapping, type ExcelSheetData } from "../../utils/excel";

interface ExcelActionsProps {
	/** 내보낼 데이터 (단일 시트용) */
	exportData?: any[];
	/** 여러 시트 데이터 (멀티 시트용) */
	sheets?: ExcelSheetData[];
	/** 엑셀 컬럼 매핑 (단일 시트용) */
	columns: ExcelColumnMapping[];
	/** 저장될 파일명 */
	fileName: string;
	/** 데이터 업로드(임포트) 콜백 */
	onImport?: (data: any[]) => void;
	/** 업로드 기능 활성화 여부 */
	uploadEnabled?: boolean;
}

/**
 * 전역 공통 엑셀 액션 버튼 모듈
 * (Bento Standard UI 준수 + 안전 업로드 로직)
 */
const ExcelActions: React.FC<ExcelActionsProps> = ({
	exportData = [],
	sheets,
	columns,
	fileName,
	onImport,
	uploadEnabled = true,
}) => {
	const { t } = useTranslation();
	const { message, modal } = App.useApp();

	// 엑셀 다운로드 실행
	const handleDownload = () => {
		if (sheets && sheets.length > 0) {
			exportMultiSheetExcel(sheets, fileName);
			return;
		}

		if (exportData.length === 0) {
			message.warning(t("common.no_data_to_export"));
			return;
		}
		exportToExcel(exportData, columns, fileName);
	};

	// 양식 다운로드 (데이터 없이 헤더만)
	const handleTemplateDownload = () => {
		exportToExcel([], columns, `${fileName}_양식`);
	};

	// 엑셀 업로드 전 파싱 및 최종 확인
	const handleBeforeUpload = async (file: File) => {
		try {
			const data = await importFromExcel(file);
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
						<p style={{ color: "#ff4d4f", fontWeight: "bold" }}>
							{t("common.excel_import_confirm_msg")}
						</p>
					</div>
				),
				okText: t("common.confirm"),
				cancelText: t("common.cancel"),
				onOk: () => {
					onImport?.(data);
					message.success(t("common.import_success"));
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
				<Button
					type="text"
					icon={<FileExcelOutlined />}
					onClick={handleTemplateDownload}
				/>
			</Tooltip>

			{/* 2. 엑셀 업로드 */}
			{uploadEnabled && onImport && (
				<Upload
					accept=".xlsx, .xls"
					showUploadList={false}
					beforeUpload={handleBeforeUpload}
				>
					<Tooltip title={t("common.excel_upload")}>
						<Button type="text" icon={<UploadOutlined />} />
					</Tooltip>
				</Upload>
			)}

			{/* 3. 데이터 다운로드 */}
			<Tooltip title={t("common.excel_download")}>
				<Button
					type="text"
					icon={<DownloadOutlined />}
					onClick={handleDownload}
					disabled={exportData.length === 0 && (!sheets || sheets.length === 0)}
				/>
			</Tooltip>
		</Space.Compact>
	);
};

export default ExcelActions;
