# 📄 SFMS Phase 1 - 프론트엔드 화면 및 컴포넌트 명세서

* **버전:** v1.5 (Bento v1.1 Standard)
* **최종 수정일:** 2026-03-21
* **기술 스택:** React 19, Ant Design v5, ProComponents
* **디자인 원칙:** **Icon-centric UI, Fixed Viewport, Zero-Card-Scroll**

---

## 1. 🧩 전역 UI/UX 표준 (Global Standards)

### 1.1 레이아웃 (Fixed Layout)
*   **고정 영역**: 상단 헤더(Header) 및 사이드바(Sider) 고정.
*   **콘텐츠 영역**: `100vh`에서 헤더/푸터를 제외한 순수 콘텐츠 높이(`LAYOUT_CONSTANTS.CONTENT_HEIGHT`)를 엄격히 준수.
*   **스플리터(Splitter)**: 좌측 트리와 우측 상세 영역은 `Splitter`로 구분하며, 사용자의 분할 비율을 `localStorage`에 저장하여 유지.

### 1.2 아이콘 및 인터랙션 (Icon-centric & Tooltip)
*   **액션 버튼**: 테이블 툴바의 필터, 새로고침, 추가 버튼 등은 **아이콘만 노출**하여 가독성 확보.
*   **툴팁 강제**: 모든 아이콘 단독 버튼은 `Tooltip`으로 감싸 기능을 설명해야 함.
*   **피드백**: 모든 저장/삭제 행위는 `App.useApp()`의 `message` 또는 `notification`을 통해 로케일 기반 메시지 출력.

---

## 2. 🧱 주요 공통 컴포넌트 (Shared Components)

### 2.1 조직도 트리 (`OrgTree`)
*   **루트 노드**: 고정된 상위 노드 `"전체 조직도"` (`ApartmentOutlined`) 표시.
*   **아이콘**: 각 부서 노드는 `ClusterOutlined` 아이콘 적용.
*   **비활성**: `is_active: false`인 항목은 회색 텍스트 및 취소선 적용.

### 2.2 공통 코드 선택 (`OrgTreeSelect` / `CodeSelect`)
*   **TreeSelect**: 부서 선택 시 사용. `styles={{ popup: { root: { ... } } }}` 최신 속성 적용.
*   **Lookup**: `staleTime: Infinity` 설정으로 캐시 최적화.

---

## 🖥️ 3. 핵심 페이지 명세 (Screen Specs)

### 3.1 👤 사용자 관리 (`/usr/users`)
*   **레이아웃**: `Splitter` (30% 조직도 트리 / 70% 사용자 목록).
*   **필터**: 플로팅 박스 내 키워드 검색 및 비활성(퇴사자) 포함 스위치 제공.
*   **테이블**: 10행 기준 스크롤, 직위/직책 맵핑 렌더링.

### 3.2 ⚙️ 감사 로그 (`/sys/audit-logs`)
*   **목적**: 시스템 행위 추적 및 데이터 변경 이력 확인.
*   **특수 기능**:
    *   **날짜 범위 필터**: `RangePicker`를 통한 정밀 기간 조회.
    *   **활성 필터 태그**: 적용된 필터 조건들을 `Tag` 형태로 표시하고 개별 취소 지원.
    *   **스냅샷 뷰어**: 상세 아이콘(`CameraOutlined`) 클릭 시 JSON 스냅샷 데이터를 코드 블록 형태로 모달 출력.

---

## 🌐 4. 다국어(i18n) 적용 지침

1.  **하드코딩 금지**: 모든 텍스트는 `t("key")` 형태여야 함.
2.  **리소스 관리**: `KO_MESSAGES` 상수 객체에서 `common`, `menu`, `user`, `org`, `sys`, `errors` 도메인별 관리.
3.  **동적 매핑**: 백엔드에서 온 영문 코드(예: `USER_NOT_FOUND`)는 `MESSAGES.ERRORS[code]`를 통해 즉시 변환.

---

## 🚀 5. 구현 체크리스트 (UI/UX)

* [x] 모든 아이콘 버튼에 `Tooltip`이 적용되었는가?
* [x] 테이블 데이터가 10건 이하일 때 불필요한 스크롤바가 생기지 않는가?
* [x] `Splitter` 비율이 페이지 이동 후에도 유지되는가?
* [x] 하드코딩된 한글 문자열이 남아있지 않은가? (`grep` 검색 필수)
