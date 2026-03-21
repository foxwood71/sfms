# 📘 SFMS Phase 1 DB - 04 인증 및 권한 관리 (IAM) 설계서

* **문서 버전:** v1.5 (Dynamic Permission Policy)
* **최종 수정일:** 2026-03-21
* **도메인:** `IAM` (Identity & Access Management)
* **관련 스키마:** `iam`

---

## 1. 🏗️ 도메인 개요
시스템의 접근 제어(RBAC)를 위한 역할 정의 및 사용자별 권한 매트릭스를 관리합니다.

---

## 2. 📊 테이블 명세

### 2.1 역할 (`iam.roles`)
사용자 그룹에 부여될 권한의 집합을 정의합니다.

| 컬럼명 | 타입 | 제약 조건 | 설명 |
| :--- | :--- | :---: | :--- |
| `id` | BIGSERIAL | PK | 역할 고유 ID |
| `name` | VARCHAR(100) | NOT NULL | 역할 명칭 (예: 시설 관리자) |
| `code` | VARCHAR(50) | NOT NULL UNIQUE | 역할 코드 (예: FAC_ADMIN) |
| `permissions` | JSONB | NOT NULL | 권한 매트릭스 (Resource-Action Pair) |
| `is_system` | BOOLEAN | DEFAULT FALSE | 시스템 필수 역할 여부 (삭제 방지) |

---

## 🔐 3. 동적 권한 시스템 (Dynamic RBAC)

### 3.1 슈퍼유저 (Superuser) 판별 원칙
SFMS는 특정 역할 코드(`ADMIN` 등)를 하드코딩하지 않습니다. 대신 `permissions` 컬럼의 데이터를 분석하여 권한을 결정합니다.

*   **판별 기준**: 보유한 역할의 `permissions` JSON 내부에 **`"ALL": ["*"]`** (또는 소문자 `all`) 설정이 포함되어 있는가?
*   **적용**: 위 조건을 충족하는 사용자는 모든 메뉴 필터링을 통과하며, 시스템 전체 데이터에 대한 CRUD 권한을 자동으로 획득합니다.

### 3.2 권한 매트릭스 구조
```json
{
  "USR": ["READ", "CREATE"],
  "FAC": ["*"],
  "IAM": ["READ"]
}
```
*   `*` (Asterisk): 해당 리소스에 대한 모든 액션 허용을 의미합니다.
*   권한 통합: 사용자가 여러 역할을 가진 경우, 각 역할의 권한을 **합집합(OR)** 연산하여 최종 권한을 산출합니다.
