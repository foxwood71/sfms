# 📘 SFMS Phase 1: 프론트엔드 아키텍처 및 UI 표준

* **프로젝트명:** SFMS (Smart Facility Management System)
* **최종 수정일:** 2026-03-21 (Bento Standard v1.1 업데이트)
* **단계:** Phase 1 (Foundation & UI Standards)
* **기술 스택:**
    * **Core:** React 19 (with v5 Patch), TypeScript 5.x, Vite 6.x
    * **UI Framework:** **Ant Design v5**, **ProComponents**
    * **State Management:** TanStack Query v5 (Server), Zustand (Global UI)
    * **Internationalization:** i18next, react-i18next
    * **Lint/Format:** Biome (Strict mode)

---

## 1. 🏗️ 아키텍처 개요 (Architecture Overview)

### 1.1 데이터 흐름 (Data Flow)
* **Server State**: `TanStack Query`가 모든 API 통신 및 캐싱을 전담합니다.
* **Client State**: `Zustand`가 전역 UI 상태를 관리합니다.
* **API Client**: `Axios` 인터셉터를 통한 **Silent Refresh (RTR)** 및 에러 통합 처리를 수행합니다.

---

## 🎨 2. UI/UX 벤또 표준 (Bento Standard v1.1)

사용자 경험의 일관성과 전문성을 위해 다음 레이아웃 및 디자인 표준을 강제합니다.

### 2.1 레이아웃 구조 (Fixed Layout)
* 모든 페이지는 `100vh` 기반의 **Fixed Layout**을 적용합니다.
* 브라우저 전체 스크롤을 금지(`body { overflow: hidden }`)하고 각 패널 내부에서 독립 스크롤을 구현합니다.
* **Splitter Persistence**: `Splitter`의 분할 비율은 `localStorage`에 저장하여 유지합니다.

### 2.2 카드 및 스크롤 정책 (Zero-Card-Scroll)
* **10-Row Rule**: 목록 테이블은 10개 행 기준 높이를 기본으로 설정합니다. (`LAYOUT_CONSTANTS.CONTENT_HEIGHT`)
* 상위 카드(`ProCard`) 자체는 절대 스크롤되지 않아야 하며, 스크롤은 오직 내부의 리스트 영역에만 허용합니다.

### 2.3 아이콘 중심 UI (Icon-centric & Tooltip)
* 상단 필터, 액션 버튼 등은 텍스트 라벨 대신 **아이콘 + Tooltip** 조합을 우선적으로 사용합니다.
* 모든 아이콘 버튼은 `Tooltip` 컴포넌트로 감싸 기능을 명시적으로 안내해야 합니다.

### 2.4 고도화된 필터 시스템 (Floating Filter)
* 필터 영역은 기본적으로 숨김 상태이며, 필터 버튼 클릭 시에만 플로팅 박스로 노출됩니다.
* 현재 적용된 필터 조건은 테이블 상단에 **풍선(Tag) 형태**로 표시하고, 개별 삭제 및 전체 초기화 기능을 제공합니다.

---

## 🌐 3. 다국어 및 메시지 정책 (i18n)

### 3.1 Zero Hardcoded Strings 원칙
* 모든 UI 텍스트 및 알림 메시지는 한글로 하드코딩하지 않습니다.
* `shared/locales/ko/messages.ts`에 정의된 영문 키를 `t()` 함수를 통해 호출합니다.
* **Fallback 사용 금지**: `t("key", "한글")` 형태의 기본값 제공은 지양하며, 모든 텍스트는 메시지 팩에서 관리합니다.

### 3.2 에러 메시지 처리
* 백엔드는 `USER_NOT_FOUND`와 같은 영문 코드를 전달합니다.
* 프론트엔드는 `getErrorMessage(errorKey)` 유틸리티를 사용하여 로케일에 맞는 한국어 메시지로 치환하여 출력합니다.

---

## 📝 4. 코드 문서화 및 디렉토리 구조

### 4.1 TSDoc 작성 규칙
* 모든 Export되는 요소는 TSDoc 주석을 필수로 포함합니다. (`@param`, `@returns`, `@description`)

### 4.2 디렉토리 구조
* DDD(Domain-Driven Design)를 지향하며, 각 도메인 폴더 내부에 `api`, `pages`, `components`, `types`를 독립적으로 구성합니다.

---

## 🛡️ 5. 보안 표준

### 5.1 인증 및 세션 관리
* **RTR (Refresh Token Rotation)**: 액세스 토큰 만료 시 자동으로 리프레시 토큰을 교체합니다.
* **강력한 로그아웃**: 로그아웃 시 액세스 토큰과 리프레시 토큰 모두 백엔드 블랙리스트에 등록합니다.

### 5.2 RBAC 기반 접근 제어
* 사용자의 `permissions` 매트릭스를 기반으로 메뉴 필터링 및 버튼 활성화 여부를 제어합니다.
* `"ALL": ["*"]` 권한을 가진 사용자는 시스템 슈퍼유저로 자동 감지됩니다.
