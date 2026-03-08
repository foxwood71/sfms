"""시설 및 공간 관리(FAC) 도메인의 Pydantic 스키마를 정의하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [Base Codes] 기초 코드 관련 스키마
# --------------------------------------------------------


class FacilityCategoryRead(BaseModel):
    """시설 카테고리 정보 조회 응답을 위한 스키마입니다."""

    id: int
    code: str
    name: str
    description: str | None = None
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


class SpaceTypeRead(BaseModel):
    """공간 물리적 유형 조회 응답을 위한 스키마입니다."""

    id: int
    code: str
    name: str
    is_active: bool
    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Facility] 최상위 시설 관련 스키마
# --------------------------------------------------------


class FacilityBase(BaseModel):
    """시설의 공통 속성을 정의하는 기본 스키마입니다."""

    category_id: int | None = None
    representative_image_id: uuid.UUID | None = None
    code: str = Field(..., min_length=2, max_length=50)
    name: str = Field(..., min_length=2, max_length=100)
    address: str | None = None
    is_active: bool = True
    sort_order: int = 0
    metadata_info: dict[str, Any] = Field(default_factory=dict)


class FacilityCreate(FacilityBase):
    """신규 시설 등록을 위한 스키마입니다."""

    pass


class FacilityUpdate(BaseModel):
    """시설 정보 수정을 위한 스키마입니다."""

    category_id: int | None = None
    representative_image_id: uuid.UUID | None = None
    name: str | None = None
    address: str | None = None
    is_active: bool | None = None
    sort_order: int | None = None
    metadata_info: dict[str, Any] | None = None


class FacilityRead(FacilityBase):
    """시설 정보 조회 응답을 위한 스키마입니다."""

    id: int
    created_at: datetime
    updated_at: datetime
    created_by: int | None = None
    updated_by: int | None = None
    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Space] 공간 계층 관련 스키마
# --------------------------------------------------------


class SpaceBase(BaseModel):
    """공간의 공통 속성을 정의하는 기본 스키마입니다."""

    facility_id: int
    parent_id: int | None = None
    space_type_id: int | None = None
    space_function_id: int | None = None
    representative_image_id: uuid.UUID | None = None
    code: str = Field(..., min_length=1, max_length=50)
    name: str = Field(..., min_length=1, max_length=100)
    area_size: float | None = None
    is_active: bool = True
    sort_order: int = 0
    is_restricted: bool = False
    org_id: int | None = Field(None, description="관리 책임 부서 ID")
    metadata_info: dict[str, Any] = Field(default_factory=dict)


class SpaceCreate(SpaceBase):
    """신규 공간 생성을 위한 스키마입니다."""

    pass


class SpaceUpdate(BaseModel):
    """공간 정보 수정을 위한 스키마입니다."""

    parent_id: int | None = None
    space_type_id: int | None = None
    space_function_id: int | None = None
    representative_image_id: uuid.UUID | None = None
    name: str | None = None
    area_size: float | None = None
    is_active: bool | None = None
    sort_order: int | None = None
    is_restricted: bool | None = None
    metadata_info: dict[str, Any] | None = None


class SpaceRead(SpaceBase):
    """공간 정보 조회 응답을 위한 스키마입니다."""

    id: int
    children: list["SpaceRead"] | None = None
    created_at: datetime
    updated_at: datetime
    created_by: int | None = None
    updated_by: int | None = None
    model_config = ConfigDict(from_attributes=True)
