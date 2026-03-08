# 📘 SFMS Phase 1 API - 03 인증 및 권한 관리 (IAM) 상세 명세서

* **문서 버전:** v1.4 (Implementation Sync)
* **최종 수정일:** 2026-03-07
* **관련 스키마:** `iam.roles`, `iam.user_roles`, `usr.users`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (SQLAlchemy & Pydantic)

#### [Database Models]

**파일 위치:** `backend/app/domains/iam/models.py`

```python
class Role(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    description: Mapped[Optional[str]] = mapped_column(Text)
    permissions: Mapped[Dict[str, Any]] = mapped_column(JSONB)
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)

class UserRole(Base):
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("usr.users.id"), primary_key=True)
    role_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("iam.roles.id"), primary_key=True)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    assigned_by: Mapped[Optional[int]] = mapped_column(BigInteger)
```

#### [Pydantic Schemas]

**파일 위치:** `backend/app/domains/iam/schemas.py`

```python
from datetime import datetime
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [Auth] 인증 관련 스키마
# --------------------------------------------------------
class LoginRequest(BaseModel):
    login_id: str = Field(..., description="사용자 로그인 ID")
    password: str = Field(..., description="비밀번호")

class Token(BaseModel):
    access_token: str = Field(..., description="액세스 토큰 (JWT)")
    refresh_token: str = Field(..., description="리프레시 토큰 (JWT)")
    expires_in: int = Field(..., description="만료 시간 (초)")
    token_type: str = "bearer"

# --------------------------------------------------------
# [Role] 역할 관리 관련 스키마
# --------------------------------------------------------
class RoleBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="역할 명칭")
    code: str = Field(..., min_length=2, max_length=50, description="역할 식별 코드")
    description: Optional[str] = Field(None, description="역할 상세 설명")
    permissions: Dict[str, Any] = Field(default_factory=dict, description="권한 매트릭스")
    is_system: bool = Field(False, description="시스템 필수 역할 여부")

class RoleRead(RoleBase):
    id: int = Field(..., description="고유 ID")
    created_at: datetime = Field(..., description="생성 일시")
    updated_at: datetime = Field(..., description="수정 일시")
    created_by: Optional[int] = Field(None, description="생성자 ID")
    updated_by: Optional[int] = Field(None, description="수정자 ID")
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [UserRole] 사용자 역할 할당 관련 스키마
# --------------------------------------------------------
class UserRoleUpdate(BaseModel):
    user_id: int = Field(..., description="대상 사용자 ID")
    role_ids: List[int] = Field(..., description="할당할 역할 ID 목록")
```

---

## 2. 🔐 보안 및 권한 정책 (Security & Permissions)

인증(Auth) 관련 API는 로그인 여부에 따라 접근이 제한되며, 역할(Role) 및 권한 할당 관리 API는 오직 관리자 계정만 접근 가능합니다.

### 2.1 사용자별 권한 매트릭스

| 대분류 | 기능 | 미인증 | 일반 사용자 | 관리자(Admin) | 상세 보안 로직 |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **인증** | 로그인 | ✅ | ✅ | ✅ | Rate Limiting 적용 (분당 10회) |
| | 토큰 갱신 (Refresh) | ✅ | ✅ | ✅ | RTR(Rotation) 정책 적용 |
| | 로그아웃 / 내 정보 조회 | ❌ | ✅ | ✅ | JWT Blacklist 처리 |
| **역할 관리** | 역할 목록/상세 조회 | ❌ | ✅ | ✅ | |
| | 역할 추가/편집/삭제 | ❌ | ❌ | ✅ | 관리자 전용 (`Superuser`) |
| **권한 할당** | 사용자 역할 부여 | ❌ | ❌ | ✅ | Full Replace 방식 |

---

## 🔑 3. 인증 API (Authentication)

### 3.1 로그인 (Login)

* **URL:** `POST /auth/login`
* **Permission:** 누구나
* **Logic:**
    1. 비밀번호 5회 실패 시 계정 잠금 (`4031 ACCOUNT_LOCKED`).
    2. 비활성 계정 체크 (`4033 ACCOUNT_DISABLED`).
    3. 성공 시 감사 로그 기록 및 Access/Refresh 토큰 발급.

