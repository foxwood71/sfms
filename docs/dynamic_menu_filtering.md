# 🔐 SFMS 동적 메뉴 필터링 가이드 (Dynamic Menu Filtering)

SFMS 프로젝트는 사용자의 역할(Role)과 권한(Permission)에 따라 사이드바 메뉴를 동적으로 구성합니다. 이 문서는 백엔드와 프론트엔드 간의 권한 연동 방식과 메뉴 필터링 로직을 설명합니다.

---

## 1. 백엔드: 권한 데이터 제공 (IAM 도메인)

### 권한 통합 로직
사용자가 여러 개의 역할을 가진 경우, 각 역할에 정의된 권한 매트릭스를 **합집합(OR)** 연산으로 통합합니다.
- **위치**: `backend/app/domains/iam/services.py` (`AuthService.get_user_with_permissions`)
- **특수 권한**: 특정 리소스에 `*` 권한이 있는 경우, 해당 도메인의 모든 액션을 허용하는 것으로 간주합니다.

### API 응답 스키마
`GET /api/v1/auth/me` 호출 시 반환되는 데이터 구조입니다.
```json
{
  "success": true,
  "data": {
    "login_id": "admin",
    "name": "관리자",
    "roles": ["SUPER_ADMIN"],
    "permissions": {
      "USR": ["READ", "CREATE", "UPDATE", "DELETE"],
      "FAC": ["*"],
      "SYS": ["READ_LOG"]
    }
  }
}
```

---

## 2. 프론트엔드: 메뉴 구성 및 필터링

### 메뉴 설정 (`menuConfig.ts`)
전체 메뉴 구조를 정의하며, 각 메뉴 아이템에 필요한 리소스와 액션을 명시합니다.
- **위치**: `frontend/src/shared/layout/menuConfig.ts`

```typescript
export const menuConfig: MenuItem[] = [
  {
    path: "/fac",
    name: "시설 및 공간",
    resource: "FAC", // 권한 체크 기준 도메인
    action: "READ",  // 필요 액션 (기본값: READ)
    routes: [
      { path: "/fac/list", name: "시설 목록" },
      { path: "/fac/register", name: "시설 등록", action: "CREATE" },
    ],
  },
  // ...
];
```

### 필터링 알고리즘 (`filterMenus`)
사용자 접속 시 다음 순서로 메뉴를 필터링합니다.
1. **슈퍼유저 체크**: `is_superuser`가 `true`인 경우 모든 필터링을 건너뛰고 전체 메뉴를 반환합니다.
2. **권한 체크**: 메뉴에 정의된 `resource`가 사용자의 `permissions` 목록에 있는지 확인합니다.
   - 사용자의 해당 리소스 권한에 `*`가 포함되어 있으면 통과.
   - 메뉴의 `action`이 사용자의 권한 리스트에 포함되어 있으면 통과.
3. **재귀적 처리**: 하위 메뉴(`routes`)가 있는 경우 자식 메뉴에 대해서도 동일한 필터링을 수행합니다.
4. **빈 메뉴 정리**: 필터링 결과 하위 메뉴가 모두 사라진 대메뉴는 사이드바에서 자동으로 제거합니다.

---

## 3. 레이아웃 통합 (`MainLayout.tsx`)

프론트엔드의 `MainLayout`은 `useAuthStore`를 구독하며, 사용자 정보가 변경될 때마다 `useMemo`를 통해 최적화된 메뉴를 계산하여 `ProLayout`에 전달합니다.

```typescript
const dynamicMenuData = useMemo(() => {
  return {
    path: "/",
    routes: filterMenus(menuConfig, user?.permissions, user?.is_superuser),
  };
}, [user]);
```

---

## 4. 권한 추가 및 수정 방법
1. **신규 메뉴 추가**: `menuConfig.ts`에 아이템을 추가하고 `resource`를 지정합니다.
2. **백엔드 권한 정의**: `PermissionService` (백엔드)의 리소스 맵에 해당 도메인을 추가합니다.
3. **역할 할당**: '권한 관리' 화면(개발 예정)에서 해당 역할에 신규 메뉴 권한을 체크합니다.

---
*최종 수정일: 2026-03-08*
