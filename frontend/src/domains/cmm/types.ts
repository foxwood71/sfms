/**
 * CMM (Common Module Management) 도메인 타입 정의.
 * 백엔드 모델(models.py) 및 스키마(schemas.py)와 구조를 일치시킵니다.
 */

// 1. 가변 속성(JSONB) 값의 타입 정의 (Zero Any Policy)
export type PropValue = string | number | boolean | null | undefined;
export type PropsRecord = Record<string, PropValue>;

// 2. 시스템 도메인 인터페이스
export interface SystemDomain {
    domain_code: string;
    domain_name: string;
    description?: string;
    is_active: boolean;
    created_at: string;
}

// 3. 코드 그룹 인터페이스 (신규 규격 필드 반영)
export interface CodeGroup {
    id: number;
    group_code: string;
    group_name: string;
    domain_code?: string;
    description?: string;

    // [SFMS Standard] 코드 규격 관리
    code_length: number; // 권장 코드 길이
    is_seq_used: boolean; // 순번 생성 엔진 사용 여부

    is_system: boolean;
    is_active: boolean;
    props: PropsRecord;
    details?: CodeDetail[]; // 상세 코드 목록 (Optional)
    created_at: string;
    updated_at: string;
}

// 4. 코드 그룹 생성/수정 파라미터
export interface CodeGroupParams extends Partial<Omit<CodeGroup, "id" | "details" | "created_at" | "updated_at">> {
    group_code: string;
    group_name: string;
}

// 5. 상세 코드 인터페이스
export interface CodeDetail<T = PropsRecord> {
    id: number;
    group_code: string;
    detail_code: string;
    detail_name: string;
    props: T;
    sort_order: number;
    is_active: boolean;
    created_at: string;
    updated_at: string;
}

// 6. 상세 코드 생성/수정 파라미터
export interface CodeDetailParams extends Partial<Omit<CodeDetail, "id" | "created_at" | "updated_at">> {
    group_code: string;
    detail_code: string;
    detail_name: string;
}

// 7. 첨부파일 인터페이스
export interface Attachment {
    id: string; // UUID
    domain_code: string;
    resource_type: string;
    ref_id: number;
    category_code: string;
    file_name: string;
    file_path: string;
    file_size: number;
    content_type?: string;
    org_id?: number;
    props: PropsRecord;
    is_deleted: boolean;
    created_at: string;
}

/**
 * 첨부파일 메타데이터 수정 파라미터
 */
export interface AttachmentUpdate extends Partial<Omit<Attachment, "id" | "file_path" | "file_size" | "created_at">> {}

// 8. 알림 인터페이스
export interface Notification {
    id: number;
    domain_code?: string;
    receiver_user_id: number;
    category: string;
    priority: string;
    title: string;
    content?: string;
    link_url?: string;
    props: PropsRecord;
    is_read: boolean;
    read_at?: string;
    created_at: string;
}
