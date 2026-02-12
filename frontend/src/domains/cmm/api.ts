import { http } from "@/shared/api/http";
import type { CodeGroup, CodeDetail } from "./types";

// 코드 그룹 목록 조회
export const getCodeGroups = async () => {
  const { data } = await http.get<CodeGroup[]>("/cmm/groups");
  return data;
};

// 특정 그룹의 상세 코드 조회
export const getCodeDetails = async (groupCode: string) => {
  const { data } = await http.get<CodeDetail[]>(`/cmm/codes/${groupCode}`);
  return data;
};

// (추후 구현) 그룹 생성, 수정, 삭제 등...
