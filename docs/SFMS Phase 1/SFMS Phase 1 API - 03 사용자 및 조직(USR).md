# 📘 SFMS Phase 1 API - 03 사용자 및 조직 관리 (USR) 상세 명세서

* **문서 버전:** v1.0 (Final)
* **작성일:** 2026-02-17
* **관련 스키마:** `usr.users`, `usr.organizations`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (Python/Pydantic)

파일 위치: `app/modules/usr/schemas.py`

```python
from pydantic import BaseModel, Field, EmailStr, ConfigDict, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
import uuid

# --------------------------------------------------------
# [Organization] 조직(부서) 관련 스키마
# --------------------------------------------------------
class OrgBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100, description="조직 명칭")
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$", description="조직 코드 (대문자)")
    parent_id: Optional[int] = Field(None, description="상위 조직 ID (Root는 None)")
    sort_order: int = Field(0, description="정렬 순서")
    description: Optional[str] = None
    is_active: bool = True

class OrgCreate(OrgBase):
    pass

class OrgUpdate(BaseModel):
    name: Optional[str] = None
    # code는 수정 불가 (식별자 변경 위험)
    parent_id: Optional[int] = None
    sort_order: Optional[int] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class OrgRead(OrgBase):
    id: int
    # Tree 구조 표현을 위한 확장 필드 (선택적)
    children: Optional[List['OrgRead']] = None 
    
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [User] 사용자 관련 스키마
# --------------------------------------------------------
class UserBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    emp_code: str = Field(..., min_length=1, max_length=20, description="사번")
    email: EmailStr = Field(..., description="이메일 (소문자 저장)")
    phone: Optional[str] = Field(None, pattern=r"^\d{2,3}-\d{3,4}-\d{4}$")
    org_id: Optional[int] = Field(None, description="소속 조직 ID")
    is_active: bool = True
    metadata: Dict[str, Any] = Field(default_factory=dict, description="추가 속성 (직급, 직책 등)")

    @field_validator('email')
    def to_lower_email(cls, v):
        return v.lower()

class UserCreate(UserBase):
    login_id: str = Field(..., min_length=4, max_length=50, pattern=r"^[a-z0-9_]+$")
    password: str = Field(..., min_length=8, description="초기 비밀번호")

    @field_validator('login_id')
    def to_lower_login_id(cls, v):
        return v.lower()

class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    org_id: Optional[int] = None
    is_active: Optional[bool] = None
    metadata: Optional[Dict[str, Any]] = None
    profile_image_id: Optional[uuid.UUID] = None

class UserPasswordUpdate(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=8)

class UserRead(UserBase):
    id: int
    login_id: str
    profile_image_id: Optional[uuid.UUID] = None
    last_login_at: Optional[datetime] = None
    
    # Join된 조직 정보 (Optional)
    organization_name: Optional[str] = None 
    
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

```

### 1.2 Frontend Interfaces (TypeScript)

파일 위치: `src/api/usr/types.ts`

```typescript
import { ApiResponse } from '@/api/types';

// [Organization]
export interface Organization {
  id: number;
  name: string;
  code: string;
  parent_id: number | null;
  sort_order: number;
  description?: string;
  is_active: boolean;
  children?: Organization[]; // Tree UI용 재귀 구조
  created_at: string;
  updated_at: string;
}

// [User]
export interface User {
  id: number;
  login_id: string;
  emp_code: string;
  name: string;
  email: string;
  phone?: string;
  org_id?: number;
  organization_name?: string; // UI 표시용 편의 필드
  profile_image_id?: string;  // UUID
  is_active: boolean;
  last_login_at?: string;
  metadata: Record<string, any>; // { "position": "대리", "duty": "팀원" }
  created_at: string;
}

// [User Form]
export interface CreateUserRequest {
  login_id: string;
  password: string;
  name: string;
  emp_code: string;
  email: string;
  org_id?: number;
  // ... 기타 필드
}

```

---

## 2. 🏢 조직 관리 API (Organizations)

조직도는 **트리 구조(Tree Structure)**로 관리되며, 계층적인 조회가 핵심입니다.

### 2.1 조직 목록 조회 (List / Tree)

* **URL:** `GET /api/v1/usr/organizations`
* **Query Params:**
* `mode`: `flat` (단순 리스트) or `tree` (계층형 JSON) - Default: `tree`
* `is_active`: `true` (활성 조직만) or `all`


* **Response:** `ApiResponse<List[OrgRead]>`
* **Logic:**
* `tree` 모드: 전체 데이터를 메모리에서 재귀적으로 조립하여 반환하거나, Postgres `WITH RECURSIVE` 쿼리 활용.
* 프론트엔드 `Tree` 컴포넌트(AntD 등)에 바인딩하기 적합한 구조로 반환.



### 2.2 조직 생성 (Create)

* **URL:** `POST /api/v1/usr/organizations`
* **Body:** `OrgCreate`
* **Logic:**
* `code` 중복 체크 (Unique).
* `parent_id`가 존재할 경우, 유효한 상위 부서인지 검증.



### 2.3 조직 상세 조회 (Read One)

* **URL:** `GET /api/v1/usr/organizations/{id}`
* **Response:** `ApiResponse<OrgRead>`

### 2.4 조직 수정 (Update)

* **URL:** `PATCH /api/v1/usr/organizations/{id}`
* **Body:** `OrgUpdate`
* **Logic:**
* `parent_id` 수정 시 **순환 참조(Circular Reference)** 방지 로직 필수. (나의 자식을 나의 부모로 설정할 수 없음)



