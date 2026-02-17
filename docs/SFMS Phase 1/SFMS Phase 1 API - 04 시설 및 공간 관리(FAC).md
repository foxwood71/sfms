# 📘 SFMS Phase 1 API - 04 시설 및 공간 관리 (FAC) 상세 명세서 (Revised v1.1)

* **문서 버전:** v1.1 (Production Ready)
* **작성일:** 2026-02-17
* **관련 스키마:** `fac.facilities`, `fac.spaces` 등
* **기준 규격:** `SFMS Standard v1.2`

---

## 1. 🏗️ 데이터 모델 및 타입 정의 (Data Models & Types)

**보완점:** Pydantic v2 `ConfigDict` 적용, `Enum` 사용, 그리고 프론트엔드 최적화를 위한 `Thumbnail URL` 필드를 명시했습니다.

### 1.1 Backend Models (Python/Pydantic)

파일 위치: `app/modules/fac/schemas.py`

```python
from pydantic import BaseModel, Field, ConfigDict, field_validator
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum
import uuid

# [Enum] 검색 대상
class SearchTarget(str, Enum):
    ALL = "all"
    FACILITY = "facility"
    SPACE = "space"

# --------------------------------------------------------
# [Base Code] 기초 코드
# --------------------------------------------------------
class FacCodeBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$")
    description: Optional[str] = None
    is_active: bool = True

class FacCodeRead(FacCodeBase):
    id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [Facility] 최상위 시설
# --------------------------------------------------------
class FacilityBase(BaseModel):
    category_id: int
    name: str = Field(..., min_length=2)
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$")
    address: Optional[str] = None
    is_active: bool = True
    sort_order: int = 0
    metadata: Dict[str, Any] = Field(default_factory=dict)

class FacilityCreate(FacilityBase):
    pass

class FacilityUpdate(BaseModel):
    category_id: Optional[int] = None
    name: Optional[str] = None
    # code 수정 불가
    address: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None

class FacilityRead(FacilityBase):
    id: int
    category_name: Optional[str] = None
    representative_image_id: Optional[uuid.UUID] = None
    representative_image_url: Optional[str] = None # 썸네일 URL
    
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --------------------------------------------------------
# [Space] 공간 (계층 구조)
# --------------------------------------------------------
class SpaceBase(BaseModel):
    facility_id: int
    parent_id: Optional[int] = None
    space_type_id: Optional[int] = None
    space_function_id: Optional[int] = None
    
    name: str
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$")
    area_size: Optional[float] = Field(None, ge=0)
    is_restricted: bool = False
    is_active: bool = True
    sort_order: int = 0
    metadata: Dict[str, Any] = Field(default_factory=dict)

class SpaceCreate(SpaceBase):
    pass

class SpaceUpdate(BaseModel):
    # facility_id 수정 불가 (이동 시 삭제 후 생성 권장)
    parent_id: Optional[int] = None
    space_type_id: Optional[int] = None
    space_function_id: Optional[int] = None
    name: Optional[str] = None
    area_size: Optional[float] = None
    is_restricted: Optional[bool] = None
    is_active: Optional[bool] = None
    metadata: Optional[Dict[str, Any]] = None

class SpaceRead(SpaceBase):
    id: int
    representative_image_id: Optional[uuid.UUID] = None
    representative_image_url: Optional[str] = None
    
    # Tree 구조 (Children)
    children: Optional[List['SpaceRead']] = Field(default_factory=list)
    
    type_name: Optional[str] = None
    function_name: Optional[str] = None
    
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# [Search] 통합 검색 결과
class SearchResult(BaseModel):
    id: int
    type: str = Field(..., description="FACILITY or SPACE")
    name: str
    code: str
    location_path: str = Field(..., description="위치 경로 (예: 사업소 > 본관 > 1층)")
    highlight: Optional[str] = None # 검색어 하이라이팅 (PGroonga)

```

### 1.2 Frontend Interfaces (TypeScript)

파일 위치: `src/api/fac/types.ts`

```typescript
// [Base Code]
export interface FacCode {
  id: number;
  name: string;
  code: string;
  is_active: boolean;
}

// [Facility]
export interface Facility {
  id: number;
  category_id: number;
  category_name?: string;
  name: string;
  code: string;
  address?: string;
  representative_image_id?: string;
  representative_image_url?: string;
  is_active: boolean;
  metadata: Record<string, any>;
  created_at: string;
}

// [Space]
export interface Space {
  id: number;
  facility_id: number;
  parent_id: number | null;
  name: string;
  code: string;
  type_name?: string;
  function_name?: string;
  representative_image_url?: string;
  children?: Space[];
  is_active: boolean;
}

```

---

## 2. 🗂️ 기초 코드 관리 API (Codes)

*(기존 v1.0과 동일하므로 생략)*

---

## 3. 🏭 최상위 시설 관리 API (Facilities)

### 3.1 시설 목록 조회

* **URL:** `GET /api/v1/fac/facilities`
* **Query Params:**
* `keyword`: 이름/코드 검색
* `category_id`: 필터
* `is_active`: `true` | `all`


* **Response:** `ApiResponse<List[FacilityRead]>`
* **Logic:**
* `representative_image_id`가 있으면 `cmm` 모듈을 통해 `representative_image_url` (썸네일)을 생성하여 반환.



### 3.2 시설 생성

* **URL:** `POST /api/v1/fac/facilities`
* **Body:** `FacilityCreate`
* **Logic:**
* `code` 중복 시 `4096 (DUPLICATE_FACILITY_CODE)` 반환.



### 3.3 시설 삭제

