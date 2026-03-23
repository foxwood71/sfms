# 📘 SFMS Phase 1: 통합 데이터베이스 설계 원칙 및 규칙 (Conventions)

* **프로젝트명:** SFMS (Sewage Facility Management System)
* **최종 수정일:** 2026-03-23 (표준 고도화 반영)
* **버전:** 3.0
* **단계:** Phase 1 (Foundation & Security)

---

## 1. 🏗️ 배포 및 파일 관리 표준 (Deployment Standard)

### 1.1 Phase 기반 3자리 넘버링
데이터베이스 스크립트는 프로젝트 단계(Phase)와 실행 순서를 결합한 3자리 숫자로 관리합니다.
* **`0xx` (Phase 0)**: 인프라 구축 및 부트스트래핑.
  * `000_infrastructure.sql`: 스키마 및 확장도구 생성.
  * `011_bootstrap.sql`: 시스템 관리자(ID:0) 및 최상위 조직 선행 생성.
* **`1xx` ~ `4xx` (Phase 1~4)**: 도메인별 스키마 확장.
  * `110_usr_tables.sql`, `150_fac_tables.sql` 등.
* **`9xx` (Finalization)**: 제약조건 연결 및 시드 데이터 적재.
  * `900_constraints.sql`: 외래키(FK) 일괄 적용.
  * `910_seed_data.sql`: 공통 코드 상세 데이터 적재.

### 1.2 순환 참조 해결 전략 (Skeleton-Hardening)
1. **Skeleton**: 테이블 생성 시 외래키(FK)를 제외하고 뼈대만 생성합니다.
2. **Bootstrap**: 제약조건이 없는 상태에서 초기 필수 데이터를 적재합니다.
3. **Hardening**: 모든 데이터 적재 후 `ALTER TABLE`을 통해 제약조건을 일괄 연결합니다.

---

## 🔐 2. 데이터 무결성 및 코드 표준

### 2.1 공통 코드 통합 참조 표준 (CMM Integration)
모든 분류성 기초 데이터는 `cmm.codes` 테이블로 통합하며, 다음 규격을 준수합니다.
* **참조 방식**: ID(BigInt) 대신 **3자리 영문 대문자 코드(VARCHAR)**를 사용합니다.
* **무결성 강제 (Composite FK)**: 
  * 자식 테이블에 그룹 코드를 고정값(`CHECK` 제약조건)으로 갖는 컬럼을 추가합니다.
  * `(group_code, detail_code)` 복합 외래 키를 통해 특정 그룹 내 코드만 참조하도록 강제합니다.
* **조회 인터페이스**: 각 도메인 스키마에 `v_...` 형태의 **전용 뷰(View)**를 제공하여 개발 편의성을 높입니다.

### 2.2 식별자 규격 (Naming)
* **관리 코드**: 분류 코드(Prefix) + 순번(Sequence) 조합을 권장합니다 (예: `STP001`, `ROM012`).
* **대문자 원칙**: 모든 식별 코드는 반드시 대문자로 저장하며 `CHECK (code = UPPER(code))`를 적용합니다.

---

## 🛠️ 3. 공통 컬럼 및 인프라 표준

### 3.1 공통 컬럼 (Standard Columns)
모든 테이블은 추적성을 위해 아래 컬럼을 보유합니다.
* `created_at`, `updated_at`: `TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP`
* `created_by`, `updated_by`: `BIGINT` (시스템 관리자는 0번 사용)

### 3.2 시간대 및 인덱싱
* **Timezone**: 모든 일시는 **UTC**로 저장하며 `TIMESTAMPTZ` 타입을 사용합니다.
* **전문 검색**: 명칭(`name`) 검색을 위해 `PGroonga` 인덱스를 적용합니다.
* **비정형 데이터**: `metadata` 검색을 위해 `GIN` 인덱스를 활용합니다.

---

## ⚠️ 4. 삭제 및 갱신 정책

### 4.1 삭제 정책
* **논리 삭제 (Soft Delete)**: `User`, `Attachment` 등 이력 보존이 중요한 데이터 (`is_active` 사용).
* **물리 삭제 (Hard Delete)**: `Organization`, `Space` 등 구조적 데이터 (하위 데이터 존재 시 삭제 차단).

### 4.2 자동 갱신 (Trigger)
* `sys.trg_set_updated_at()` 트리거를 사용하여 수동 조작 없이도 수정 일시가 갱신되도록 합니다.
