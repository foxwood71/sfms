/**
 * CMM (Common Module Management) API 호출 모듈.
 * 백엔드 router.py의 엔드포인트와 1:1 대응하도록 설계되었습니다.
 */

import { http } from "@/shared/api/http";
import type {
	Attachment,
	AttachmentUpdate,
	CodeDetail,
	CodeGroup,
} from "./types";

// --- 1. 공통 코드 그룹 관리 ---

/** 활성 코드 그룹 목록을 조회합니다. */
export const getCodeGroups = async () => {
	const { data } = await http.get<CodeGroup[]>("/cmm/groups"); //
	return data;
};

/** 새로운 코드 그룹을 생성합니다. */
export const createCodeGroup = async (groupData: Partial<CodeGroup>) => {
	const { data } = await http.post<CodeGroup>("/cmm/groups", groupData); //
	return data;
};

/** 코드 그룹 정보를 수정합니다. */
export const updateCodeGroup = async (
	groupCode: string,
	groupData: Partial<CodeGroup>,
) => {
	const { data } = await http.patch<CodeGroup>(
		`/cmm/groups/${groupCode}`,
		groupData,
	); //
	return data;
};

/** 코드 그룹을 삭제합니다 (하위 코드 포함). */
export const deleteCodeGroup = async (groupCode: string) => {
	await http.delete(`/cmm/groups/${groupCode}`); //
};

// --- 2. 상세 코드 관리 (Code Details) ---

/** 특정 그룹의 상세 코드 목록을 조회합니다. */
export const getCodeDetails = async (groupCode: string) => {
	// 기존의 /cmm/codes/${groupCode}에서 router.py 설계에 맞춰 경로 수정
	const { data } = await http.get<CodeDetail[]>(
		`/cmm/groups/${groupCode}/codes`,
	); //
	return data;
};

/** 새로운 상세 코드를 생성합니다. */
export const createCodeDetail = async (detailData: Partial<CodeDetail>) => {
	const { data } = await http.post<CodeDetail>(
		"/cmm/groups/details",
		detailData,
	); //
	return data;
};

/** 상세 코드 정보를 수정합니다 (JSONB props 포함). */
export const updateCodeDetail = async (
	groupCode: string,
	detailCode: string,
	detailData: Partial<CodeDetail>,
) => {
	const { data } = await http.patch<CodeDetail>(
		`/cmm/groups/${groupCode}/details/${detailCode}`, //
		detailData,
	);
	return data;
};

/** 특정 상세 코드를 삭제합니다. */
export const deleteCodeDetail = async (
	groupCode: string,
	detailCode: string,
) => {
	await http.delete(`/cmm/groups/${groupCode}/details/${detailCode}`); //
};

// --- 3. 첨부파일 관리 (MinIO 연동) ---

/** 파일을 업로드하고 DB 메타데이터를 등록합니다. */
export const uploadAttachment = async (
	domainCode: string,
	refId: string,
	file: File,
) => {
	const formData = new FormData();
	formData.append("file", file);

	const { data } = await http.post<Attachment>(
		`/cmm/upload?domain_code=${domainCode}&ref_id=${refId}`, //
		formData,
		{ headers: { "Content-Type": "multipart/form-data" } },
	);
	return data;
};

/** 첨부파일의 메타데이터 정보를 조회합니다. */
export const getAttachmentInfo = async (fileId: string) => {
	const { data } = await http.get<Attachment>(`/cmm/attachments/${fileId}`); //
	return data;
};

/** 첨부파일 메타데이터(파일명 등)를 수정합니다. */
export const updateAttachmentMetadata = async (
	fileId: string,
	updateData: AttachmentUpdate,
) => {
	const { data } = await http.patch<Attachment>(
		`/cmm/attachments/${fileId}`,
		updateData,
	); //
	return data;
};

/** 첨부파일을 논리 삭제(Soft Delete)합니다. */
export const deleteAttachment = async (fileId: string) => {
	await http.delete(`/cmm/attachments/${fileId}`); //
};

/** 첨부파일을 다운로드합니다 (Blob 형태). */
export const downloadAttachment = async (fileId: string) => {
	const response = await http.get(`/cmm/download/${fileId}`, {
		//
		responseType: "blob",
	});
	return response.data;
};

// --- 4. 기타 공통 기능 ---

/** 도메인별 새 시퀀스 번호를 생성합니다. */
export const getSequence = async (domainCode: string) => {
	const { data } = await http.get<{ sequence: string }>(
		`/cmm/sequence/${domainCode}`,
	); //
	return data;
};
