# 📄 SFMS Phase 1 doc07 - 프론트엔드 화면 및 컴포넌트 명세서 (Final)

* **프로젝트명:** SFMS (Smart Facility Management System)
* **작성일:** 2026-02-18
* **버전:** v1.0
* **기술 스택:** React, Ant Design Pro (v5), Tailwind CSS
* **UI 표준:** **High Density** (`size="small"`, `fontSize: 13px`)

---

## 1. 🗺️ 글로벌 레이아웃 (Global Layout)

`src/layouts/BasicLayout.tsx`

시스템 전체의 골격입니다. `ProLayout` 컴포넌트를 사용합니다.

### 1.1 레이아웃 설정 (Props)

| 속성 (Prop) | 설정값 | 설명 |
| --- | --- | --- |
| `layout` | `"mix"` | 상단 헤더 + 좌측 사이드바 혼합형 |
| `splitMenus` | `false` | 대메뉴/소메뉴 분리 안 함 |
| `fixedHeader` | `true` | 헤더 고정 |
| `fixSiderbar` | `true` | 사이드바 고정 |
| `siderWidth` | `220` | 사이드바 너비 (Pixel) |
| `token` | `{ sider: { colorMenuBackground: '#fff' } }` | 사이드바 배경색 (Clean White) |

### 1.2 헤더 (RightContent)

* **AvatarDropdown:**
* **표시:** `Current User Name` + `Avatar(Image)`
* **메뉴:**
1. 👤 **내 정보** (Drawer 오픈)
2. 🔑 **비밀번호 변경** (Modal 오픈)
3. 🚪 **로그아웃** (Confirm 후 `/api/v1/auth/logout` 호출)

---

## 2. 🧩 공통 비즈니스 컴포넌트 (Shared Business Components)

여러 화면에서 **반복적으로 사용되는 입력 도구**를 표준화합니다.

### 2.1 공통 코드 셀렉트 (`CodeSelect`)

DB의 공통 코드를 조회하여 `Select` 옵션으로 렌더링합니다.

* **Props:**
* `groupCode` (Required): 공통 코드 그룹 (예: `FAC_CAT`)
* `value` / `onChange`: Form 연동용
* `placeholder`: 기본 문구

* **Logic:**
* `useQuery(['codes', groupCode])`로 API 호출 (`GET /cmm/codes/{group}/lookup`).
* **StaleTime:** `Infinity` (코드는 세션 동안 안 변함).

### 2.2 조직 트리 셀렉트 (`OrgTreeSelect`)

부서를 선택할 때 사용하는 트리형 드롭다운입니다.

* **Props:**
* `rootId`: 특정 부서 하위만 보일지 여부 (Optional)

* **Logic:**
* API 호출: `GET /usr/organizations?mode=tree`
* `AntD TreeSelect` 컴포넌트 매핑 (`value=id`, `title=name`, `children=children`).

### 2.3 시설 트리 셀렉트 (`OrgTreeSelect`)

시설과 공간(위치)을 선택할 때 사용하는 트리형 드롭다운입니다.

* **Props:**
* facilityId (Required): 공간 트리를 조회할 상위 시설 ID (필수).
* value / onChange: Form 연동용.
* disabled: 시설이 선택되지 않았을 경우 true.

* **Logic:**
* API 호출: `GET /fac/facilities/{facilityId}/spaces?mode=tree`
* Dependency Check: facilityId props가 null이거나 비어있으면 컴포넌트를 Disabled 상태로 하고 "시설을 먼저 선택하세요" Placeholder 표시.
* `AntD TreeSelect` 컴포넌트 매핑 (`value=id`, `title=name`, `children=children`).
* Icon Mapping: 공간 타입(space_type_id)에 따라 아이콘 구분 (예: 🏢 건물, 🅿️ 구역, 🚪 호실).
* Selectable: 부모 노드(건물 등)도 선택 가능하도록 설정 (단, 정책에 따라 disableCheckbox 처리 가능).

### 2.4 이미지 업로더 (`ImageUploader`)

* **Props:**
* `domain`: `FAC` | `USR` ...
* `value`: `uuid` (현재 이미지 ID)
* `onChange`: `(newUuid) => void`

