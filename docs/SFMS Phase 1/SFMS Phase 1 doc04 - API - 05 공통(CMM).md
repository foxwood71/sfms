# 📘 SFMS Phase 1 API - 05 공통 관리 (CMM) 상세 명세서

* **문서 버전:** v1.3 (Context-based Recycle Bin Updated)
* **최종 수정일:** 2026-03-07
* **관련 스키마:** `cmm.code_groups`, `cmm.code_details`, `cmm.attachments`, `cmm.notifications`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (SQLAlchemy & Pydantic)

#### [Database Models]

**파일 위치:** `backend/app/domains/cmm/models.py`

```python
class CodeGroup(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_code: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    group_name: Mapped[str] = mapped_column(String(100))
    domain_code: Mapped[Optional[str]] = mapped_column(String(3))
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

class CodeDetail(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    group_code: Mapped[str] = mapped_column(String(30), ForeignKey("cmm.code_groups.group_code"))
    detail_code: Mapped[str] = mapped_column(String(30))
    detail_name: Mapped[str] = mapped_column(String(100))
    props: Mapped[Dict[str, Any]] = mapped_column(JSONB)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

class Attachment(Base):
    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True)
    domain_code: Mapped[str] = mapped_column(String(3))
    resource_type: Mapped[str] = mapped_column(String(50))
    ref_id: Mapped[int] = mapped_column(BigInteger, index=True)
    file_name: Mapped[str] = mapped_column(String(255))
    file_path: Mapped[str] = mapped_column(String(500), unique=True)
    org_id: Mapped[int | None] = mapped_column(BigInteger, index=True, comment="업로드 당시 부서 ID")
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False)

class Notification(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    receiver_user_id: Mapped[int] = mapped_column(BigInteger, index=True)
    category: Mapped[str] = mapped_column(String(20))
    title: Mapped[str] = mapped_column(String(200))
    content: Mapped[Optional[str]] = mapped_column(Text)
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
```

#### [Pydantic Schemas]

**파일 위치:** `backend/app/domains/cmm/schemas.py`

```python
from datetime import datetime
from typing import Any, Dict, List, Optional
import uuid
from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [Common Code] 공통 코드 관련 스키마
# --------------------------------------------------------
class CodeDetailRead(BaseModel):
    id: int
    group_code: str
    detail_code: str
    detail_name: str
    props: Dict[str, Any]
    sort_order: int
    is_active: bool
    model_config = ConfigDict(from_attributes=True)

class CodeGroupRead(BaseModel):
    id: int
    group_code: str
    group_name: str
    domain_code: Optional[str]
    description: Optional[str]
    is_active: bool
    is_system: bool
    details: List[CodeDetailRead] = []
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [Attachment] 첨부 파일 메타데이터 스키마
# --------------------------------------------------------
class AttachmentRead(BaseModel):
    id: uuid.UUID
    domain_code: str
    resource_type: str
    ref_id: int
    category_code: str
    file_name: str
    file_path: str
    file_size: int
    content_type: Optional[str]
    org_id: Optional[int]
    props: Dict[str, Any]
    created_at: datetime
    created_by: Optional[int]
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [Notification] 알림 관련 스키마
# --------------------------------------------------------
class NotificationRead(BaseModel):
    id: int
    category: str
    priority: str
    title: str
    content: Optional[str]
    link_url: Optional[str]
    is_read: bool
    read_at: Optional[datetime]
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)
```

---

## 2. 🔐 보안 및 권한 정책 (Security & Permissions)

파일 관리는 업무의 연속성을 위해 **'부서(조직) 기반 공유 소유권'** 모델을 따릅니다.

### 2.1 사용자별 권한 매트릭스

| 대분류 | 기능 | 일반 사용자 | 관리자(Admin) | 상세 보안 로직 |
| :--- | :--- | :---: | :---: | :--- |
| **공통 코드** | 코드 목록/상세 조회 | ✅ | ✅ | 프론트엔드 Select Box용 |
| | 코드 그룹/상세 CRUD | ❌ | ✅ | 관리자 전용 (`Superuser`) |
| **첨부파일** | 파일 업로드 | ✅ | ✅ | 모든 인증된 사용자 (부서 정보 자동 기록) |
| | **파일 삭제/복구** | ⚠️ | ✅ | 소유권 체크: **본인 또는 동일 부서원**만 가능 |
| | **삭제 목록 조회** | ⚠️ | ✅ | **컨텍스트 필터링** 지원 (본인/부서 데이터 한정) |
| | 파일 영구 삭제 | ❌ | ✅ | `permanent=true` 옵션 (물리 파기) |
| **알림 관리** | 내 알림 조회/읽음 | ✅ | ✅ | 본인 데이터만 접근 가능 |

---

## 🗂️ 3. 공통 코드 관리 API (Common Codes)

### 3.1 코드 목록 조회

* **URL:** `GET /cmm/codes`
* **Query Params:** `domain_code` (필터)

### 3.2 코드 그룹/상세 관리 (CRUD)

* **URL:** `POST /cmm/codes`, `PATCH /cmm/codes/{group_code}` 등 (상세 내용은 3.2절 참조)
* **Permission:** **관리자 전용**

---

## 📂 4. 통합 파일 관리 API (Attachments)

### 4.1 파일 업로드

* **URL:** `POST /cmm/upload`
* **Query Params:** `domain_code`, `resource_type`, `ref_id`, `category_code`
* **Logic:** 업로드 당시 사용자의 **부서 ID(`org_id`)**를 함께 기록하여 부서원 간 공유 권한을 부여합니다.

### 4.2 파일 삭제 (소프트 삭제)

* **URL:** `DELETE /cmm/attachments/{attachment_id}`
* **Permission:** 본인, 동일 부서원, 또는 관리자
* **Logic:** `is_deleted = True` 처리.

### 4.3 삭제된 파일 목록 조회 (Recycle Bin)

* **URL:** `GET /cmm/attachments/deleted`
* **Query Params:**
  * `domain_code`: 특정 도메인 필터 (예: FAC)
  * `resource_type`: 리소스 유형 (예: EQUIPMENT)
  * `ref_id`: 특정 레코드 ID (예: 10번 시설)
* **Logic:**
  * **컨텍스트 조회**: 특정 시설 상세 페이지에서 해당 시설과 관련된 삭제 이력만 골라볼 때 사용합니다.
  * **권한 필터**: 일반 사용자는 본인 또는 우리 부서가 삭제한 파일만 리스트에 나타납니다.

### 4.4 파일 복구 (Restore)

* **URL:** `POST /cmm/attachments/{attachment_id}/restore`
* **Permission:** 본인, 동일 부서원, 또는 관리자
* **Logic:** 소프트 삭제된 상태를 활성 상태로 되돌립니다.

---

## ⚙️ 5. 운영 가이드: 영구 파기 (Purge)

### 5.1 배치 스크립트 기반 자동 파기

* **스크립트:** `backend/app/scripts/purge_attachments.py`
* **기능:** 삭제 후 보관 기간(기본 30일)이 지난 데이터를 스토리지와 DB에서 영구 삭제합니다.
* **보안:** 외부 노출 없이 서버 로컬 터미널(`cron`)에서만 실행됩니다.

---

## ⚠️ 6. CMM 도메인 특화 에러 코드

| Code | Name | Description |
| --- | --- | --- |
| `4032` | `ACCESS_DENIED` | 본인 또는 부서 소유 파일이 아니어서 접근 거부 |
| `4099` | `SYSTEM_RESOURCE_MOD` | 시스템 필수 코드는 삭제 불가능 |