### 3.2 토큰 갱신 (Refresh Token)

* **URL:** `POST /auth/refresh`
* **Security:** **Refresh Token Rotation (RTR)**
* **Request Body:** `{"refresh_token": "eyJhbG..."}` (JSON)
* **Logic:** 사용된 리프레시 토큰은 블랙리스트에 등록되어 재사용이 금지되며, 새로운 리프레시 토큰이 함께 발급됩니다.

### 3.3 내 정보 조회 (Get Me)

* **URL:** `GET /auth/me`
* **Response:** `APIResponse[UserRead]` (현재 로그인한 사용자의 프로필 및 소속 정보)

---

## 🛡️ 4. 역할 관리 API (Roles)

### 4.1 역할 목록 조회

* **URL:** `GET /roles`
* **Query Params:** `keyword` (이름/코드), `page`, `size`

### 4.2 역할 생성/수정

* **URL:** `POST /roles`, `PATCH /roles/{role_id}`
* **Permission:** **관리자 전용**
* **Logic:**
  * `is_system=True`인 필수 역할은 코드 수정 및 삭제가 불가합니다.
  * `permissions` 필드에 리소스별 액션 매트릭스(JSON)를 저장합니다.

### 4.3 역할 삭제

* **URL:** `DELETE /roles/{role_id}`
* **Permission:** **관리자 전용**
* **Constraint:** 해당 역할을 보유한 사용자가 한 명이라도 있으면 삭제가 거부됩니다 (`4091 RESOURCE_IN_USE`).

---

## 👥 5. 권한 할당 API (Role Assignment)

### 5.1 사용자 역할 부여

* **URL:** `PUT /roles/users/{user_id}/roles`
* **Permission:** **관리자 전용**
* **Logic:**
    1. **Full Replace 방식**: 대상 사용자의 기존 역할을 **모두 제거**한 후, 전달받은 `role_ids` 목록을 신규 할당합니다.
    2. 전달받은 `role_ids` 목록을 신규 할당합니다 (`assigned_by` 기록).
    3. 감사 로그(`GRANT_ROLE`)를 생성하고 권한 캐시(Redis)를 초기화합니다.
    4. **주의**: 일부 역할만 추가하고자 할 때도 전체 역할 목록을 전송해야 합니다.

---

## 🧩 6. 권한 리소스 메타데이터

### 6.1 프론트엔드용 리소스 맵 조회

* **URL:** `GET /roles/permissions/resources`
* **Response Example:**
    ```json
    {
      "domain": "IAM",
      "data": {
        "USR": { "label": "사용자 관리", "actions": ["READ", "WRITE", "DELETE"] },
        "FAC": { "label": "시설 관리", "actions": ["READ", "WRITE", "EXECUTE"] },
        "SYS": { "label": "시스템 설정", "actions": ["READ", "WRITE"] }
      }
    }
    ```
* **Usage:** 관리자 페이지의 권한 설정 UI 구성을 위해 사용됩니다.

---

## ⚠️ 7. IAM 도메인 특화 에러 코드

| Code | Name | Description |
| --- | --- | --- |
| `4010` | `AUTH_FAILED` | 아이디 또는 비밀번호가 일치하지 않습니다. |
| `4011` | `TOKEN_BLACKLISTED` | 이미 로그아웃되거나 사용된 토큰입니다. |
| `4031` | `ACCOUNT_LOCKED` | 비밀번호 오류 횟수 초과로 계정이 잠겼습니다. |
| `4033` | `ACCOUNT_DISABLED` | 비활성화(퇴사 등)된 계정입니다. |
| `4090` | `DUPLICATE_CODE` | 이미 사용 중인 역할 코드입니다. |
| `4099` | `SYSTEM_RESOURCE_MOD` | 시스템 필수 역할은 수정/삭제할 수 없습니다. |
| `4290` | `TOO_MANY_REQUESTS` | 단시간 내 너무 많은 로그인 시도가 발생했습니다. |
