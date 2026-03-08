# 📘 SFMS Phase 1 API - 02 시스템 관리 (SYS) 상세 명세서

* **문서 버전:** v1.6 (Latest Implementation Sync)
* **최종 수정일:** 2026-03-07
* **도메인:** `SYS` (System & Admin)
* **핵심 역할:** 감사 로그 추적, 채번(Sequence) 관리 규칙 설정 및 발급
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (SQLAlchemy & Pydantic)

#### [Database Models]

**파일 위치:** `backend/app/domains/sys/models.py`

```python
class AuditLog(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    actor_user_id: Mapped[Optional[int]] = mapped_column(BigInteger, index=True)
    action_type: Mapped[str] = mapped_column(String(20))
    target_domain: Mapped[str] = mapped_column(String(3))
    target_table: Mapped[str] = mapped_column(String(50))
    target_id: Mapped[str] = mapped_column(String(50))
    snapshot: Mapped[Dict[str, Any]] = mapped_column(JSONB)
    client_ip: Mapped[Optional[str]] = mapped_column(String(50))
    user_agent: Mapped[Optional[str]] = mapped_column(Text)
    description: Mapped[Optional[str]] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

class SequenceRule(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    domain_code: Mapped[str] = mapped_column(String(3))
    prefix: Mapped[str] = mapped_column(String(10))
    year_format: Mapped[str] = mapped_column(String(4), default="YYYY")
    separator: Mapped[str] = mapped_column(String(1), default="-")
    padding_length: Mapped[int] = mapped_column(Integer, default=4)
    current_year: Mapped[str] = mapped_column(String(4))
    current_seq: Mapped[int] = mapped_column(BigInteger, default=0)
    reset_type: Mapped[str] = mapped_column(String(10), default="YEARLY")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
```

#### [Pydantic Schemas]

**파일 위치:** `backend/app/domains/sys/schemas.py`

```python
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [AuditLog] 시스템 감사 로그 스키마
# --------------------------------------------------------
class AuditLogBase(BaseModel):
    actor_user_id: Optional[int] = Field(None, description="행위를 수행한 사용자 ID")
    action_type: str = Field(..., max_length=20, description="행위 유형 (CREATE, UPDATE 등)")
    target_domain: str = Field(..., max_length=3, description="대상 업무 도메인 코드")
    target_table: str = Field(..., max_length=50, description="대상 데이터 테이블명")
    target_id: str = Field(..., max_length=50, description="대상 데이터의 식별자(PK)")
    snapshot: Dict[str, Any] = Field(default_factory=dict, description="변경 데이터의 스냅샷")
    client_ip: Optional[str] = Field(None, max_length=50, description="클라이언트 IP 주소")
    user_agent: Optional[str] = Field(None, description="User-Agent 정보")
    description: Optional[str] = Field(None, description="상세 텍스트 설명")

class AuditLogRead(AuditLogBase):
    id: int = Field(..., description="로그 고유 ID")
    created_at: datetime = Field(..., description="로그 발생 일시")
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [SequenceRule] 채번 규칙 스키마
# --------------------------------------------------------
class SequenceRuleBase(BaseModel):
    domain_code: str = Field(..., min_length=3, max_length=3, description="도메인 코드")
    prefix: str = Field(..., max_length=10, description="문서 번호 접두어")
    year_format: str = Field("YYYY", max_length=4, description="연도 표시 형식")
    separator: str = Field("-", max_length=1, description="구분자")
    padding_length: int = Field(4, ge=1, le=10, description="일련번호 자릿수")
    reset_type: str = Field("YEARLY", max_length=10, description="번호 초기화 방식")
    is_active: bool = Field(True, description="규칙 활성화 여부")

class SequenceRuleRead(SequenceRuleBase):
    id: int = Field(..., description="규칙 고유 ID")
    current_year: str = Field(..., description="현재 진행 중인 연도")
    current_seq: int = Field(..., description="마지막 발급된 번호")
    created_at: datetime = Field(..., description="등록 일시")
    updated_at: datetime = Field(..., description="최종 수정 일시")
    model_config = ConfigDict(from_attributes=True)
```

---

## 2. 🔐 보안 및 권한 정책 (Security & Permissions)

시스템 설정 및 로그 조회는 관리자 전용으로 제한하며, 실제 업무 처리에 필요한 번호 발급 기능만 일반 사용자에게 개방합니다.

### 2.1 사용자별 권한 매트릭스

