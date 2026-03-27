/**
 * FAC (Facility & Space Management) 도메인 타입 정의
 */

/**
 * 시설 카테고리 (공통 코드 통합 뷰)
 */
export interface FacilityCategory {
    code: string;
    name: string;
    sort_order: number;
}

/**
 * 최상위 시설물 (사업소/처리장)
 */
export interface Facility {
    id: number;
    category_code: string;
    representative_image_id?: string;
    code: string;
    name: string;
    address?: string;
    is_active: boolean;
    sort_order: number;
    metadata_info: Record<string, unknown>;
    created_at: string;
    updated_at: string;
}

/**
 * 공간 물리적 유형 (공통 코드 통합 뷰)
 */
export interface SpaceType {
    code: string;
    name: string;
    sort_order: number;
}

/**
 * 공간 기능적 용도 (공통 코드 통합 뷰)
 */
export interface SpaceFunction {
    code: string;
    name: string;
    sort_order: number;
}

/**
 * 시설 내부 공간 계층 (Tree)
 */
export interface Space {
    id: number;
    facility_id: number;
    parent_id?: number;
    representative_image_id?: string;
    space_type_code: string;
    space_func_code: string;
    code: string;
    name: string;
    area_size?: number;
    is_active: boolean;
    sort_order: number;
    is_restricted: boolean;
    org_id?: number;
    metadata_info: Record<string, unknown>;
    children?: Space[];
    created_at: string;
    updated_at: string;
}

/**
 * 시설 생성/수정 파라미터
 */
export interface FacilityParams extends Partial<Omit<Facility, "id" | "created_at" | "updated_at">> {}

/**
 * 공간 생성/수정 파라미터
 */
export interface SpaceParams extends Partial<Omit<Space, "id" | "children" | "created_at" | "updated_at">> {}
