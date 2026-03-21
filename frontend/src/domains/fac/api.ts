/**
 * FAC (Facility & Space) API 호출 모듈
 */

import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type { Facility, FacilityParams, Space, SpaceParams } from "./types";

// --- 1. 시설물 (Facilities) 관리 ---

/**
 * 모든 최상위 시설 목록 조회
 */
export const getFacilitiesApi = async () => {
    const response = await http.get<APIResponse<Facility[]>>("/fac/facilities");
    return response.data;
};

/**
 * 특정 시설 상세 조회
 */
export const getFacilityDetailApi = async (id: number) => {
    const response = await http.get<APIResponse<Facility>>(`/fac/facilities/${id}`);
    return response.data;
};

/**
 * 신규 시설 등록
 */
export const createFacilityApi = async (params: FacilityParams) => {
    const response = await http.post<APIResponse<Facility>>("/fac/facilities", params);
    return response.data;
};

/**
 * 시설 정보 수정
 */
export const updateFacilityApi = async (id: number, params: FacilityParams) => {
    const response = await http.patch<APIResponse<Facility>>(`/fac/facilities/${id}`, params);
    return response.data;
};

/**
 * 시설 삭제
 */
export const deleteFacilityApi = async (id: number) => {
    const response = await http.delete<APIResponse<null>>(`/fac/facilities/${id}`);
    return response.data;
};

// --- 2. 공간 (Spaces) 관리 ---

/**
 * 특정 시설의 공간 트리 구조 조회
 */
export const getSpaceTreeApi = async (facilityId: number) => {
    const response = await http.get<APIResponse<Space[]>>(`/fac/facilities/${facilityId}/spaces`);
    return response.data;
};

/**
 * 신규 공간 생성
 */
export const createSpaceApi = async (params: SpaceParams) => {
    const response = await http.post<APIResponse<Space>>("/fac/spaces", params);
    return response.data;
};

/**
 * 공간 정보 수정
 */
export const updateSpaceApi = async (id: number, params: SpaceParams) => {
    const response = await http.patch<APIResponse<Space>>(`/fac/spaces/${id}`, params);
    return response.data;
};

/**
 * 공간 삭제
 */
export const deleteSpaceApi = async (id: number) => {
    const response = await http.delete<APIResponse<null>>(`/fac/spaces/${id}`);
    return response.data;
};