* **URL:** `DELETE /api/v1/fac/facilities/{id}`
* **Logic:**
* 하위 공간(`fac.spaces`) 존재 여부 확인 (`count > 0` 이면 `4091` 에러).
* 안전 삭제(Safe Delete)를 우선 적용.



---

## 4. 🏢 공간 계층 관리 API (Spaces)

**대용량 트리 처리**와 **순환 참조 방지**가 핵심입니다.

### 4.1 시설별 공간 트리 조회 (Optimized)

* **URL:** `GET /api/v1/fac/facilities/{facility_id}/spaces`
* **Query Params:**
* `mode`: `tree` (기본) | `flat`
* `depth`: 조회 깊이 제한 (예: 2depth까지만 조회)


* **Response:** `ApiResponse<List[SpaceRead]>`
* **Logic:**
* **Batch Load:** DB에서 해당 시설의 전체 공간 데이터를 `flat`하게 한 번에 조회 (`SELECT * FROM spaces WHERE facility_id = ?`).
* **In-Memory Assembly:** Python 코드에서 부모-자식 관계를 연결하여 Tree 구조 생성 (DB 재귀 쿼리보다 애플리케이션 레벨 조립이 유지보수에 유리).
* **Cache:** 시설별 트리 구조는 Redis에 캐싱 (`@cache(expire=3600, key_builder=...)`).



### 4.2 공간 생성

* **URL:** `POST /api/v1/fac/spaces`
* **Logic:**
* **복합 유니크:** `(facility_id, code)` 중복 시 `4097` 에러.
* **부모 검증:** `parent_id`가 동일한 `facility_id`를 가지는지 검증.



### 4.3 공간 수정 (Move & Update)

* **URL:** `PATCH /api/v1/fac/spaces/{id}`
* **Logic:**
* **순환 참조 방지 (Circular Check):** `parent_id` 변경 시, 대상 부모가 '나의 자손'인지 확인. 맞다면 `4005` 에러.
* **Cache Eviction:** 수정 시 해당 시설의 Redis 트리 캐시 무효화.



### 4.4 공간 삭제

* **URL:** `DELETE /api/v1/fac/spaces/{id}`
* **Logic:**
* 하위 공간 존재 시 `4098 (SPACE_HAS_CHILDREN)` 반환.



---

## 5. 🔍 통합 검색 API (Search)

**PGroonga**를 활용한 강력한 검색 기능입니다.

### 5.1 시설/공간 통합 검색

* **URL:** `GET /api/v1/fac/search`
* **Query Params:**
* `keyword`: 검색어 (한글, 영어, 메타데이터 JSON 값)
* `target`: `all` | `facility` | `space`


* **Response:** `ApiResponse<List[SearchResult]>`
* **Logic:**
* **PGroonga Query:** `&@~` 연산자를 사용하여 `name`, `code`, `metadata` 컬럼 동시 검색.
* **Highlighting:** 검색된 키워드 주변 텍스트를 추출하여 `highlight` 필드에 반환 (프론트엔드 강조 표시용).
* **Location Path:** 공간 검색 시, 상위 시설 및 부모 공간의 이름을 조합하여 경로 제공 (예: "제1처리장 > 침전지 > 1호기").



---

## 6. 🖼️ 이미지 관리 (Integration)

* **URL:** `PUT /api/v1/fac/{target_type}/{id}/image`
* **Content-Type:** `multipart/form-data`
* **Logic:**
1. `cmm.file_service` 호출 -> 이미지 업로드 및 썸네일 생성.
2. UUID 반환받아 `fac` 테이블 업데이트.
3. 결과로 썸네일 URL 반환.



---

## 7. ⚠️ FAC 도메인 에러 코드 (Error Codes)

| HTTP | Code | Name | Description |
| --- | --- | --- | --- |
| 409 | `4096` | `DUPLICATE_FACILITY_CODE` | 이미 존재하는 시설 코드입니다. |
| 409 | `4097` | `DUPLICATE_SPACE_CODE` | 해당 시설 내에 이미 존재하는 공간 코드입니다. |
| 400 | `4004` | `INVALID_PARENT_SPACE` | 상위 공간이 유효하지 않거나 다른 시설에 속해 있습니다. |
| 400 | `4005` | `CIRCULAR_REFERENCE` | 자기 자신 또는 자손을 상위 공간으로 지정할 수 없습니다. |
| 409 | `4098` | `SPACE_HAS_CHILDREN` | 하위 공간이 존재하여 삭제할 수 없습니다. |

---

## 8. ✅ 구현 체크리스트 (Final Checklist)

* [ ] **Tree Assembly Logic**: Python `list_to_tree` 유틸리티 함수 구현 및 단위 테스트.
* [ ] **Circular Dependency**: 부모 변경 시 BFS/DFS 탐색을 통한 순환 참조 방지 로직 구현.
* [ ] **PGroonga Search**: `metadata` JSONB 컬럼에 대한 PGroonga 인덱스 생성 및 검색 쿼리 튜닝 (`EXPLAIN ANALYZE`).
* [ ] **Image Thumbnail**: 목록 조회 시 원본 이미지가 아닌 썸네일 URL을 반환하여 트래픽 최적화 확인.
* [ ] **Path Generation**: 검색 결과에서 `location_path`를 생성하기 위한 `CTE` 쿼리 또는 로직 구현.

이로써 **Phase 1의 4대 핵심 모듈(Standard/CMM, IAM, USR, FAC)**에 대한 **최종 상세 명세서(v1.1~v1.3)** 작성이 모두 완료되었습니다.

이제 이 명세서를 바탕으로 **DB 스키마 적용** 및 **API 개발**을 시작하시면 됩니다. 추가적인 지원이 필요하신가요?