* **UI:**
* 이미지가 있으면: 썸네일 표시 + "변경/삭제" 버튼 오버레이.
* 이미지가 없으면: "업로드" 박스 표시.

* **Logic:**
* 파일 선택 즉시 `POST /cmm/files/upload` 호출.
* 업로드 성공 시 `uuid`를 받아 `onChange(uuid)` 실행.

---

## 3. 🖥️ 핵심 화면 상세 명세 (Screen Specifications)

### 3.1 🔐 로그인 (Login)

* **경로:** `/login`
* **레이아웃:** `UserLayout` (배경 이미지 + 중앙 카드)

| UI 요소 | 타입 | 검증 규칙 (Validation) | 비고 |
| --- | --- | --- | --- |
| **아이디** | Input | 필수, 영문 소문자/숫자, min:4 | `prefix={<UserOutlined />}` |
| **비밀번호** | Password | 필수, min:6 | `prefix={<LockOutlined />}` |
| **로그인 버튼** | Button | - | `loading` 상태 처리 필수 |

* **API Action:** `POST /auth/login`
* **Success:** Access Token 저장 -> `/` (대시보드) 이동.
* **Error:** `401`: "아이디 또는 비밀번호를 확인해주세요." (상세 에러 숨김)

---

### 3.2 🏭 시설 목록 관리 (Facility List)

* **경로:** `/fac/list`
* **컴포넌트:** `ProTable<Facility>`

#### A. 검색 영역 (Search Form)

| 라벨 | 필드명 (`dataIndex`) | 컴포넌트 | 비고 |
| --- | --- | --- | --- |
| **시설 구분** | `category_id` | `CodeSelect` | group=`FAC_CAT` |
| **시설명/코드** | `keyword` | `Input.Search` | |
| **운영 상태** | `is_active` | `Select` | 전체/운영중/중단 |

#### B. 테이블 컬럼 (Columns)

| 헤더 | 데이터 키 | 너비 | 렌더링 (Render) |
| --- | --- | --- | --- |
| **코드** | `code` | 100px | **Bold** + Click 시 수정 Drawer 오픈 |
| **시설명** | `name` | 200px | 텍스트 |
| **구분** | `category_name` | 120px | `Tag` (Color: Blue) |
| **주소** | `address` | - | 말줄임 (`ellipsis`) |
| **상태** | `is_active` | 80px | `Badge` (Success=운영중, Default=중단) |
| **관리** | `option` | 150px | `수정` (Button), `삭제` (Popconfirm) |

#### C. 신규/수정 Drawer (Form)

* **컴포넌트:** `DrawerForm`
* **API:** `POST /fac/facilities` (신규), `PATCH /fac/facilities/{id}` (수정)

| 라벨 | 필드명 | 컴포넌트 | 필수 | 비고 |
| --- | --- | --- | --- | --- |
| **시설 구분** | `category_id` | `CodeSelect` | Y | |
| **시설 코드** | `code` | `Input` | Y | 수정 시 **Readonly** (Disabled) |
| **시설명** | `name` | `Input` | Y | |
| **대표 이미지** | `image_id` | `ImageUploader` | N | |
| **주소** | `address` | `Input` | N | |
| **운영 여부** | `is_active` | `Switch` | Y | Default: True |

---

### 3.3 🌳 공간 계층 관리 (Space Tree)

* **경로:** `/fac/tree`
* **레이아웃:** `ProCard` (Split Mode: 30% Tree / 70% Detail)

#### [Left] 시설 및 공간 트리

* **Header:** `시설 선택 (Select)` -> `facility_id` 상태 변경.
* **Body:** `AntD Tree`
* **Data:** `GET /fac/facilities/{id}/spaces?mode=tree`
* **Node:**
* `icon`: 📂 (자식 있음), 📄 (자식 없음)
* `title`: `[코드] 명칭`

* **Interaction:**
* `Select`: 우측 상세 폼에 데이터 로딩.
* `Drag & Drop`: `PATCH /fac/spaces/{dragId}` (Body: `{parent_id: dropId}`) 호출.

#### [Right] 공간 상세 정보 (Detail Form)

* **컴포넌트:** `ProForm`
* **모드:** 조회(Readonly) / 수정(Edit) / 신규등록(Create - 트리 상단 버튼)

