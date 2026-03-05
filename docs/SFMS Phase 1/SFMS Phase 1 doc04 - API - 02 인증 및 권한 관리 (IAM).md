# 📘 SFMS Phase 1 API - 02 인증 및 권한 관리 (IAM & Auth) 상세 명세서 (Revised v1.3)

* **문서 버전:** v1.3 (Production Ready)
* **작성일:** 2026-02-17
* **관련 스키마:** `iam.roles`, `iam.user_roles`, `usr.users`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

**보완점:** `Enum`을 도입하여 권한 코드의 오타를 방지하고, Pydantic v2의 `ConfigDict`를 적용했습니다.

### 1.1 Backend Models (Python/Pydantic)

파일 위치: `app/modules/iam/schemas.py`

```python
from pydantic import BaseModel, Field, ConfigDict, EmailStr, field_validator
from typing import List, Dict, Optional
from datetime import datetime
from enum import Enum

# [Enum] 토큰 타입
class TokenType(str, Enum):
    BEARER = "bearer"

# --------------------------------------------------------
# [Auth] 인증 관련 스키마
# --------------------------------------------------------
class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: TokenType = TokenType.BEARER
    expires_in: int     # Access Token 만료 시간 (초)

class LoginRequest(BaseModel):
    login_id: str = Field(..., min_length=4, description="사용자 ID (소문자 자동 변환)")
    password: str = Field(..., min_length=6, description="비밀번호")

    @field_validator('login_id')
    def to_lower(cls, v):
        return v.lower()

class CurrentUser(BaseModel):
    id: int
    login_id: str
    name: str
    email: EmailStr
    org_id: Optional[int]
    org_name: Optional[str] = None # UI 표시용 (Join)
    roles: List[str]      # Role Code List (e.g., ["ADMIN"])
    permissions: Dict[str, List[str]] # Merged Permissions
    
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [IAM] 역할(Role) 관련 스키마
# --------------------------------------------------------
class RoleBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$", description="역할 코드 (대문자)")
    description: Optional[str] = None
    permissions: Dict[str, List[str]] = Field(default_factory=dict)
    is_system: bool = False

class RoleCreate(RoleBase):
    pass

class RoleUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    permissions: Optional[Dict[str, List[str]]] = None
    # code, is_system 수정 불가

class RoleRead(RoleBase):
    id: int
    created_at: datetime
    updated_at: datetime
    created_by: Optional[int]
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [Assignment] 권한 부여
# --------------------------------------------------------
class UserRoleUpdate(BaseModel):
    user_id: int
    role_ids: List[int] = Field(..., description="부여할 역할 ID 목록 (Full Replace)")

```

### 1.2 Frontend Interfaces (TypeScript)

파일 위치: `src/api/iam/types.ts`

```typescript
import { ApiResponse } from '@/api/types';

// [Auth]
export interface AuthToken {
  access_token: string;
  refresh_token: string;
  token_type: 'bearer';
  expires_in: number;
}

export interface UserProfile {
  id: number;
  login_id: string;
  name: string;
  email: string;
  org_id?: number;
  org_name?: string;
  roles: string[];
  permissions: Record<string, string[]>;
}

// [IAM] Role
export interface Role {
  id: number;
  name: string;
  code: string;
  description?: string;
  permissions: Record<string, string[]>; // { "FAC": ["READ", "WRITE"] }
  is_system: boolean;
  created_at: string;
  updated_at: string;
}

```

---

## 2. 🔐 인증 API (Authentication)

### 2.1 로그인 (Login)

**보완:** 계정 잠금(Account Lockout) 로직이 추가되었습니다.

* **URL:** `POST /api/v1/auth/login`
* **Request Body:** `LoginRequest`
* **Response:** `ApiResponse<Token>`
* **Logic:**
  1. `login_id`로 사용자 조회.
  2. **Rate Limiting:** IP당 분당 5회 시도 제한 (Redis).
     * 실패 시: "아이디 또는 비번이 틀립니다" (보안상 ID 존재 여부 노출 금지).

  3. **잠금 확인:** `login_fail_count >= 5` 이면 `4031 (ACCOUNT_LOCKED)` 반환.
  4. **비밀번호 검증:** BCrypt 해시 대조.
     * 실패 시: `login_fail_count + 1`.

  5. **성공 시:** `login_fail_count = 0`, `last_login_at = Now` 업데이트.
  6. **Audit Log:** `action_type: LOGIN` 기록.

### 2.2 토큰 갱신 (Refresh Token)

**보완:** Refresh Token Rotation(RTR) 정책을 적용하여 보안을 강화합니다.

* **URL:** `POST /api/v1/auth/refresh`
* **Request Body:** `{ "refresh_token": "..." }`
* **Logic:**
1. Refresh Token 검증 (만료, 서명).
2. Redis Blacklist 확인 (이미 사용된 토큰인지).
3. **Rotation:** 기존 Refresh Token을 무효화(Blacklist 등록)하고, **새로운 Access Token과 새로운 Refresh Token**을 발급하여 반환.

### 2.3 내 정보 조회 (Get Me)

* **URL:** `GET /api/v1/auth/me`
* **Header:** `Authorization: Bearer {token}`
* **Response:** `ApiResponse<CurrentUser>`
* **Logic:**
* `org_id`를 이용해 `usr.organizations` 테이블을 조인, `org_name`을 함께 반환하여 프론트엔드에서 추가 호출을 줄임.

### 2.4 로그아웃 (Logout)

