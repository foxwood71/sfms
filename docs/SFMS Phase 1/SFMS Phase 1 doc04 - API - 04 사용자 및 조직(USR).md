# 📘 SFMS Phase 1 API - 04 사용자 및 조직 관리 (USR) 상세 명세서

* **문서 버전:** v1.3 (Security & Hierarchy Refined)
* **최종 수정일:** 2026-03-08
* **관련 스키마:** `usr.users`, `usr.organizations`
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (SQLAlchemy & Pydantic)

#### [Database Models]

**파일 위치:** `backend/app/domains/usr/models.py`

```python
class Organization(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True) # CHECK (code = UPPER(code))
    parent_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("usr.organizations.id"))
    sort_order: Mapped[int] = mapped_column(Integer, default=10)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

class User(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    login_id: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    emp_code: Mapped[str] = mapped_column(String(20), unique=True)
    name: Mapped[str] = mapped_column(String(50))
    email: Mapped[Optional[str]] = mapped_column(String(100), unique=True)
    org_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("usr.organizations.id"))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
```

---

## 🔐 2. 보안 및 권한 정책 (Security & Permissions)

### 2.1 필드별 수정 권한 매트릭스

| 필드 | 일반 사용자 (Self) | 관리자 (Admin) | 비고 |
| :--- | :---: | :---: | :--- |
| **이름, 이메일, 연락처** | ✅ | ✅ | 일반적인 프로필 수정 |
| **소속 부서 (org_id)** | ❌ | ✅ | 부서 이동은 인사 권한 (일반 유저 수정 시도 시 무시됨) |
| **계정 활성 상태** | ❌ | ✅ | 퇴사 처리 등 (일반 유저 수정 시도 시 무시됨) |
| **비밀번호** | ✅ (본인확인) | ✅ (강제변경) | 별도 엔드포인트 사용 |

---

## 🏢 3. 조직 관리 API (Organizations)

### 3.1 조직도 조회 (List/Tree)

* **URL:** `GET /usr/organizations`
* **Query Params:** `mode` ('tree' or 'flat'), `is_active`
* **Logic:** 비동기 지연 로딩 방지를 위해 완전 직렬화된 데이터를 반환합니다.

### 3.2 조직 생성 및 수정

* **URL:** `POST /usr/organizations`, `PATCH /usr/organizations/{org_id}`
* **Constraint:**
    1. **Case Sensitivity**: `code`는 대문자만 허용.
    2. **Hierarchy Integrity**: 자기 참조 및 순환 참조 금지 (`4004`, `4005`).

### 3.3 조직 삭제

* **URL:** `DELETE /usr/organizations/{org_id}`
* **Constraint:** 하위 부서나 소속 사용자가 있을 경우 삭제 불가 (`4091 RESOURCE_IN_USE`).

---

## 👤 4. 사용자 관리 API (Users)

### 4.1 사용자 목록 조회 및 검색

* **URL:** `GET /usr`
* **Query Params:** `keyword` (성명/ID/사번), `org_id`, `include_children`

### 4.2 신규 사용자 등록

* **URL:** `POST /usr/users`
* **Permission:** 관리자 전용
* **Logic:** ID/이메일/사번 중복 체크 및 초기 비밀번호 해싱.

### 4.3 사용자 정보 수정 (Update Profile)

* **URL:** `PATCH /usr/{user_id}`
* **Permission:** **본인 또는 관리자**
* **Logic:** 
    1. 타인의 정보를 수정하려 할 경우 `4032 ACCESS_DENIED` 발생.
    2. 일반 사용자가 `org_id`나 `is_active` 필드를 포함해 요청할 경우, 해당 필드는 무시하고 나머지 정보만 수정합니다.
    3. 부서 변경(`org_id`) 발생 시 시스템 감사 로그(`ORG_CHANGE`)를 자동 생성합니다.

### 4.4 비밀번호 관리 (Password)

* **URL:** `PUT /usr/{user_id}/password`
* **Logic:** 
    * **본인**: `current_password`가 일치해야 수정 가능.
    * **관리자**: 현재 비밀번호 확인 없이 강제 변경 가능 (감사 로그 기록).

### 4.5 사용자 계정 비활성화

* **URL:** `DELETE /usr/{user_id}`
* **Logic:** 물리 삭제가 아닌 **논리 삭제(`is_active=False`)** 처리하며, 메타데이터에 퇴사일시 등을 기록합니다.

---

## ⚠️ 5. USR 도메인 특화 에러 코드

| Code | Name | Description |
| --- | --- | --- |
| `4001` | `PASSWORD_MISMATCH` | 현재 비밀번호가 일치하지 않습니다. |
| `4004` | `INVALID_PARENT_ORG` | 상위 부서 ID가 유효하지 않거나 자기 자신입니다. |
| `4005` | `CIRCULAR_REFERENCE` | 조직 구조에 순환 참조가 발생했습니다. |
| `4032` | `ACCESS_DENIED` | 본인 정보가 아니거나 수정 권한이 없습니다. |
| `4091` | `RESOURCE_IN_USE` | 하위 부서나 소속 사용자가 있어 삭제할 수 없습니다. |
| `4092` | `DUPLICATE_LOGIN_ID` | 이미 사용 중인 로그인 ID입니다. |
| `4093` | `DUPLICATE_EMAIL` | 이미 등록된 이메일 주소입니다. |
| `4094` | `DUPLICATE_EMP_CODE` | 이미 등록된 사원 번호입니다. |
| `4095` | `DUPLICATE_ORG_CODE` | 이미 사용 중인 조직 코드입니다. |
