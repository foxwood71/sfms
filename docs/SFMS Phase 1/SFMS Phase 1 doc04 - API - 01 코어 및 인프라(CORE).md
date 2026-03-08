# 📘 SFMS Phase 1 API - 01 코어 및 인프라 (CORE) 상세 명세서 (Revised v1.3)

* **문서 버전:** v1.3 (Final Implementation Sync)
* **최종 수정일:** 2026-03-07
* **도메인:** `CORE` (Infrastructure & Settings)
* **핵심 역할:** 비동기 환경 설정, 데이터베이스 세션 관리, 보안(JWT/bcrypt), 헬스 체크, 서버 시간 동기화, 전역 에러 핸들링
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

API 응답을 위한 Pydantic 스키마를 정의합니다. (Pydantic v2 기준)

**참조 위치:** `app/core/health.py`

```python
from datetime import datetime
from pydantic import BaseModel, ConfigDict

# --------------------------------------------------------
# [System] 헬스 체크 응답 구조
# --------------------------------------------------------
class HealthCheckResponse(BaseModel):
    status: str  # "ok" or "error"
    db_connection: bool
    redis_connection: bool
    minio_connection: bool
    version: str
    server_time: str  # ISO 8601 UTC

    model_config = ConfigDict(from_attributes=True)
```

---

## 2. ⚙️ 코어 시스템 API (Core System API)

### 2.1 시스템 헬스 체크 (Health Check)

* **URL:** `GET /api/v1/health`
* **Response:** `APIResponse[HealthCheckResponse]`
* **Logic:** DB, Redis, MinIO 연결 상태를 비동기로 확인하여 전체 서비스 가용성을 판별합니다.

---

## 3. 🌍 코어 인프라 설정 및 로직 (Core Settings & DB)

### 3.1 전역 환경 변수 설정 (Configuration)

**파일 위치:** `app/core/config.py` (Pydantic Settings v2 적용)

### 3.2 비동기 데이터베이스 관리 (Database)

**파일 위치:** `app/core/database.py` (SQLAlchemy Async 적용)

### 3.3 공통 응답 규격 (Unified Response)

**파일 위치:** `app/core/responses.py` (`APIResponse` 클래스)

*   **Pydantic v2 기반**: `model_validator`를 통해 도메인 코드 자동 보정(3자리 대문자) 및 성공 메시지 자동 매핑 기능을 제공합니다.
*   **유연한 호출**: `APIResponse("IAM", data=...)` (위치 인자)와 `APIResponse(domain="IAM", data=...)` (키워드 인자)를 모두 지원합니다.
*   **직렬화 안정성**: `arbitrary_types_allowed=True` 설정을 통해 SQLAlchemy 모델의 직접 직렬화를 지원합니다.

### 3.4 전역 예외 처리 (Global Exceptions)

**파일 위치:** `app/core/exceptions.py`

*   **Python 3.12+ 지원**: PEP 695 제네릭 문법(`class SFMSException[T]`)을 적용하여 타입 안정성을 확보했습니다.
*   **자동 메시지 매핑**: `message` 인자 생략 시 `ErrorCode`의 이름을 프론트엔드 i18n 키로 자동 사용합니다.

---

## 4. 🔒 보안 및 인증 표준 (Security)

*   **Password Hashing**: Python 3.13 및 최신 환경 호환성을 위해 `passlib` 대신 **`bcrypt` 라이브러리를 직접 사용**합니다.
*   **JWT Token**: `pyjwt`를 사용하며, 모든 토큰에는 `type` (access/refresh) 필드가 포함되어 용도를 엄격히 구분합니다.
*   **Rate Limit**: Redis를 사용하여 로그인 시도 횟수를 제한(분당 10회 등)합니다.

---

## 5. ⚠️ 에러 코드 정의 (Error Codes)

| HTTP | Code | Name | Description |
| --- | --- | --- | --- |
| 503 | `5030` | `SERVICE_UNAVAILABLE` | DB/Redis/MinIO 등 인프라 연결 실패 |
| 500 | `5000` | `INTERNAL_SERVER_ERROR` | 알 수 없는 서버 내부 오류 |
| 500 | `5001` | `DATABASE_ERROR` | 쿼리 실행 중 발생한 DB 에러 |
| 500 | `5003` | `STORAGE_ERROR` | MinIO 스토리지 업로드 및 처리 실패 |

---

## 6. ✅ 구현 체크리스트 (Final Checklist)

* [x] **Async Support**: 모든 I/O 작업(DB, Redis, MinIO)이 `await`를 사용하는 비동기 방식으로 구현되었는가?
* [x] **Annotated Pattern**: FastAPI 의존성 주입 시 `Annotated[Type, Depends(func)]` 문법을 사용하는가? (기본값은 반드시 `= default`로 Annotated 외부에 위치)
* [x] **Unified Response**: 모든 예외와 응답이 `APIResponse` 규격을 따르는가?
* [x] **Security**: `bcrypt` 직접 사용 및 JWT 시간 계산 오차 방지가 적용되었는가?
