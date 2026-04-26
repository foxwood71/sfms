import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/api/types";
import type { 
  Role, 
  RoleCreate, 
  RoleUpdate, 
  PermissionResource, 
  UserRoleUpdate 
} from "../types/role";

/**
 * 역할(Role) 관련 API 클라이언트
 */
export const roleApi = {
  /**
   * 역할 목록 조회
   */
  getRoles: (keyword?: string, page = 1, size = 100): Promise<APIResponse<Role[]>> =>
    http.get("/roles", { params: { keyword, page, size } }).then((res) => res.data),

  /**
   * 역할 상세 조회
   */
  getRole: (roleId: number): Promise<APIResponse<Role>> =>
    http.get(`/roles/${roleId}`).then((res) => res.data),

  /**
   * 역할 생성
   */
  createRole: (data: RoleCreate): Promise<APIResponse<Role>> =>
    http.post("/roles", data).then((res) => res.data),

  /**
   * 역할 수정
   */
  updateRole: (roleId: number, data: RoleUpdate): Promise<APIResponse<Role>> =>
    http.patch(`/roles/${roleId}`, data).then((res) => res.data),

  /**
   * 역할 삭제
   */
  deleteRole: (roleId: number): Promise<APIResponse<void>> =>
    http.delete(`/roles/${roleId}`).then((res) => res.data),

  /**
   * 권한 설정용 리소스 메타데이터 조회
   */
  getPermissionResources: (): Promise<APIResponse<PermissionResource>> =>
    http.get("/roles/permissions/resources").then((res) => res.data),

  /**
   * 사용자별 역할 할당 수정
   */
  assignUserRoles: (userId: number, roleIds: number[]): Promise<APIResponse<void>> => {
    const data: UserRoleUpdate = { user_id: userId, role_ids: roleIds };
    return http.put(`/roles/users/${userId}/roles`, data).then((res) => res.data);
  }
};
