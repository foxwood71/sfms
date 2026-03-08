# 📘 SFMS Phase 1: 통합 데이터베이스 설계 원칙 및 규칙 (Conventions)

* **프로젝트명:** SFMS (Sewage Facility Management System)
* **최종 수정일:** 2026-03-08
* **버전:** 2.1
* **단계:** Phase 1 (Foundation & Security)

---

## 1. 🏗️ 데이터베이스 구조 및 명명 규칙

### 1.1 스키마 구성 (Schema Structure)

도메인 중심 설계를 바탕으로 데이터를 분리하여 관리합니다.
* **`cmm` (Common)**: 공통 코드, 통합 첨부파일, 알림.
* **`sys` (System)**: 감사 로그(Audit), 채번 규칙(Sequence).
* **`iam` (Identity)**: 사용자 인증, 역할 및 권한 관리.
* **`usr` (User)**: 사용자 프로필, 조직(Organization) 계층.
* **`fac` (Facility)**: 최상위 시설물, 상세 공간(Space) 계층.

### 1.2 명명 규칙 (Naming Conventions)

* **테이블/컬럼**: 소문자 스네이크 케이스(`snake_case`)를 사용합니다.
* **인덱스**: `idx_{table}_{column}` (예: `idx_users_login_id`)
* **제약 조건**:
  * Unique: `uq_{table}_{column}`
  * Check: `chk_{table}_{column}` (예: `chk_spaces_code_upper`)

---

## 🔐 2. 데이터 무결성 및 보안 원칙

### 2.1 코드 관리 (Code Standards)

* 모든 식별 코드(`code` 컬럼)는 반드시 **모두 대문자**로 저장해야 합니다.
* **제약 조건**: `CHECK (code = UPPER(code))`를 필수로 적용하여 데이터 일관성을 보장합니다.

### 2.2 계층 구조 무결성 (Hierarchy Integrity)

* `parent_id`를 사용하는 트리 구조 테이블은 다음 제약 조건을 포함해야 합니다.
* **자기 참조 방지**: `CHECK (id <> parent_id)`
* **순환 참조 방지**: 서비스 레이어에서 자식 노드를 부모로 설정하는 행위를 사전에 차단합니다.

### 2.3 삭제 정책 (Deletion Policy)

데이터의 성격에 따라 삭제 방식을 엄격히 구분합니다.
* **논리 삭제 (Soft Delete)**: `User`, `Attachment` 등 이력 보존이 중요한 데이터.
  * `is_active = False` 또는 `is_deleted = True` 플래그를 사용합니다.
* **물리 삭제 (Hard Delete)**: `Organization`, `Space`, `Role` 등 구조적 데이터.
  * 하위 데이터(자식 또는 소속 사용자)가 존재할 경우 삭제를 차단하는 외래키 제약 조건을 활용합니다.

---

## 🛠️ 3. 공통 컬럼 및 인프라 표준

### 3.1 공통 컬럼 (Standard Columns)

거의 모든 테이블은 추적성을 위해 아래 컬럼을 보유합니다.
* `created_at`: `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
* `updated_at`: `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
* `created_by`: `BIGINT REFERENCES usr.users(id)`
* `updated_by`: `BIGINT REFERENCES usr.users(id)`

### 3.2 시간대 (Timezone)

* 모든 일시는 `TIMESTAMPTZ` 타입을 사용하며, DB에는 **UTC**로 저장합니다. 애플리케이션(FastAPI)에서 클라이언트 환경에 맞춰 변환합니다.

### 3.3 인덱싱 전략

* **전문 검색**: 한글 검색이 필요한 명칭(`name`) 컬럼에는 `PGroonga` 인덱스를 적용합니다.
* **JSONB**: 비정형 데이터(`metadata`, `snapshot`) 검색을 위해 `GIN` 인덱스를 적극 활용합니다.

### 3.4 트리거 (Trigger)

* `updated_at` 컬럼의 실시간 갱신을 위해 `sys.trg_set_updated_at()` 트리거를 모든 테이블에 부착합니다.

---

## ⚠️ 4. 배포 및 생성 순서 (Deployment Order)

스키마 간 참조 무결성(FK)으로 인해 아래 순서를 엄격히 준수해야 합니다.
1. `usr` 스키마 및 조직/사용자 테이블 생성.
2. `iam` 스키마 생성 및 권한 할당 테이블 생성.
3. `cmm`, `sys` 스키마 생성 (사용자 참조 필요).
4. `fac` 스키마 생성 (최종 도메인 데이터).