| 섹션 | 라벨 | 필드명 | 컴포넌트 | 설정 |
| --- | --- | --- | --- | --- |
| **기본 정보** | **상위 공간** | `parent_id` | `TreeSelect` | 현재 시설 트리 바인딩 |
| | **공간 유형** | `space_type_id` | `CodeSelect` | group=`SPC_TYPE` (건물, 층, 실) |
| | **기능 분류** | `func_id` | `CodeSelect` | group=`SPC_FUNC` (전기, 기계) |
| | **공간 코드** | `code` | `Input` | 대문자 강제 변환 |
| | **공간 명칭** | `name` | `Input` | |
| **속성 정보** | **면적** | `area_size` | `InputNumber` | suffix="m²" |
| | **출입 통제** | `is_restricted` | `Switch` | |
| **사진** | **전경 사진** | `image_id` | `ImageUploader` | |
| **메타데이터** | **설비 제원** | `metadata` | `ProFormList` | Key-Value 동적 추가 (Phase 1.5) |

---

### 3.4 👥 사용자 관리 (User List)

* **경로:** `/usr/list`
* **컴포넌트:** `ProTable<User>`

#### A. 검색 영역

| 라벨 | 필드명 | 컴포넌트 | 비고 |
| --- | --- | --- | --- |
| **소속 부서** | `org_id` | `OrgTreeSelect` | |
| **검색어** | `keyword` | `Input` | 이름/사번/ID |
| **재직 상태** | `status` | `Select` | 재직/휴직/퇴사 |

#### B. 사용자 등록/수정 Modal

* **API:** `POST /usr/users`, `PATCH /usr/users/{id}`

| 라벨 | 필드명 | 컴포넌트 | 필수 | 규칙 |
| --- | --- | --- | --- | --- |
| **프로필** | `profile_id` | `ImageUploader` | N | Avatar 모드 (Circle) |
| **로그인 ID** | `login_id` | `Input` | Y | 중복 체크 버튼 (Suffix) |
| **비밀번호** | `password` | `Input.Password` | Y | **신규 등록 시에만 노출** |
| **성명** | `name` | `Input` | Y | |
| **사번** | `emp_code` | `Input` | Y | |
| **이메일** | `email` | `Input` | Y | Email 포맷 검증 |
| **소속 부서** | `org_id` | `OrgTreeSelect` | N | |
| **직위/직급** | `metadata.pos` | `CodeSelect` | N | group=`POS_TYPE` (과장, 대리) |

---

## 4. ⚡️ 인터랙션 및 피드백 표준 (Interaction Standards)

사용자 경험(UX)의 일관성을 위한 규칙입니다.

### 4.1 로딩 상태 (Loading)

* **페이지 진입 시:** `Skeleton` 컴포넌트 사용 (깜빡임 방지).
* **버튼 클릭 시:** 버튼 내부에 `Spinner` 표시 및 `disabled` 처리 (중복 전송 방지).
* **테이블 조회 시:** `ProTable` 내장 `loading` 속성 활성화.

### 4.2 알림 메시지 (Feedback)

* **성공:** `message.success("저장되었습니다.")` (화면 중앙 상단 토스트)
* **실패 (Business):** `message.error("중복된 ID입니다.")`
* **실패 (System):** `notification.error({ message: "서버 오류", description: "..." })` (우측 상단 박스)
* **삭제 확인:** 반드시 `Popconfirm` 또는 `Modal.confirm`을 거쳐야 함 ("정말 삭제하시겠습니까? 복구할 수 없습니다.").

---

### 5. 🚀 Phase 2 (구현) 착수 가이드

이제 모든 설계가 끝났습니다. 다음 순서로 개발을 진행하십시오.

1. **Project Setup:** `npm create vite@latest` -> `doc04` 기술 스택 적용.
2. **Theme Config:** `doc04`의 `theme.ts` 적용 (AntD ConfigProvider).
3. **Layout Impl:** `src/layouts/BasicLayout` 구현 (`ProLayout`).
4. **Common Comps:** `CodeSelect`, `ImageUploader` 등 공통 컴포넌트 우선 개발.
5. **Page Impl:** `Login` -> `Facility List` -> `User List` 순서로 개발.
