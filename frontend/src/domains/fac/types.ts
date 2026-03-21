/**
 * FAC (Facility & Space Management) 도메인 타입 정의
 * 백엔드 schemas.py 및 models.py와 동기화
 */

import type { Attachment } from "../cmm/types";

/**
 * 시설 카테고리 (WTP: 하수처리장, PS: 펌프장 등)
 */
export interface FacilityCategory {
    id: number;
    code: string;
    name: string;
    description?: string;
    is_active: boolean;
}

/**
 * 최상위 시설물 (사업소/처리장)
 */
export interface Facility {
    id: number;
    category_id?: number;
    representative_image_id?: string;
    code: string;
    name: string;
    address?: string;
    is_active: boolean;
    sort_order: number;
    metadata_info: Record<string, any>;
    created_at: string;
    updated_at: string;
}

/**
 * 공간 물리적 유형 (BLDG: 건물, FLOOR: 층, ROOM: 호실 등)
 */
export interface SpaceType {
    id: number;
    code: string;
    name: string;
    is_active: boolean;
}

/**
 * 공간 기능적 용도 (OFFICE: 사무실, ELEC: 전기실 등)
 */
export interface SpaceFunction {
    id: number;
    code: string;
    name: string;
    is_active: boolean;
}

/**
 * 시설 내부 공간 계층 (Tree)
 */
export interface Space {
    id: number;
    facility_id: number;
    parent_id?: number;
    representative_image_id?: string;
    space_type_id?: number;
    space_function_id?: number;
    code: string;
    name: string;
    area_size?: number;
    is_active: boolean;
    sort_order: number;
    is_restricted: boolean;
    org_id?: number;
    metadata_info: Record<string, any>;
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