* **URL:** `POST /api/v1/auth/logout`
* **Logic:**
* 남은 유효 시간(`exp`)만큼 Access Token을 Redis Blacklist에 등록.

---

## 3. 🛡️ 권한 관리 API (IAM Roles)

### 3.1 역할 목록 조회

* **URL:** `GET /api/v1/iam/roles`
* **Query:** `keyword` (이름/코드), `page`, `size`
* **Response:** `ApiResponse<List[RoleRead]>`

### 3.2 역할 상세 조회

* **URL:** `GET /api/v1/iam/roles/{id}`

### 3.3 역할 생성

* **URL:** `POST /api/v1/iam/roles`
* **Body:** `RoleCreate`
* **Logic:**
* `code`는 대문자로 강제 변환 및 중복 체크 (`4090`).
* `permissions` JSON 스키마 검증 (임의의 키값 방지).

### 3.4 역할 수정

* **URL:** `PATCH /api/v1/iam/roles/{id}`
* **Body:** `RoleUpdate`
* **Constraint:** 시스템 기본 역할(`is_system=true`)은 `name`과 `permissions`만 수정 가능하며, 핵심 권한 삭제는 백엔드에서 방어 로직 필요.

### 3.5 역할 삭제

* **URL:** `DELETE /api/v1/iam/roles/{id}`
* **Logic:**
* **시스템 역할 삭제 불가** (`4092`).
* **사용 중인 역할 삭제 불가:** `iam.user_roles` 참조 확인 (`4091`).

---

## 4. 👥 사용자 권한 할당 API (Role Assignment)

### 4.1 사용자에게 역할 부여

* **URL:** `PUT /api/v1/iam/users/{user_id}/roles`
* **Body:** `UserRoleUpdate` (`{ "role_ids": [1, 2] }`)
* **Logic:**
* 기존 권한을 모두 삭제(`DELETE`)하고 새로 입력(`INSERT`)하는 **Full Replace** 방식.
* **Audit Log:** `action_type: GRANT_ROLE`, `target_id: user_id` 기록.
* **Cache Invalidation:** 대상 사용자가 로그인 중일 경우, 권한 변경 사항이 즉시 반영되지 않으므로, 중요한 변경인 경우 대상 사용자의 Refresh Token을 강제 만료시키는 로직 고려 가능.

---

## 5. 🧩 권한 리소스 목록 API (Permissions Resource)

프론트엔드 UI(권한 설정 트리) 구성을 위한 메타데이터입니다.

* **URL:** `GET /api/v1/iam/permissions/resources`
* **Response:**

```json
{
  "success": true,
  "data": {
    "USR": { "label": "사용자 관리", "actions": ["READ", "CREATE", "UPDATE", "DELETE"] },
    "FAC": { "label": "시설 관리", "actions": ["READ", "UPDATE_STATUS", "CONTROL"] }
  }
}

```

* **Note:** 하드코딩된 리스트보다는 `cmm.system_domains` 테이블과 연동하거나 별도 설정 파일(`permissions.yaml`) 기반으로 제공하는 것이 유지보수에 유리합니다.

---

## 6. ⚠️ 에러 코드 정의 (Error Codes)

보안 관련 에러 코드를 세분화했습니다.

| HTTP | Code | Name | Description |
| --- | --- | --- | --- |
| 400 | `4002` | `PASSWORD_WEAK` | 비밀번호가 복잡도 정책(8자 이상, 특수문자 등)을 위반함 |
| 401 | `4010` | `AUTH_FAILED` | 아이디 또는 비밀번호가 일치하지 않음 |
| 401 | `4011` | `TOKEN_EXPIRED` | Access Token 만료 |
| 401 | `4012` | `TOKEN_INVALID` | 유효하지 않은 토큰 (서명 위조 등) |
| 403 | `4030` | `FORBIDDEN` | 해당 리소스에 대한 접근 권한(Permission) 없음 |
| 403 | `4031` | `ACCOUNT_LOCKED` | 비밀번호 5회 오류로 계정 잠금됨 (관리자 문의) |
| 409 | `4090` | `DUPLICATE_CODE` | 이미 존재하는 역할 코드 |
| 409 | `4091` | `ROLE_IN_USE` | 사용자를 보유한 역할은 삭제할 수 없음 |
| 409 | `4092` | `SYSTEM_ROLE_MOD` | 시스템 기본 역할은 삭제할 수 없음 |
| 429 | `4290` | `TOO_MANY_REQUESTS` | 로그인 시도 횟수 초과 (IP 차단) |

---

## 7. ✅ 구현 체크리스트 (Final Checklist)

* [ ] **Rate Limiting**: `slowapi` 또는 `fastapi-limiter`를 사용하여 로그인 엔드포인트 보호.
* [ ] **Secure Password**: 비밀번호 저장 시 `passlib.context.CryptContext(schemes=["bcrypt"])` 사용 확인.
* [ ] **Audit Sensitive Data**: 감사 로그 기록 시 `snapshot` 데이터에 **비밀번호 필드가 포함되지 않도록** 필터링 로직 구현 필수.
* [ ] **Admin Init**: `app/db/init_db.py` 스크립트 작성 - 서버 최초 실행 시 `SUPER_ADMIN` 역할과 초기 관리자 계정 자동 생성 확인.
* [ ] **JWT Claim**: Access Token Payload에 `sub` (user_id), `iat`, `exp`, `type` 외에 불필요한 개인정보(이메일 등)는 최소화.
