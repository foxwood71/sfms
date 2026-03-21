import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type { AuditLogParams, AuditLogResponse } from "../types";

/**
 * 감사 로그 목록 조회 API
 */
export const getAuditLogsApi = (params: AuditLogParams): Promise<APIResponse<AuditLogResponse>> => 
    http.get("/sys/audit-logs", { params }).then(res => res.data);
