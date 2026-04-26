import type { PermissionResource } from "../../types/role";

interface UsePermissionEditorProps {
  value: Record<string, string[]>;
  onChange: (value: Record<string, string[]>) => void;
}

export const usePermissionEditor = ({ value, onChange }: UsePermissionEditorProps) => {
  // 특정 도메인-액션의 체크 여부 확인
  const isChecked = (domain: string, action: string) => {
    return value[domain]?.includes(action) || value["ALL"]?.includes("*");
  };

  // 체크박스 변경 핸들러
  const handleToggle = (domain: string, action: string) => {
    const currentActions = value[domain] || [];
    let nextActions: string[];

    if (currentActions.includes(action)) {
      nextActions = currentActions.filter((a) => a !== action);
    } else {
      nextActions = [...currentActions, action];
    }

    const nextValue = { ...value };
    if (nextActions.length > 0) {
      nextValue[domain] = nextActions;
    } else {
      delete nextValue[domain];
    }

    onChange(nextValue);
  };

  return {
    isChecked,
    handleToggle,
  };
};