### 2.5 조직 삭제 (Delete)

* **URL:** `DELETE /api/v1/usr/organizations/{id}`
* **Response:** `ApiResponse<null>`
* **Logic:**
* **제약 조건 Check:**
1. 하위 조직(`children`)이 존재하는 경우 삭제 불가 → `4091 (STATE_CONFLICT)`
2. 소속된 사용자(`usr.users`)가 존재하는 경우 삭제 불가 → `4091 (STATE_CONFLICT)`


* 위 조건 통과 시 Hard Delete 수행.



---

## 3. 👥 사용자 관리 API (Users)

### 3.1 사용자 목록 조회 (List)

* **URL:** `GET /api/v1/usr/users`
* **Query Params:**
* `page`, `size`, `sort`
* `org_id`: 특정 부서원 조회 (하위 부서 포함 여부는 옵션 `include_children=true`)
* `keyword`: 이름, 사번, 아이디 검색
* `is_active`: 재직자(`true`), 퇴사자(`false`)


* **Response:** `ApiResponse<List[UserRead]>`

### 3.2 사용자 생성 (Create)

* **URL:** `POST /api/v1/usr/users`
* **Body:** `UserCreate`
* **Logic:**
* **중복 체크:** `login_id`, `email`, `emp_code` 중복 시 각각 적절한 에러 메시지 반환 (`4090`).
* **비밀번호:** `passlib` 등을 사용하여 Hash 후 저장.
* **기본값:** `is_active=True`, `metadata={}`



### 3.3 사용자 상세 조회 (Read One)

* **URL:** `GET /api/v1/usr/users/{id}`
* **Response:** `ApiResponse<UserRead>`

### 3.4 사용자 정보 수정 (Update Info)

관리자 또는 본인이 정보를 수정합니다.

* **URL:** `PATCH /api/v1/usr/users/{id}`
* **Body:** `UserUpdate`
* **Logic:**
* `email` 변경 시 중복 체크.
* `org_id` 변경 시 부서 이동 처리 (Audit Log 기록 권장).



### 3.5 비밀번호 변경 (Change Password)

* **URL:** `PUT /api/v1/usr/users/{id}/password`
* **Body:** `UserPasswordUpdate`
* **Logic:**
* 본인 요청: `current_password` 일치 여부 확인.
* 관리자 요청(비밀번호 초기화): 별도 API(`POST .../reset-password`) 분리 또는 권한 체크 후 강제 변경 허용.



### 3.6 사용자 삭제/비활성화 (Delete)

* **URL:** `DELETE /api/v1/usr/users/{id}`
* **Logic:**
* 실제 데이터 삭제(Hard Delete)보다는 `is_active=False` 처리(Soft Delete)를 권장.
* 퇴사 처리를 위해 `metadata`에 `retired_at` 날짜 기록 가능.



---

## 4. 🖼️ 프로필 이미지 처리

사용자 프로필 이미지는 `cmm.attachments`와 연동됩니다.

### 4.1 프로필 이미지 업로드

* **URL:** `POST /api/v1/usr/users/{id}/profile-image`
* **Content-Type:** `multipart/form-data`
* **Logic:**
1. 파일 업로드 (`cmm` 모듈 활용).
2. `cmm.attachments`에 레코드 생성 (Category: `PROFILE`).
3. `usr.users.profile_image_id` 컬럼 업데이트.
4. 기존 이미지가 있다면 삭제(또는 보관) 처리.



---

## 5. ⚠️ USR 도메인 에러 코드 (Error Codes)

공통 규격에 더해 USR 도메인 특화 에러를 정의합니다.

| HTTP | Code | Name | Description |
| --- | --- | --- | --- |
| 409 | `4090` | `DUPLICATE_LOGIN_ID` | 이미 사용 중인 로그인 ID입니다. |
| 409 | `4093` | `DUPLICATE_EMAIL` | 이미 등록된 이메일 주소입니다. |
| 409 | `4094` | `DUPLICATE_EMP_CODE` | 이미 등록된 사원 번호입니다. |
| 409 | `4091` | `ORG_HAS_CHILDREN` | 하위 부서가 존재하여 삭제할 수 없습니다. |
| 409 | `4095` | `ORG_HAS_USERS` | 부서원이 존재하여 부서를 삭제할 수 없습니다. |
| 400 | `4003` | `INVALID_PARENT_ORG` | 상위 부서 ID가 자기 자신이거나 유효하지 않습니다. |

---

## 6. ✅ 구현 체크리스트 (Checklist)

* [ ] **Recursive Query**: 조직도 Tree 조회를 위한 SQLAlchemy CTE(Common Table Expression) 또는 재귀 로직 구현.
* [ ] **Circular Check**: 조직 이동(상위 부서 변경) 시 순환 참조 방지 알고리즘 적용.
* [ ] **Unique Constraint Handling**: DB의 Unique Index 위반 에러(`psycopg2.errors.UniqueViolation`)를 Catch하여 사용자 친화적 에러 코드(`409x`)로 변환.
* [ ] **Password Security**: 비밀번호 저장 시 반드시 Salt를 포함한 Hash(bcrypt/argon2) 적용.
* [ ] **Profile Image**: 프론트엔드에서 이미지 URL을 조회할 때 Presigned URL 또는 Proxy URL 생성 로직 확인.