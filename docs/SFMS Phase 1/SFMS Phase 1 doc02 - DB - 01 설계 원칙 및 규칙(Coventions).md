# 📘 SFMS Phase 1: 통합 데이터베이스 설계서 (Final Version)

* **프로젝트명:** SFMS (Sewage facility Management System)
* **작성일:** 2026-02-16
* **버전:** 2.0
* **단계:** Phase 1 (Foundation, Security, facility Base)
* **기술 스택:**
* **Database:** PostgreSQL 16+
* **Extensions:** `pgroonga` (한글/JSON 검색), `pgcrypto` (UUID)
* **File Storage:** MinIO (S3 Compatible) - DB는 메타데이터만 저장
* **변경이력**:

> 1. cmm, usr, fac 스키마 확정.
> 2. **JSONB 데이터 구조 표준 명세 추가.**

* **스키마 구조:**

> 1. **`cmm` (Common):** 공통 기준정보, 파일 레지스트리(MinIO), 감사 로그, 알림
> 2. **`ian` (Identity & Access Management):** 사용자 인증, 권한 관리
> 3. **`usr` (User):** 사용자, 조직(Organization), 권한(RBAC)
> 4. **`fac` (facility):** 시설 및 공간 계층 구조 (Tree)

---

## 1. 🏗️ 설계 원칙 및 규칙 (Conventions)

### 1.1 데이터 타입 및 식별자 전략

* **Primary Key (PK):**
  * 일반 업무 데이터: `BigSerial` (Auto-increment BigInteger) 사용. (성능 및 레거시 매핑 용이)
  * 파일/첨부 데이터: `UUID` (v4) 사용. (보안 및 분산 저장소 키 충돌 방지)

* **Timezone:**
  * 모든 일시(`DateTime`)는 `TIMESTAMPTZ` (Timezone 포함) 타입을 사용하며, DB에는 **UTC**로 저장하고 애플리케이션에서 로컬 시간(KST)으로 변환합니다.

* **JSONB 활용 (Semi-structured Data):**
  * Snake Case: JSON Key는 반드시 **스네이크 케이스(user_name)**를 사용합니다.
  * Flat Structure: 가능한 중첩(Nested) 구조를 피하고 1단계 Depth를 권장합니다.
  * Search: PGroonga 인덱스를 통해 JSON 내부의 모든 Key와 Value를 검색 가능하게 합니다.
  * 레거시 시스템의 비정형 데이터, 설비 제원, 변경 로그(`snapshot`)는 `JSONB` 컬럼에 저장하여 스키마 변경 없이 유연성을 확보합니다.

### 1.2 검색 및 인덱싱 전략

* **Full Text Search:** `PGroonga` 확장 기능을 사용하여 한글의 **중간 일치 검색**(`LIKE '%검색어%'`) 속도를 획기적으로 개선합니다.
* **JSON Search:** `Audit Log`의 변경 내역이나 `facility`의 메타데이터 검색 시 `GIN` 인덱스(PGroonga)를 사용하여 고속 검색을 지원합니다.

---

## 2. ⚠️ DB 생성 전략 (Database Create Strategy)

1. usr 스키마와 users 테이블이 먼저 생성되어야 함.

2. 그다음에 cmm.audit_logs 테이블을 생성해야 REFERENCES usr.users(id) 구문에서 "테이블을 찾을 수 없다"는 에러가 나지 않습니다.
