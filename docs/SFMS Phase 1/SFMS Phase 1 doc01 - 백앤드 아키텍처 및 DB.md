# 📗 SFMS Phase 1: 백엔드 아키텍처 및 DB 설계 표준

* **프로젝트명:** SFMS (Smart Facility Management System)
* **최종 수정일:** 2026-03-21 (API 응답 및 페이징 표준 고도화)
* **단계:** Phase 1 (Foundation & Core API)
* **기술 스택:**
    * **Language:** Python 3.13 (with `uv` package manager)
    * **Framework:** **FastAPI**
    * **ORM:** SQLAlchemy 2.0 (Async mode)
    * **Database:** **PostgreSQL 16** (with PGroonga), **Redis 7**
    * **Validation:** Pydantic v2

---

## 1. 🏗️ API 설계 표준 (RESTful API)

### 1.1 공통 응답 규격 (Global Response)
모든 API 응답은 `APIResponse` 클래스로 래핑되어 일관된 본문을 반환합니다.

```json
{
  "domain": "USR",
  "success_code": 2000,
  "message": "SUCCESS",
  "data": { ... }
}
```

### 1.2 목록 조회 및 페이징 표준
대량의 데이터를 반환하는 목록 API는 반드시 페이징 처리를 수행하며, `data` 필드 내부에 목록과 전체 건수를 포함합니다.

* **요청 파라미터**: `page` (1부터 시작), `size` (페이지 크기)
* **응답 규격**: 
  ```json
  "data": {
    "items": [ ... ],
    "total": 1250
  }
  ```

### 1.3 에러 처리 정책
* 백엔드는 가독성을 위한 한글 메시지 대신 **영문 에러 코드**를 반환합니다. (예: `USER_NOT_FOUND`, `TOKEN_BLACKLISTED`)
* 프론트엔드는 이 코드를 키로 사용하여 로케일에 맞는 언어로 치환하여 출력합니다.

---

## 🔐 2. 보안 및 권한 정책

### 2.1 인증 및 세션 (JWT)
* **Refresh Token Rotation (RTR)**: 리프레시 토큰 사용 시마다 기존 토큰을 무효화하고 새 세트를 발급합니다.
* **Token Blacklisting**: 로그아웃 시 Access/Refresh 토큰을 Redis에 등록하여 즉각적인 만료를 강제합니다.

### 2.2 동적 슈퍼유저 권한 감지
특정 역할 명칭(ADMIN 등)에 의존하지 않고, 역할에 부여된 **권한 매트릭스(JSONB)**를 기반으로 관리자 여부를 판별합니다.
* **조건**: `permissions` 데이터 내에 `{"ALL": ["*"]}` 또는 `{"all": ["*"]}` 설정이 포함된 역할을 하나라도 보유한 경우 시스템 슈퍼유저로 자동 승격됩니다.

---

## 💾 3. 데이터베이스 설계 원칙

### 3.1 스키마 구성
* 모든 도메인은 독립된 **PostgreSQL Schema**를 사용합니다. (예: `sys`, `usr`, `fac`)
* 테이블 간 참조는 외래키(FK)를 통해 무결성을 보장하며, 순환 참조 발생 시 `ALTER TABLE`을 통해 후행 선언합니다.

### 3.2 감사 로그 (Auditing)
모든 데이터의 C/U/D 행위는 `sys.audit_logs`에 기록되어야 합니다.
* **필수 기록 항목**: 행위 유형, 대상 도메인, 스냅샷(JSON), 수행자 ID, IP 주소, User-Agent.
* **보안 감사**: 로그인 성공/실패 및 계정 잠금 이벤트도 반드시 기록 범위에 포함합니다.

### 3.3 JSONB 활용 가이드
* 확장 속성(`props`, `metadata`)은 `JSONB` 타입을 사용합니다.
* **무결성 유지**: 데이터가 없을 경우 `NULL` 대신 빈 객체 **`'{}'::jsonb`**를 기본값으로 할당하여 애플리케이션 단의 파싱 에러를 방지합니다.
