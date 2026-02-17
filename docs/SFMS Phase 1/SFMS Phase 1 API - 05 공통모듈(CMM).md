# 📘 SFMS Phase 1 API - 05 공통 관리 (CMM) 상세 명세서 (Revised v1.3)

* **문서 버전:** v1.3 (Production Ready)
* **작성일:** 2026-02-17
* **관련 스키마:** `cmm.*` (codes, attachments, notifications, logs, sequences)
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

**보완점:** Pydantic v2 `ConfigDict` 적용, `Enum` 활용, **시스템 상태** 및 **다중 파일 처리** 모델을 추가했습니다.

### 1.1 Backend Models (Python/Pydantic)

파일 위치: `app/modules/cmm/schemas.py`

```python
from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
import uuid

# [Enum] 정렬 방향
class SortDirection(str, Enum):
    ASC = "asc"
    DESC = "desc"

# [Enum] 이미지 리사이징 옵션 (프론트엔드 최적화)
class ImageResizeOption(str, Enum):
    ORIGINAL = "original"
    THUMBNAIL = "thumbnail" # 200x200 (목록용)
    MEDIUM = "medium"       # 800x600 (상세용)

# --------------------------------------------------------
# [System] 시스템 상태 (New)
# --------------------------------------------------------
class HealthCheckResponse(BaseModel):
    status: str = "ok"
    db_connection: bool
    redis_connection: bool
    version: str
    server_time: datetime

# --------------------------------------------------------
# [Common Code] 공통 코드
# --------------------------------------------------------
class CodeGroupBase(BaseModel):
    group_code: str = Field(..., pattern=r"^[A-Z0-9_]+$")
    domain_code: str = Field(..., min_length=3, max_length=3)
    group_name: str
    description: Optional[str] = None
    is_active: bool = True

class CodeDetailBase(BaseModel):
    detail_code: str = Field(..., pattern=r"^[A-Z0-9_]+$")
    detail_name: str
    props: Dict[str, Any] = Field(default_factory=dict)
    sort_order: int = 0
    is_active: bool = True

class CodeLookUpItem(BaseModel):
    value: str  # detail_code
    label: str  # detail_name
    props: Dict[str, Any] = {}
    sort_order: int

# --------------------------------------------------------
# [File] 첨부파일 (Multi-Upload 지원)
# --------------------------------------------------------
class FileUploadResult(BaseModel):
    id: uuid.UUID
    file_name: str
    file_path: str
    file_size: int
    content_type: str
    url: str
    thumbnail_url: Optional[str] = None # 이미지인 경우 썸네일 경로

class MultiFileUploadResponse(BaseModel):
    success_count: int
    failed_count: int
    results: List[FileUploadResult]
    errors: Optional[List[Dict[str, Any]]] = None # 실패 파일명 및 사유

# --------------------------------------------------------
# [Sequence] 채번 규칙 제어 (New)
# --------------------------------------------------------
class SequenceRuleRead(BaseModel):
    id: int
    domain_code: str
    prefix: str
    current_year: str
    current_seq: int
    padding_length: int
    description: Optional[str]
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

class SequenceResetRequest(BaseModel):
    current_seq: int = Field(..., ge=0, description="강제 설정할 시퀀스 번호")
    reason: str = Field(..., min_length=5, description="변경 사유 (Audit Log 필수)")

```

### 1.2 Frontend Interfaces (TypeScript)

파일 위치: `src/api/cmm/types.ts`

```typescript
// [System]
export interface SystemHealth {
  status: string;
  db_connection: boolean;
  version: string;
}

// [File]
export interface FileUploadResult {
  id: string; // UUID
  file_name: string;
  url: string;
  thumbnail_url?: string;
}

export interface MultiFileUploadResponse {
  success_count: number;
  failed_count: number;
  results: FileUploadResult[];
  errors?: { file_name: string; reason: string }[];
}

// [Sequence]
export interface SequenceRule {
  id: number;
  domain_code: string;
  prefix: string;
  current_seq: number;
  description?: string;
}

```

---

## 2. ⚙️ 시스템 유틸리티 API (System) - **[신규 추가]**

**운영 및 모니터링(DevOps)**을 위한 필수 API입니다. 로드밸런서(AWS ALB, Nginx) 설정 시 반드시 필요합니다.

### 2.1 헬스 체크 (Liveness/Readiness Probe)

* **URL:** `GET /api/v1/system/health`
* **Auth:** **Public (인증 제외 설정 필수)**
* **Response:** `HealthCheckResponse`
* **Logic:**
* DB `SELECT 1` 수행 (연결 확인)
* Redis `PING` 수행 (캐시 확인)
* 하나라도 실패 시 HTTP 503 Service Unavailable 반환.



### 2.2 서버 시간 조회

* **URL:** `GET /api/v1/system/time`
* **Response:** `{ "server_time": "2026-02-17T20:30:00+09:00", "timezone": "KST" }`
* **Use Case:** 클라이언트(Browser)와 서버 간 시간 동기화 문제 해결.

---

## 3. 🗂️ 공통 코드 관리 API (Codes)

### 3.1 코드 그룹/상세 관리 (CRUD)

*(기존 v1.0 내용과 유사하나 Pydantic v2 모델 적용)*

### 3.2 [핵심] 프론트엔드 코드 조회 (Lookup)

* **URL:** `GET /api/v1/cmm/codes/{group_code}/lookup`
* **Response:** `ApiResponse<List[CodeLookUpItem]>`
* **Performance:** **Redis 캐싱(`@cache(expire=3600)`) 적용 필수.** 코드는 자주 변하지 않으므로 DB 부하를 줄여야 합니다.

