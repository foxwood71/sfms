/**
 * CMM (Common Module Management) API 호출 모듈.
 * 백엔드 router.py의 엔드포인트와 1:1 대응하도록 설계되었습니다.
 */

import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type { Attachment, AttachmentUpdate, CodeDetail, CodeGroup } from "./types";

// --- 1. 공통 코드 그룹 관리 ---

/** 활성 코드 그룹 목록을 조회합니다. */
export const getCodeGroups = async (includeInactive = true) => {
    const response = await http.get<APIResponse<CodeGroup[]>>("/cmm/codes", {
        params: { include_inactive: includeInactive },
    });
    // response.data는 APIResponse 객체이고, response.data.data가 실제 배열 데이터임
    return response.data;
};

/** 새로운 코드 그룹을 생성합니다. */
export const createCodeGroup = async (groupData: Partial<CodeGroup>) => {
    const response = await http.post<APIResponse<CodeGroup>>("/cmm/codes", groupData);
    return response.data;
};

/** 코드 그룹 정보를 수정합니다. */
export const updateCodeGroup = async (groupCode: string, groupData: Partial<CodeGroup>) => {
    const response = await http.patch<APIResponse<CodeGroup>>(`/cmm/codes/${groupCode}`, groupData);
    return response.data;
};

/** 코드 그룹을 삭제합니다 (하위 코드 포함). */
export const deleteCodeGroup = async (groupCode: string) => {
    await http.delete(`/cmm/codes/${groupCode}`);
};

// --- 2. 상세 코드 관리 (Code Details) ---

/** 특정 그룹의 상세 코드 목록을 조회합니다. */
export const getCodeDetails = async (groupCode: string) => {
    const response = await http.get<APIResponse<CodeGroup>>(`/cmm/codes/${groupCode}`);
    // response.data는 APIResponse 객체이고, response.data.data가 실제 CodeGroup 객체임
    // 그 내부의 details 배열을 반환
    return response.data?.data?.details || [];
};

/** 공통 코드 데이터를 내보내기 위해 조회합니다. (target: all | groups | details) */
export const exportCodesApi = async (target: "all" | "groups" | "details") => {
    const response = await http.get<APIResponse<unknown>>(`/cmm/export/codes/${target}`);
    return response.data?.data;
};

/** 엑셀 데이터를 기반으로 공통 코드를 일괄 임포트합니다. */
export const importCodesApi = async (items: unknown[]) => {
    const response = await http.post<APIResponse<unknown>>("/cmm/import/codes/all", {
        items,
    });
    return response.data;
};

/** 새로운 상세 코드를 생성합니다. */
export const createCodeDetail = async (detailData: Partial<CodeDetail>) => {
    const groupCode = detailData.group_code;
    const response = await http.post<APIResponse<CodeDetail>>(`/cmm/codes/${groupCode}/details`, detailData);
    return response.data;
};

/** 상세 코드 정보를 수정합니다 (JSONB props 포함). */
export const updateCodeDetail = async (groupCode: string, detailCode: string, detailData: Partial<CodeDetail>) => {
    const response = await http.patch<APIResponse<CodeDetail>>(
        `/cmm/codes/${groupCode}/details/${detailCode}`,
        detailData,
    );
    return response.data;
};

/** 특정 상세 코드를 삭제합니다. */
export const deleteCodeDetail = async (groupCode: string, detailCode: string) => {
    await http.delete(`/cmm/codes/${groupCode}/details/${detailCode}`);
};

// --- 3. 첨부파일 관리 (MinIO 연동) ---

/** 파일을 업로드하고 DB 메타데이터를 등록합니다. */
export const uploadAttachment = async (domainCode: string, refId: string, file: File) => {
    const formData = new FormData();
    formData.append("file", file);

    const response = await http.post<APIResponse<Attachment>>(
        `/cmm/attachments/upload?domain_code=${domainCode}&ref_id=${refId}`,
        formData,
        { headers: { "Content-Type": "multipart/form-data" } },
    );
    return response.data;
};

/** 첨부파일의 메타데이터 정보를 조회합니다. */
export const getAttachmentInfo = async (fileId: string) => {
    const response = await http.get<APIResponse<Attachment>>(`/cmm/attachments/${fileId}`);
    return response.data;
};

/** 첨부파일 메타데이터(파일명 등)를 수정합니다. */
export const updateAttachmentMetadata = async (fileId: string, updateData: AttachmentUpdate) => {
    const response = await http.patch<APIResponse<Attachment>>(`/cmm/attachments/${fileId}`, updateData);
    return response.data;
};

/** 첨부파일을 논리 삭제(Soft Delete)합니다. */
export const deleteAttachment = async (fileId: string) => {
    await http.delete(`/cmm/attachments/${fileId}`);
};

// --- 4. 시스템 관리 (SYS) ---

/** 채번(Sequence)을 생성합니다. */
export const getNextSequence = async (domainCode: string, prefix: string) => {
    const response = await http.get<APIResponse<string>>(`/sys/sequence/${domainCode}/${prefix}/next`);
    return response.data?.data;
};

/** 감사 로그(Audit Logs)를 조회합니다. */
export const getAuditLogs = async (params: Record<string, unknown>) => {
    const response = await http.get<APIResponse<unknown>>("/sys/audit-logs", {
        params,
    });
    return response.data;
};