| 대분류 | 기능 | 일반 사용자 | 관리자(Admin) | 비고 |
| :--- | :--- | :---: | :---: | :--- |
| **채번 관리** | 채번 규칙 목록 조회 | ❌ | ✅ | 관리자 전용 |
| | 채번 규칙 생성/수정/삭제 | ❌ | ✅ | 관리자 전용 |
| | **다음 시퀀스 번호 발급** | ✅ | ✅ | 모든 인증된 사용자 |
| **감사 로그** | 감사 로그 목록 조회 | ❌ | ✅ | 보안 관리자 전용 |

---

## 3. 🔢 채번 관리 API (Sequences)

### 3.1 채번 규칙 목록 조회 (List)

* **URL:** `GET /sys/sequences`
* **Permission:** **관리자 전용**
* **Response:** `APIResponse[List[SequenceRuleRead]]`

### 3.2 채번 규칙 생성 (Create)

* **URL:** `POST /sys/sequences`
* **Permission:** **관리자 전용**
* **Request Body (SequenceRuleCreate):**
    * `domain_code` (str, 필수): 적용할 도메인 코드 (주의: `sys.system_domains`에 기등록된 코드만 가능)
    * `prefix` (str, 필수): 문서 번호 접두어
    * `current_year` (str, 필수): 채번을 시작할 기준 연도 (예: "2026")
    * `current_seq` (int, 선택): 시작 일련번호 (기본값: 0)
    * 기타 속성 (`separator`, `padding_length` 등)은 기본값 사용 가능
* **Logic:** 도메인 코드, 접두어, 연도 포맷, 초기화 방식 등을 설정합니다.

### 3.3 채번 규칙 수정 (Update)

* **URL:** `PATCH /sys/sequences/{rule_id}`
* **Permission:** **관리자 전용**
* **Logic:** 기존 규칙의 속성을 수정합니다. 수정 후 발급되는 번호부터 변경된 규칙이 적용됩니다.

### 3.4 채번 규칙 삭제 (Delete)

* **URL:** `DELETE /sys/sequences/{rule_id}`
* **Permission:** **관리자 전용**

### 3.5 다음 채번 번호 발급 (Get Next)

* **URL:** `GET /sys/sequence/{domain_code}/{prefix}/next`
* **Permission:** 모든 인증된 사용자
* **Logic:**
    1. 해당 도메인/접두어 규칙을 조회(비관적 락 적용).
    2. 연도별 리셋(`YEARLY`) 여부 확인 후 순번 증가.
    3. 규칙에 따른 포맷팅 문자열 반환.
* **발급 결과 예시:**
    * 기본 설정 (`-`, 4자리): `WO-2026-0001`
    * 커스텀 설정 (`_`, 6자리): `REQ_2026_000001`

---

## 📜 4. 시스템 감사 로그 API (Audit Logs)

### 4.1 감사 로그 목록 조회 (Read - List)

* **URL:** `GET /sys/audit-logs`
* **Permission:** **관리자 전용**
* **Query Params:** `skip`, `limit`, `target_domain`, `action_type`
* **Logic:** 시스템 전반에서 발생한 데이터 변경 및 주요 행위 이력을 조회합니다. `pgroonga` 인덱스를 통해 고속 조회를 지원합니다.
* **참고:** 필터 조건에 맞는 로그가 없을 경우 **빈 리스트(`[]`)와 200 OK**를 반환합니다.

---

## ⚠️ 5. SYS 도메인 특화 에러 코드

| Code | Name | Description |
| --- | --- | --- |
| `4040` | `NOT_FOUND` | 요청한 규칙이 존재하지 않음 |
| `4032` | `ACCESS_DENIED` | 관리자 권한이 없는 사용자의 접근 |
| `4090` | `DUPLICATE_CODE` | 이미 존재하는 도메인/접두어 조합의 규칙 생성 시도 |

---

## ✅ 6. 구현 체크리스트

* [x] **Concurrency Control**: 채번 발급 시 비관적 락(`with_for_update`)을 사용하여 번호 중복을 방지하는가?
* [x] **Audit Field**: 규칙 생성/수정 시 `created_by`, `updated_by`가 정확히 기록되는가?
* [x] **Docstrings**: 모든 클래스와 메서드에 상세한 Python Docstring이 포함되었는가?
* [x] **Hardcoded Domains**: `SystemDomain` 관련 API가 제거되고 코드 내 상수로 관리되는가?
