// src/domains/cmm/api.ts

import { http } from "@/shared/api/http";
import type { CodeGroup, CodeDetail } from "./types";

// 기존 함수들...
export const getCodeGroups = async () => {
  const { data } = await http.get<CodeGroup[]>("/cmm/groups");
  return data;
};

export const getCodeDetails = async (groupCode: string) => {
  const { data } = await http.get<CodeDetail[]>(`/cmm/codes/${groupCode}`);
  return data;
};

// [추가] 코드 그룹 생성 API
export const createCodeGroup = async (data: CodeGroup) => {
  // 백엔드 엔드포인트: POST /api/v1/cmm/groups
  const { data: response } = await http.post<CodeGroup>("/cmm/groups", data);
  return response;
};
