# 📘 SFMS Phase 1: 프론트엔드 아키텍처 및 UI 표준

* **프로젝트명:** SFMS (Smart Facility Management System)
* **최종 수정일:** 2026-03-08
* **단계:** Phase 1 (Foundation & UI Standards)
* **기술 스택:**
    * **Core:** React 19 (with v5 Patch), TypeScript 5.x, Vite 6.x
    * **UI Framework:** **Ant Design v5**, **ProComponents**
    * **State Management:** TanStack Query v5 (Server), Zustand (Global UI)
    * **Styling:** Tailwind CSS 4, AntD Design Token
    * **Lint/Format:** Biome (Strict mode)

---

## 1. 🏗️ 아키텍처 개요 (Architecture Overview)

**"복잡한 데이터를 한눈에, 수정은 안전하게"**
데이터 중심의 엔터프라이즈 애플리케이션을 위해 서버 데이터와 UI 상태를 엄격히 분리하여 관리합니다.

### 1.1 데이터 흐름 (Data Flow)
* **Server State**: `TanStack Query`가 모든 API 통신, 캐싱, 동기화를 전담합니다.
* **Client State**: `Zustand`가 테마, 사이드바 상태, 인증 토큰 등 전역 UI 상태를 관리합니다.
* **API Client**: `Axios` 인터셉터를 통해 401(토큰 만료), 403(권한 부족) 에러를 통합 처리합니다.

---

## 📂 2. 디렉토리 구조 (Directory Structure)

백엔드의 DDD 구조와 보조를 맞추어 도메인 응집도를 극대화합니다.

```text
frontend/src/
├── app/                    # 앱 전역 설정 (Router, Providers)
├── shared/                 # [공통] 도메인 무관 재사용 요소
│   ├── api/                # Axios Interceptors
│   ├── components/         # 공통 UI (Button, Modal)
│   ├── hooks/              # useAuth, useMessage 등
│   └── stores/             # Zustand UI Stores
├── domains/                # [도메인] 백엔드 모듈과 1:1 매핑
│   ├── cmm/                # 코드, 파일, 알림
│   ├── sys/                # 감사로그, 채번 설정
│   ├── usr/                # 조직도, 사용자 관리
│   └── fac/                # 시설, 공간 트리
│       ├── api/            # 해당 도메인 API 호출 함수
│       ├── components/     # 도메인 전용 컴포넌트 (FacilityTree.tsx)
│       ├── hooks/          # React Query Hooks (useFacilityList)
│       ├── types/          # TypeScript 인터페이스 (Zod 스키마)
│       └── pages/          # 라우팅 페이지 (FacilityPage.tsx)
└── styles/                 # 전역 스타일 (Tailwind, AntD Theme)
```

---

## 📝 3. 코드 문서화 표준 (Documentation Standards)

유지보수성과 협업 효율을 위해 모든 코드는 **TSDoc** 규범을 준수하여 문서화합니다.

### 3.1 TSDoc 작성 규칙
* 모든 **Export되는 요소**(컴포넌트, 함수, 클래스, 인터페이스)는 TSDoc 주석을 필수로 포함합니다.
* **필수 태그**: `@param`, `@returns` (함수일 경우), `@example` (복잡한 로직일 경우).

### 3.2 컴포넌트 및 Props 문서화 예시
Props 인터페이스의 각 필드에는 인라인 주석(`/** ... */`)을 달아 VS Code 인텔리센스에서 설명이 노출되도록 합니다.

```tsx
/**
 * 시설물 관리 테이블 컴포넌트
 * 
 * @description 시설 목록을 그리드로 표시하고 필터링/페이징 기능을 제공합니다.
 * @see {@link https://procomponents.ant.design/en-US/components/table ProTable}
 */
interface FacilityTableProps {
  /** 조회 대상 시설 카테고리 코드 (예: 'WTP') */
  categoryCode?: string;
  /** 데이터 수정 성공 시 호출되는 콜백 함수 */
  onSuccess?: () => void;
  /** 읽기 전용 모드 여부 (기본값: false) */
  readOnly?: boolean;
}

export const FacilityTable: React.FC<FacilityTableProps> = ({ 
  categoryCode, 
  onSuccess, 
  readOnly = false 
}) => {
  // ... 구현부
};
```

### 3.3 커스텀 훅(Custom Hooks) 문서화
```typescript
/**
 * 특정 시설의 상세 정보를 조회하는 React Query 훅
 * 
 * @param facilityId 시설 고유 ID
 * @returns { isLoading, data, error } 쿼리 결과 객체
 * @example
 * const { data } = useFacilityDetail(101);
 */
export const useFacilityDetail = (facilityId: number) => {
  // ...
};
```

---

## 🎨 4. UI/UX 및 테마 표준

### 4.1 Ant Design v5 Theme (High Density)
AntD의 기본 여백을 축소하여 전문적인 데이터 밀도를 유지합니다.

```typescript
// src/styles/theme.ts
export const sfmsTheme = {
  token: {
    fontSize: 13,
    borderRadius: 4,
    fontFamily: "Pretendard, system-ui, sans-serif",
  },
  components: {
    Layout: {
      headerBg: '#ffffff', // 최신 토큰 명칭 준수
      bodyBg: '#f5f5f5',
      triggerBg: '#001529',
    },
    Table: {
      cellPaddingBlock: 8,
      headerBg: '#fafafa',
    }
  },
};
```

### 4.2 메시지 및 알림 호출 (중요)
`message.success()` 등의 정적 호출은 테마가 미적용될 수 있으므로, 반드시 **`App.useApp()`** 훅을 통해 추출한 객체를 사용합니다.

```tsx
const { message, modal, notification } = App.useApp();
// 사용: message.success('처리되었습니다');
```

---

## 🛡️ 5. 개발 및 보안 표준

### 5.1 인증 가드 (AuthGuard)
* 모든 보호된 경로는 `AuthGuard` 컴포넌트로 감싸 토큰 유효성을 체크합니다.
* 토큰 만료 시 `Refresh Token Rotation` 로직이 자동으로 실행됩니다.

### 4.2 권한 제어 (RBAC)
* `IAM` 도메인에서 내려주는 리소스별 액션 매트릭스를 기반으로 버튼/메뉴 노출을 제어합니다.
* 예: `can('FAC', 'WRITE')` 형식의 유틸리티 사용 권장.

---
