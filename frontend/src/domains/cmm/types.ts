/**
 * CMM (Common Module Management) 도메인 타입 정의.
 * 백엔드 모델(models.py) 및 스키마(schemas.py)와 구조를 일치시킵니다.
 */

// 1. 가변 속성(JSONB) 값의 타입 정의
export type PropValue = string | number | boolean | null | undefined;

// 2. 시스템 도메인 인터페이스 (cmm.system_domains)
export interface SystemDomain {
	domain_code: string; // PK (3자리, 예: FAC)
	domain_name: string;
	schema_name: string;
	description?: string;
	is_active: boolean;
	created_at: string;
}

// 3. 코드 그룹 인터페이스 (cmm.code_groups)
export interface CodeGroup {
	group_code: string; // PK
	group_name: string;
	description?: string;
	is_system: boolean;
	is_active: boolean;
	created_at?: string;
	updated_at?: string;
}

// 4. 상세 코드 인터페이스 (cmm.code_details)
// 제네릭 T를 사용하여 props 내부 구조를 상황에 맞게 확장 가능
export interface CodeDetail<T = Record<string, PropValue>> {
	group_code: string; // FK
	detail_code: string; // PK
	detail_name: string;
	props: T; // JSONB 속성 대응
	sort_order: number;
	is_active: boolean;
	created_at?: string;
}

// 5. 첨부파일 인터페이스 (cmm.attachments)
export interface Attachment {
	file_id: string; // UUID
	domain_code: string;
	ref_id: string; // 연관 업무 PK (FAC_001 등)
	file_name: string; // 원본 파일명
	file_path: string; // MinIO 저장 경로
	file_size: number; // BIGINT 대응
	content_type: string;
	is_deleted: boolean;
	created_at: string;
}

// 6. 첨부파일 수정을 위한 Partial 타입
export interface AttachmentUpdate {
	ref_id?: string;
	file_name?: string;
}

// 7. 시퀀스 응답 타입
export interface SequenceResponse {
	sequence: string; // 예: "FAC-2026-001"
}
