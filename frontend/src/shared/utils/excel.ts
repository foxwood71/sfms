import * as XLSX from "xlsx";

/**
 * 엑셀 컬럼 매핑 정보
 */
export interface ExcelColumnMapping {
	/** 데이터 객체의 키 */
	dataIndex: string;
	/** 엑셀 헤더에 표시될 이름 */
	title: string;
}

/**
 * 엑셀 시트 데이터 구조
 */
export interface ExcelSheetData {
	/** 시트 이름 */
	sheetName: string;
	/** 시트에 들어갈 데이터 */
	data: any[];
	/** 컬럼 매핑 */
	columns: ExcelColumnMapping[];
}

/**
 * 여러 개의 시트를 가진 엑셀 파일을 다운로드합니다.
 */
export const exportMultiSheetExcel = (
	sheets: ExcelSheetData[],
	fileName: string,
) => {
	const workbook = XLSX.utils.book_new();

	for (const sheet of sheets) {
		const excelData = sheet.data.map((item) => {
			const row: Record<string, any> = {};
			for (const col of sheet.columns) {
				row[col.title] = item[col.dataIndex];
			}
			return row;
		});
		const worksheet = XLSX.utils.json_to_sheet(excelData);
		XLSX.utils.book_append_sheet(workbook, worksheet, sheet.sheetName);
	}

	XLSX.writeFile(workbook, `${fileName}_${new Date().getTime()}.xlsx`);
};

/**
 * JSON 데이터를 엑셀 파일로 변환하여 다운로드합니다.
 * @param data 엑셀로 내보낼 데이터 배열
 * @param columns 컬럼 매핑 정보 (title, dataIndex)
 * @param fileName 저장될 파일명 (확장자 제외)
 */
export const exportToExcel = (
	data: any[],
	columns: ExcelColumnMapping[],
	fileName: string,
) => {
	// 1. 매핑 정보를 바탕으로 엑셀용 데이터 재구성
	const excelData = data.map((item) => {
		const row: Record<string, any> = {};
		for (const col of columns) {
			row[col.title] = item[col.dataIndex];
		}
		return row;
	});

	// 2. 워크시트 생성
	const worksheet = XLSX.utils.json_to_sheet(excelData);

	// 3. 워크북 생성 및 시트 추가
	const workbook = XLSX.utils.book_new();
	XLSX.utils.book_append_sheet(workbook, worksheet, "Sheet1");

	// 4. 파일 다운로드 실행
	XLSX.writeFile(workbook, `${fileName}_${new Date().getTime()}.xlsx`);
};

/**
 * 엑셀 파일을 읽어 JSON 데이터로 변환합니다.
 * @param file 업로드된 엑셀 파일
 * @returns 파싱된 JSON 데이터 배열
 */
export const importFromExcel = <T = any>(file: File): Promise<T[]> => {
	return new Promise((resolve, reject) => {
		const reader = new FileReader();

		reader.onload = (e) => {
			try {
				const data = e.target?.result;
				const workbook = XLSX.read(data, { type: "binary" });
				const firstSheetName = workbook.SheetNames[0];
				const worksheet = workbook.Sheets[firstSheetName];

				// 헤더를 키로 하여 JSON 변환
				const jsonData = XLSX.utils.sheet_to_json<T>(worksheet);
				resolve(jsonData);
			} catch (error) {
				reject(error);
			}
		};

		reader.onerror = (error) => reject(error);
		reader.readAsBinaryString(file);
	});
};
