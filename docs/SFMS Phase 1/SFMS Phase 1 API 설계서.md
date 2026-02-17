네, 개발자가 바로 코드로 옮길 수 있을 수준의 **구체적인 API 명세서(v2.0)**를 작성해 드립니다.

프론트엔드(React+Vite)와 백엔드(FastAPI) 개발자가 서로 질문할 필요 없이 이 문서만 보고 개발할 수 있도록 **요청 파라미터(필수/선택), 바디 구조, 응답 필드, 예외 처리**를 완벽하게 정리했습니다.

---

# 📘 SFMS API 상세 명세서 (Developer Ready v2.0)

* **Base URL:** `/api/v1`
* **Content-Type:** `application/json`
* **Auth:** Header `Authorization: Bearer {token}`

---

## 1. 📡 공통 규격 (Standard)

### 1.1 응답 래퍼 (Envelope Pattern)

모든 API는 아래 포맷으로 반환됩니다. Frontend는 `data` 필드만 바라봅니다.

```typescript
// TypeScript Interface
interface ApiResponse<T> {
  success: boolean;       // 성공 여부
  code: number;           // 200(성공), 4xxx(클라이언트 오류), 5xxx(서버 오류)
  message: string;        // 사용자 노출용 메시지
  data: T | null;         // 실제 데이터 payload
  meta?: {                // 목록 조회 시 페이지네이션 정보
    total: number;
    page: number;
    size: number;
    total_pages: number;
  };
}

```

### 1.2 공통 에러 코드

* `4000`: Bad Request (파라미터 누락/타입 오류)
* `4010`: Unauthorized (토큰 만료/없음)
* `4030`: Forbidden (권한 부족 - IAM Role 체크)
* `4040`: Not Found (데이터 없음)
* `4090`: Conflict (중복 데이터 - Unique Key 위배)
* `4091`: State Conflict (삭제 불가 - 하위 데이터 존재)

---

## 2. 🔐 IAM & Auth (인증 및 권한 관리)

**Schema:** `iam.roles`, `iam.user_roles`

### 2.1 로그인 (Login)

* **URL:** `POST /auth/login`
* **Request Body:**
* `login_id` (str, required): 아이디
* `password` (str, required): 비밀번호


* **Response `data`:**
```json
{
  "access_token": "eyJhbG...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "d8f92..."
}

```



### 2.2 역할(Role) 목록 조회

* **URL:** `GET /iam/roles`
* **Description:** 역할 관리 화면의 그리드 데이터.
* **Response `data` (Array):**
```json
[
  {
    "id": 1,
    "name": "슈퍼 관리자",
    "code": "SUPER_ADMIN",
    "description": "모든 권한 보유",
    "is_system": true,  // true면 삭제/수정 불가 버튼 비활성화
    "updated_at": "2026-02-17T10:00:00"
  }
]

```



### 2.3 역할 상세 조회 (권한 매트릭스 포함)

* **URL:** `GET /iam/roles/{id}`
* **Description:** 역할 수정 모달에 뿌려줄 데이터. 권한 JSON 포함.
* **Response `data`:**
```json
{
  "id": 2,
  "name": "일반 사용자",
  "code": "USER",
  "permissions": {  // Frontend 체크박스 매핑용
    "fac_mgmt": ["read"], 
    "user_mgmt": [],
    "report": ["read", "export"]
  }
}

```



### 2.4 역할 생성

* **URL:** `POST /iam/roles`
* **Request Body:**
* `name` (str, required): 역할명 (예: 시설 팀장)
* `code` (str, required): 영문 대문자 (예: `FAC_LEADER`)
* `description` (str, optional)
* `permissions` (json, required): `{"menu_code": ["action1", "action2"]}`


* **Error:** `4090` (이미 존재하는 코드)

### 2.5 역할 수정 (권한 변경)

* **URL:** `PUT /iam/roles/{id}`
* **Request Body:**
* `name` (str, optional)
* `description` (str, optional)
* `permissions` (json, required): 전체 덮어쓰기 방식으로 처리


* **Validation:** `is_system`이 true인 역할은 `code` 수정 불가.

### 2.6 역할 삭제

* **URL:** `DELETE /iam/roles/{id}`
* **Validation:**
1. `is_system`이 true면 `4030` 에러.
2. 해당 역할을 사용 중인 사용자(`iam.user_roles`)가 있으면 `4091` 에러.



---

## 3. 👥 USR (사용자 및 조직)

**Schema:** `usr.users`, `usr.organizations`

### 3.1 조직도 트리 조회 (Tree)

* **URL:** `GET /usr/orgs/tree`
* **Description:** 조직도 사이드바용 계층형 데이터.
* **Response `data`:**
```json
[
  {
    "key": 1,          // AntD Tree 호환용 key (id)
    "title": "본사",    // AntD Tree 호환용 title (name)
    "code": "HQ",
    "children": [
      { "key": 10, "title": "시설팀", "parent_id": 1, "children": [] }
    ]
  }
]

```



### 3.2 조직 생성/수정/삭제

* **POST** `/usr/orgs`: `{ name, code, parent_id, sort_order }`
* **PUT** `/usr/orgs/{id}`: `{ name, sort_order, parent_id }`
* *주의:* `parent_id` 변경 시 순환 참조(자신이 자신의 부모가 됨) 백엔드 검증 필수.


* **DELETE** `/usr/orgs/{id}`: 하위 조직이나 소속 사용자가 있으면 `4091` 에러.

### 3.3 사용자 목록 조회 (Grid)

