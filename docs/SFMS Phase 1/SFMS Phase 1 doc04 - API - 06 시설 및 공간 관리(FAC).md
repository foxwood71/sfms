# 📘 SFMS Phase 1 API - 06 시설 및 공간 관리 (FAC) 상세 명세서

* **문서 버전:** v1.2 (Leader-based Permissions Updated)
* **최종 수정일:** 2026-03-07
* **관련 스키마:** `fac.facilities`, `fac.spaces`, `fac.facility_categories` 등
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

### 1.1 Backend Models (SQLAlchemy & Pydantic)

#### [Database Models]

**파일 위치:** `backend/app/domains/fac/models.py`

```python
class Facility(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    category_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("fac.facility_categories.id"))
    representative_image_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    code: Mapped[str] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    address: Mapped[Optional[str]] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    metadata_info: Mapped[Dict[str, Any]] = mapped_column("metadata", JSONB)

class Space(Base):
    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    facility_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("fac.facilities.id"))
    parent_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("fac.spaces.id"))
    representative_image_id: Mapped[Optional[uuid.UUID]] = mapped_column(UUID(as_uuid=True))
    space_type_id: Mapped[Optional[int]] = mapped_column(BigInteger, ForeignKey("fac.space_types.id"))
    code: Mapped[str] = mapped_column(String(50))
    name: Mapped[str] = mapped_column(String(100))
    org_id: Mapped[Optional[int]] = mapped_column(BigInteger, index=True) # 관리 책임 부서
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
```

#### [Pydantic Schemas]

**파일 위치:** `backend/app/domains/fac/schemas.py`

```python
class FacilityRead(BaseModel):
    id: int
    category_id: Optional[int]
    representative_image_id: Optional[uuid.UUID]
    code: str
    name: str
    address: Optional[str]
    is_active: bool
    sort_order: int
    metadata_info: Dict[str, Any]
    model_config = ConfigDict(from_attributes=True)

class SpaceRead(BaseModel):
    id: int
    facility_id: int
    parent_id: Optional[int]
    space_type_id: Optional[int]
    code: str
    name: str
    org_id: Optional[int]
    children: Optional[List["SpaceRead"]] = None
    model_config = ConfigDict(from_attributes=True)
```

---

## 2. 🔐 보안 및 권한 정책 (Security & Permissions)

최상위 시설은 도메인 관리자가 통제하며, 세부 공간은 실제 관리 책임 부서의 리더에게 권한을 위임합니다.

### 2.1 사용자별 권한 매트릭스

| 대분류 | 기능 | 일반 사용자 | 부서장/팀장 | 도메인 관리자(FAC) | 상세 보안 로직 |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **시설 관리** | 시설 목록/상세 조회 | ✅ | ✅ | ✅ | 모든 직원 조회 가능 |
| | 시설 추가/편집/삭제 | ❌ | ❌ | ✅ | `FAC_ADMIN` 또는 `SUPER_ADMIN` |
| **공간 관리** | 공간 트리/목록 조회 | ✅ | ✅ | ✅ | |
| | 공간 신규 생성 | ❌ | ❌ | ✅ | 관리자 전용 (시스템 구조 설정) |
| | **공간 정보 수정** | ❌ | ⚠️ | ✅ | **부서장 한정**: 해당 공간의 `org_id`가 본인 부서이고 직책이 리더인 경우 |
| **파일 관리** | 시설/공간 사진 업로드 | ✅ | ✅ | ✅ | `cmm` 도메인 통합 업로드 사용 |
| | 파일 삭제/복구 | ❌ | ⚠️ | ✅ | **부서 단위**: 본인 또는 동일 부서원 파일만 |

---

## 🏭 3. 최상위 시설 관리 API (Facilities)

### 3.1 시설 목록 및 상세 조회

* **URL:** `GET /fac/facilities`, `GET /fac/facilities/{id}`
* **Permission:** 모든 인증된 사용자

### 3.2 시설 생성/수정

* **URL:** `POST /fac/facilities`, `PATCH /fac/facilities/{id}`
* **Permission:** **도메인 관리자 전용** (`check_domain_admin("FAC")`)

---

## 🏢 4. 공간 계층 관리 API (Spaces)

### 4.1 시설별 공간 트리 조회

* **URL:** `GET /fac/facilities/{facility_id}/spaces`
* **Logic:** 해당 시설의 전체 공간을 한 번에 조회 후 메모리에서 트리 구조로 조립하여 반환.

### 4.2 공간 생성

* **URL:** `POST /fac/spaces`
* **Permission:** **도메인 관리자 전용**
* **Logic:** 생성 시 해당 공간을 관리할 책임 부서(`org_id`)를 지정합니다.

### 4.3 공간 정보 수정 (편집)

* **URL:** `PATCH /fac/spaces/{space_id}`
* **Permission:** **부서장 또는 관리자**
* **Security Logic:**
    1. 수행자의 역할이 `SUPER_ADMIN` 또는 `FAC_ADMIN`이면 무조건 허용.
    2. 일반 사용자인 경우:
        * 수행자의 `org_id` == 공간의 `org_id`
        * **AND** 수행자의 `metadata.duty`가 [`부서장`, `팀장`, `MANAGER`] 중 하나여야 함.

---

## ⚠️ 5. FAC 도메인 특화 에러 코드

| Code | Name | Description |
| --- | --- | --- |
| `4032` | `ACCESS_DENIED` | 해당 공간의 관리 부서장이 아니어서 수정 거부 |
| `4005` | `CIRCULAR_REFERENCE` | 상위 공간 변경 시 자기 자신 또는 자손을 선택함 |
| `4090` | `DUPLICATE_CODE` | 동일 시설 내 중복된 공간 코드 사용 |

---

## ✅ 6. 구현 체크리스트

* [x] **Model Consistency**: DB 스키마와 SQLAlchemy 모델의 필드명이 완벽히 일치하는가?
* [x] **Leader Logic**: 사용자 메타데이터를 활용한 '부서장' 식별 로직이 서비스 레이어에 포함되었는가?
* [x] **Recursive Tree**: 공간 트리 조회 시 순환 참조 없이 안정적으로 계층을 구성하는가?
* [x] **Audit Field**: 시설/공간 변경 시 `updated_by` 가 정확히 기록되는가?