---

## 4. 📂 파일/첨부파일 관리 API (Attachments) - **[대폭 보완]**

기존 단건 업로드 방식은 현장 사진(여러 장) 업로드 시 매우 불편합니다. **다중 업로드**와 **이미지 리사이징**을 지원하도록 개선했습니다.

### 4.1 다중 파일 업로드 (Multi-Upload)

* **URL:** `POST /api/v1/cmm/files/upload`
* **Content-Type:** `multipart/form-data`
* **Form Data:**
* `files`: `List[UploadFile]` (FastAPI List 타입 사용, 최대 10개 권장)
* `domain_code`: `FAC`, `USR` 등
* `category_code`: `EVIDENCE`, `PROFILE` 등


* **Response:** `ApiResponse<MultiFileUploadResponse>`
* **Logic:**
1. **Validation:** 허용되지 않는 확장자(.exe, .sh) 및 개별 파일 용량(10MB) 체크.
2. **Image Processing:** 이미지 파일(`image/*`)인 경우 `Pillow` 라이브러리를 사용해 썸네일(200px) 자동 생성 및 메타데이터(Exif) 제거.
3. **Storage:** UUID로 파일명 난수화 후 저장 (원본 + 썸네일).
4. **DB Transaction:** 성공한 파일만 `cmm.attachments`에 Insert.
5. **Partial Success:** 일부 파일 실패 시 에러 400이 아닌 `200 OK`와 함께 실패 목록(`errors`)을 반환하여 프론트엔드에서 재시도 유도.



### 4.2 파일 다운로드 및 썸네일 조회

* **URL:** `GET /api/v1/cmm/files/{file_id}/download`
* **Query Params:**
* `size`: `original` (기본값) | `thumbnail` | `medium`


* **Logic:**
* `size=thumbnail` 요청 시, 스토리지의 `_thumb` 접미사 파일을 스트리밍.
* 썸네일이 없으면 원본을 실시간 리사이징(On-the-fly) 하거나 원본 반환.
* **Browser Cache:** `Cache-Control: max-age=86400` 헤더를 추가하여 트래픽 절감.



---

## 5. 🔢 채번 규칙 관리 API (Sequences) - **[기능 보완]**

### 5.1 채번 규칙 목록 조회

* **URL:** `GET /api/v1/cmm/sequences`
* **Response:** `ApiResponse<List[SequenceRuleRead]>`

### 5.2 시퀀스 강제 조정 (Reset) - **[Admin Only]**

DB 마이그레이션 오류나 테스트 시 번호를 초기화해야 할 때 필요합니다.

* **URL:** `PATCH /api/v1/cmm/sequences/{id}/reset`
* **Body:** `SequenceResetRequest` (변경할 번호, 사유)
* **Auth:** **Super Admin 권한 필수**
* **Logic:**
1. DB Row Lock (`SELECT ... FOR UPDATE`) 획득.
2. `current_seq` 값 변경.
3. **Audit Log:** "누가", "왜", "몇 번으로" 변경했는지 `cmm.audit_logs`에 기록 (`action_type: SEQ_RESET`).



---

## 6. 📜 시스템 감사 로그 API (Audit Logs)

*(기존 v1.0 내용과 동일하게 PGroonga 검색 지원)*

---

## 7. 🔔 알림 관리 API (Notifications)

*(기존 v1.0 내용과 동일)*

---

## 8. ⚠️ 표준 에러 코드 (Standard Error Codes)

v1.3에서 **파일 및 시스템 관련 에러**가 추가되었습니다.

| HTTP | Code | Name | Description |
| --- | --- | --- | --- |
| **207** | `2070` | `PARTIAL_SUCCESS` | 다건 처리 중 일부만 성공함 (결과 payload 확인 필요) |
| **400** | `4005` | `FILE_TOO_LARGE` | 개별 파일 크기가 제한을 초과했습니다. |
| **400** | `4006` | `INVALID_FILE_TYPE` | 허용되지 않는 파일 형식입니다. |
| **429** | `4290` | `TOO_MANY_REQUESTS` | API 호출 빈도 제한 초과 (Rate Limiting) |
| **503** | `5030` | `SERVICE_UNAVAILABLE` | DB 또는 Redis 연결 실패 (Health Check) |

---

## 9. ✅ 구현 체크리스트 (Final Checklist)

이 체크리스트를 개발 완료 조건(Definition of Done)으로 사용하십시오.

* [ ] **Health Check Bypass**: `FastAPI` 미들웨어 설정에서 `/api/v1/system/health` 경로는 JWT 인증을 거치지 않도록 예외 처리했는가?
* [ ] **Image Processing**: `Pillow` 라이브러리를 설치하고, 업로드 시 이미지 스트립(Exif 제거) 로직을 구현했는가?
* [ ] **Transaction Scope**: 파일 업로드(S3/Disk I/O)는 **DB 트랜잭션 외부**에서 수행하여 DB Lock 시간을 최소화했는가?
* [ ] **Bulk Error Handling**: 다중 파일 업로드 시 1개가 실패해도 나머지는 성공하도록 `try-except` 블록을 개별 파일 단위로 적용했는가?
* [ ] **Admin Guard**: 시퀀스 리셋 API(`PATCH .../reset`)에 `SuperUser` 전용 의존성(`Depends(get_super_user)`)을 적용했는가?
* [ ] **CORS Policy**: 프론트엔드 개발 서버(`localhost:3000`) 및 운영 도메인만 허용하도록 설정했는가?