* **URL:** `GET /usr/users`
* **Query Params:**
* `page`: (int, default=1)
* `size`: (int, default=20)
* `org_id`: (int, optional) 선택된 부서 ID
* `keyword`: (str, optional) 이름/사번/ID 검색 (PGroonga)
* `include_inactive`: (bool, default=false) 퇴사자 포함 여부


* **Response `data` (List):**
* `id`, `login_id`, `name`, `emp_code`, `org_name`, `email`, `is_active`



### 3.4 사용자 생성 (신규 입사)

* **URL:** `POST /usr/users`
* **Request Body:**
* `login_id` (str, required, min=4)
* `password` (str, required, min=8)
* `emp_code` (str, required): 사번
* `name` (str, required)
* `email` (str, required, email_format)
* `org_id` (int, required)
* `role_ids` (List[int], required): 부여할 역할 ID 목록 (예: `[2, 5]`)


* **Error:** `4090` (ID/사번/이메일 중복)

### 3.5 사용자 정보 수정

* **URL:** `PUT /usr/users/{id}`
* **Request Body:**
* `name`, `email`, `phone`, `org_id`
* `role_ids`: (Optional) 역할 변경 시 전송
* `is_active`: (bool) 퇴사 처리 시 false 전송



---

## 4. 🏗️ FAC (시설 및 공간 관리)

**Schema:** `fac.facilities`, `fac.spaces`

### 4.1 기초 코드 관리 (카테고리/타입)

프론트엔드 콤보박스나 설정 페이지에서 사용됩니다.

* **GET** `/fac/categories`: 시설 유형 (하수처리장, 펌프장 등)
* **GET** `/fac/space-types`: 공간 유형 (건물, 층, 호실)
* **GET** `/fac/space-functions`: 공간 용도 (전기실, 제어실)
* *CRUD:* `POST`, `PUT`, `DELETE` 모두 `code`(대문자), `name` 필드 사용.



### 4.2 시설물(Site) 목록 조회

* **URL:** `GET /fac/facilities`
* **Query Params:**
* `category_id`: (int)
* `keyword`: (str) 시설명 검색


* **Response `data`:** List of Facilities (이미지 URL 포함)

### 4.3 시설물 생성

* **URL:** `POST /fac/facilities`
* **Request Body:**
* `category_id` (int, required)
* `code` (str, required): Unique Code (예: `WTP_01`)
* `name` (str, required)
* `address` (str, optional)
* `representative_image_id` (uuid, optional): 파일 업로드 후 받은 ID
* `metadata` (json, optional): `{"tel": "02-123-4567", "capacity": 5000}`



### 4.4 공간(Space) 트리 조회 (핵심)

* **URL:** `GET /fac/facilities/{facility_id}/spaces`
* **Description:** 특정 시설 내부의 공간 구조를 Tree로 반환.
* **Response `data`:**
```json
[
  {
    "key": 100, "title": "관리동", "type": "BLDG",
    "children": [
      { "key": 101, "title": "1F", "type": "FLOOR", "children": [...] }
    ]
  }
]

```



### 4.5 공간 상세 조회 (단건)

* **URL:** `GET /fac/spaces/{id}`
* **Response `data`:**
* 기본 정보 외 `parent_name`, `facility_name` 등 UI 표시에 필요한 조인 정보 포함.



### 4.6 공간 생성

* **URL:** `POST /fac/spaces`
* **Request Body:**
* `facility_id` (int, required)
* `parent_id` (int, optional): 최상위(건물 등)일 경우 null
* `space_type_id` (int, required)
* `space_function_id` (int, optional)
* `code` (str, required): 시설 내 Unique (예: `ELEC_RM_1`)
* `name` (str, required)
* `area_size` (float, optional)
* `is_restricted` (bool, default=false): 출입 제한 여부



### 4.7 공간 삭제

* **URL:** `DELETE /fac/spaces/{id}`
* **Validation:** 하위 공간(`children`)이 존재하면 삭제 불가 (`4091`).

---

## 5. 🧩 CMM (공통 모듈)

### 5.1 공통 코드 다중 조회 (Lookup)

* **URL:** `GET /cmm/codes`
* **Query Params:** `groups=SYS_USE_YN,EQP_STATUS,FILE_CATEGORY`
* **Response `data`:**
```json
{
  "SYS_USE_YN": [
    { "value": "Y", "label": "사용", "props": {"color": "green"} },
    { "value": "N", "label": "미사용", "props": {"color": "red"} }
  ],
  "EQP_STATUS": [...]
}

```



### 5.2 파일 업로드

* **URL:** `POST /cmm/files`
* **Content-Type:** `multipart/form-data`
* **Form Data:**
* `file`: (Binary)
* `domain_code`: (str) `FAC`, `USR` 등
* `category_code`: (str) `IMG`, `DOC` 등


* **Response `data`:**
```json
{
  "id": "a0eebc99-...",
  "file_name": "site_view.jpg",
  "url": "https://cdn.sfms.local/..."
}

```



---

## 6. ⚠️ Frontend 개발자를 위한 가이드

1. **데이터 타입 매핑:**
* `BigInteger` (DB) → `number` (JS/TS) (단, 2^53 초과 시 string 처리 필요하나 ID는 보통 안전)
* `JSONB` (DB) → `Record<string, any>` (TS)


2. **Form Validation:**
* `code` 필드는 입력 시 자동으로 `toUpperCase()` 처리 후 전송 권장.
* `required` 필드 누락 시 백엔드에서 `4000` 에러가 발생하므로 UI에서 선검증.


3. **에러 핸들링:**
* `4010` 수신 시: Redux/Context 상태 비우고 `/login`으로 리다이렉트.
* `4091` 수신 시: `Modal.error({ title: "삭제 불가", content: res.message })` 띄우기.