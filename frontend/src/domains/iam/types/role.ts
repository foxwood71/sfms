import type { BaseResponse } from "@/shared/types/api";

/**
 * 역할(Role) 기본 정보 인터페이스
 */
export interface Role {
  id: number;
  code: string;
  name: string;
  description: string | null;
  permissions: Record<string, string[]>; // {"FAC": ["READ", "WRITE"], ...} 형태
  is_active: boolean;
  is_system: boolean;
  created_at: string;
  updated_at: string;
}

/**
 * 역할 생성 요청 인터페이스
 */
export interface RoleCreate {
  code: string;
  name: string;
  description?: string;
  permissions?: Record<string, string[]>;
  is_active?: boolean;
}

/**
 * 역할 수정 요청 인터페이스
 */
export interface RoleUpdate {
  name?: string;
  description?: string;
  permissions?: Record<string, string[]>;
  is_active?: boolean;
}

/**
 * 권한 리소스 메타데이터 인터페이스
 * GET /roles/permissions/resources 응답용
 */
export interface PermissionResource {
  [domainCode: string]: {
    name: string;
    actions: {
      action: string;
      label: string;
    }[];
  };
}

/**
 * 사용자 역할 할당 요청 인터페이스
 */
export interface UserRoleUpdate {
  user_id: number;
  role_ids: number[];
}
