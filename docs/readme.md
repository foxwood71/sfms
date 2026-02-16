# SFMS 3가지 핵심 설계서와 보조 관리 문서를 제안

## 📋 1. [필수] ERD (Entity Relationship Diagram) & 스키마 정의서

Backend가 FastAPI + SQLAlchemy(ORM) 구조이므로, 데이터 모델링이 가장 중요합니다. 특히 `PostgreSQL`의 `JSONB`를 활용하고 `ADT` 로그를 남겨야 하므로 데이터 구조가 명확해야 합니다.

* **작성 이유:** 코드 작성 중 스키마가 바뀌면 마이그레이션 비용이 큽니다.
* **포함해야 할 내용:**
* **Table:** `user`, `role`, `audit_log`, `facility` 등.
* **Column:** 타입, Nullable 여부, Default 값.
* **JSONB 구조 정의:** 특히 `audit_log.snapshot`과 같은 JSON 컬럼 내부에 어떤 Key/Value가 들어갈지 명시해야 합니다.
* **Relationship:** 1:N, M:N 관계 (특히 `User` <-> `Role` <-> `Permission`).

* **추천 도구:** Mermaid.js (텍스트로 관리 가능), dbdiagram.io, 또는 Eraser.io.

## 📋 2. [필수] API 명세서 (인터페이스 정의)

FastAPI는 Swagger(OpenAPI)가 자동 생성되지만, **"공통 응답 포맷"**과 **"에러 코드"**는 미리 정의해야 합니다.

* **작성 이유:** Frontend(React) 개발 시, Backend가 완성되지 않아도 인터페이스만 보고 Mocking 하거나 구조를 잡을 수 있습니다.
* **포함해야 할 내용:**
* **공통 Response Wrapper:** `success`, `data`, `error_code`, `message` 등을 포함한 JSON 구조 (Envelope Pattern).
* **HTTP Method 규칙:** `POST`(생성), `PUT`(전체 수정), `PATCH`(일부 수정) 구분 명확화.
* **Endpoint URL 규칙:** 예) `/api/v1/iam/users`, `/api/v1/adt/logs`.

## 📋 3. [필수] 핵심 로직 시퀀스 다이어그램 (Sequence Diagram)

모든 로직을 그릴 필요는 없습니다. **Phase 1에서 가장 복잡하고 중요한 2가지 흐름**만 그립니다.

* **대상 1: ADT(Audit) 로깅 메커니즘**
* Client 요청 -> Middleware/Decorator 포착 -> 원본 데이터 조회(Before) -> 로직 수행 -> 변경 데이터(After) -> Diff 계산 -> `ADT` 테이블 저장 -> 응답.
* *이 부분은 시스템 전체에 영향을 주므로 반드시 도식화하여 꼬이지 않게 해야 합니다.*

* **대상 2: IAM (RBAC) 인증/인가 흐름**
* Login -> JWT 발급 -> API 요청 -> Dependency Injection(`Current User`) -> Scope/Role 체크 -> 허용/거부.

## 📋 4. [관리용] 기능 명세 및 진척도 관리 (Backlog)

거창한 기획서 대신, 엑셀이나 노션(Notion), 혹은 Github Projects를 사용하여 **구현할 기능 리스트(Checklist)**를 만듭니다.

* **구조 예시:**
* [Phase 1] > [ADT] > 모델링 (Done)
* [Phase 1] > [ADT] > 미들웨어 구현 (Doing)
* [Phase 1] > [USR] > 사용자 CRUD API (Todo)

---

## 💡 Phase 1 구축을 위한 실전 문서 작성 가이드

혼자서 개발하므로 아래 순서대로 문서를 "코드로" 혹은 "간단한 마크다운으로" 작성하는 것을 추천합니다.

### Step 1. 프로젝트 구조 정의 (Project Structure)

가장 먼저 폴더 구조를 확정해야 합니다. (Clean Architecture 혹은 Domain-Driven Design 변형)

> **문서 형태:** `README.md` 혹은 `STRUCTURE.md`
>
> * `app/core`: 설정, DB, 보안, 로깅
> * `app/modules/adt`: 감사 로그 도메인
> * `app/modules/usr`: 사용자 도메인
>
>

### Step 2. 데이터베이스 스키마 (ERD) - Phase 1 범위

> **문서 형태:** `schema.prisma` (참조용) 또는 `models.py` 초안

1. **ADT_LOG:** `id`, `trace_id`, `actor_id`, `action`, `target_domain`, `target_id`, `snapshot(JSONB)`, `created_at`
2. **USR_USER:** `id`, `username`, `password_hash`, `email`, `org_id`, `status`
3. **IAM_ROLE:** `id`, `name`, `permissions(JSONB)`

#### Step 3. 권한 매트릭스 (Permission Matrix)

> **문서 형태:** 엑셀 또는 Markdown 표
> 시스템의 복잡도를 결정짓는 부분입니다.

* **행(Row):** 메뉴/기능 (예: 사용자 관리, 시설 조회)
* **열(Col):** 권한 (Read, Create, Update, Delete, Export, Approve)
* **셀(Cell):** 체크박스
  