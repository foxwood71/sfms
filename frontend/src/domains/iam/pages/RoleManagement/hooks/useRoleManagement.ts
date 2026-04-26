import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { roleApi } from "../../api/roleApi";
import type { Role, RoleCreate, RoleUpdate } from "../../types/role";
import { message } from "antd";

export const useRoleManagement = () => {
  const queryClient = useQueryClient();
  const [selectedRoleId, setSelectedRoleId] = useState<number | null>(null);
  const [keyword, setKeyword] = useState("");

  // 역할 목록 조회
  const { data: rolesResponse, isLoading: isRolesLoading } = useQuery({
    queryKey: ["roles", keyword],
    queryFn: () => roleApi.getRoles(keyword),
  });

  // 권한 리소스 메타데이터 조회
  const { data: resourcesResponse, isLoading: isResourcesLoading } = useQuery({
    queryKey: ["permission-resources"],
    queryFn: () => roleApi.getPermissionResources(),
  });

  // 특정 역할 상세 조회
  const { data: roleDetailResponse, isLoading: isDetailLoading } = useQuery({
    queryKey: ["role", selectedRoleId],
    queryFn: () => (selectedRoleId ? roleApi.getRole(selectedRoleId) : null),
    enabled: !!selectedRoleId,
  });

  // 역할 생성 뮤테이션
  const createMutation = useMutation({
    mutationFn: (data: RoleCreate) => roleApi.createRole(data),
    onSuccess: () => {
      message.success("역할이 성공적으로 생성되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["roles"] });
    },
  });

  // 역할 수정 뮤테이션
  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: RoleUpdate }) =>
      roleApi.updateRole(id, data),
    onSuccess: () => {
      message.success("역할 정보가 수정되었습니다.");
      queryClient.invalidateQueries({ queryKey: ["roles"] });
      queryClient.invalidateQueries({ queryKey: ["role", selectedRoleId] });
    },
  });

  // 역할 삭제 뮤테이션
  const deleteMutation = useMutation({
    mutationFn: (id: number) => roleApi.deleteRole(id),
    onSuccess: () => {
      message.success("역할이 삭제되었습니다.");
      setSelectedRoleId(null);
      queryClient.invalidateQueries({ queryKey: ["roles"] });
    },
  });

  return {
    roles: rolesResponse?.data || [],
    resources: resourcesResponse?.data || {},
    selectedRole: roleDetailResponse?.data || null,
    selectedRoleId,
    setSelectedRoleId,
    keyword,
    setKeyword,
    isLoading: isRolesLoading || isResourcesLoading,
    isDetailLoading,
    createRole: createMutation.mutateAsync,
    updateRole: updateMutation.mutateAsync,
    deleteRole: deleteMutation.mutateAsync,
    isMutating: createMutation.isPending || updateMutation.isPending || deleteMutation.isPending,
  };
};
