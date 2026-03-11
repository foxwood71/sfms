# 📘 SFMS Phase 1 API - 04 사용자 및 조직 관리 (USR) 상세 명세서

* **문서 버전:** v1.4 (Domain-based Error Codes)
* **최종 수정일:** 2026-03-09
* **관련 스키마:** `usr.users`, `usr.organizations`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 도메인 개요
본 도메인은 시스템의 근간이 되는 조직 계층 구조(Tree)와 사용자 계정 정보를 관리합니다.

---

## 2. 📂 조직(Organization) 관리 API

### 2.1 조직 목록 조회 (트리 구조)
*   **URL:** `GET /api/v1/usr/organizations`
*   **Query Parameters:**
    *   `mode` (string, optional): `tree` (기본값) 또는 `flat`
    *   `is_active` (boolean, optional): 활성 여부 필터. `true`면 활성 조직만, 생략하면 전체 조회.

### 2.2 조직 상세 조회 / 등록 / 수정 / 삭제
(생략: 표준 REST 규격을 따름)

*   **수정 제약 (4003):** 비활성화 시 활성 상태인 하위 조직이 존재하면 `ACTIVE_CHILDREN_EXIST` 에러를 반환합니다.

---

## 3. 👤 사용자(User) 관리 API
(생략: 표준 REST 규격을 따름)

### 3.1 주요 DTO 스키마 (v1.5 Update)

#### [UserUpdate] 사용자 정보 수정
기존 기본 필드 외에 다음 필드들이 수정 가능하도록 확장되었습니다.
*   `emp_code` (string): 사원 번호 (영문 대문자, 숫자, _, - 조합)
*   `account_status` (string): 계정 상태 (`ACTIVE`, `BLOCKED`)
*   `metadata` (object): 추가 정보 (직위 `pos`, 직책 `duty` 등 JSONB 매핑)

#### [UserRead] 사용자 정보 응답
프론트엔드 UI 고도화를 위해 다음 필드들이 포함되어 반환됩니다.
*   `roles` (list[object]): 할당된 역할 리스트 (`id`, `name`, `code` 포함)
*   `metadata` (object): 직급/직책 정보가 포함된 확장 속성
*   `org_name` (string): 소속 부서 명칭 (조인 결과)

---

## 4. ⚠️ 주요 예외 및 비즈니스 에러 코드 (USR Domain)

| 결과 코드 | 코드명 | 메시지 / 설명 |
| :--- | :--- | :--- |
| `4001` | `INVALID_PARENT_ORG` | 상위 조직 정보가 유효하지 않거나 자기 참조입니다. |
| `4002` | `CIRCULAR_REFERENCE` | 조직 계층 구조에 순환 참조가 발생했습니다. |
| `4003` | `ACTIVE_CHILDREN_EXIST` | 활성 상태인 하위 조직이 있어 비활성화할 수 없습니다. |
| `4090` | `ORG_HAS_CHILDREN` | 하위 부서가 존재하여 삭제할 수 없습니다. |
| `4091` | `ORG_HAS_USERS` | 소속 사용자가 있어 삭제할 수 없습니다. |
| `4092` | `DUPLICATE_LOGIN_ID` | 이미 사용 중인 로그인 ID입니다. |
| `4093` | `DUPLICATE_EMAIL` | 이미 등록된 이메일 주소입니다. |
| `4094` | `DUPLICATE_EMP_CODE` | 이미 등록된 사원 번호입니다. |
| `4095` | `DUPLICATE_ORG_CODE` | 이미 사용 중인 조직 코드입니다. |
