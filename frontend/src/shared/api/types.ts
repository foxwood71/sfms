/**
 * 시스템 공통 에러 응답 규격
 */
export interface APIErrorResponse {
    message: string;
    code: number;
    domain: string;
}

/**
 * 시스템 공통 API 응답 규격
 */
export interface APIResponse<T = unknown> {
    /** 성공 여부 */
    success: boolean;
    /** 도메인 코드 (CMM, SYS, USR, FAC 등) */
    domain: string;
    /** 결과 코드 */
    code: number;
    /** 메시지 (성공/에러 메시지) */
    message: string;
    /** 실제 데이터 Payload */
    data: T;
}
