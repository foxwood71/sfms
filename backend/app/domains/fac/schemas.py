"""시설 및 공간 관리(FAC) 도메인의 Pydantic 스키마를 정의하는 모듈입니다."""

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


# --------------------------------------------------------
# [Space] 공간 관련 스키마
# --------------------------------------------------------
class SpaceBase(BaseModel):
    """공간의 공통 속성 스키마입니다."""

    name: str = Field(..., min_length=1, max_length=100)
    code: str = Field(..., min_length=2, max_length=50)
    space_type: str = Field(..., description="공간 유형 (예: SITE, BLDG, FLOOR, ROOM)")
    parent_id: Optional[int] = Field(None, description="상위 공간 ID")
    is_active: bool = True


class SpaceCreate(SpaceBase):
    """공간 생성 스키마입니다."""

    pass


class SpaceUpdate(BaseModel):
    """공간 수정 스키마입니다."""

    name: Optional[str] = None
    space_type: Optional[str] = None
    parent_id: Optional[int] = None
    is_active: Optional[bool] = None


class SpaceRead(SpaceBase):
    """공간 조회 스키마입니다."""

    id: int
    children: Optional[List["SpaceRead"]] = None  # 트리 구조 재귀 표현
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Facility] 설비 관련 스키마
# --------------------------------------------------------
class FacilityBase(BaseModel):
    """설비의 공통 속성 스키마입니다."""

    name: str = Field(..., min_length=1, max_length=100)
    code: str = Field(..., min_length=2, max_length=50)
    space_id: Optional[int] = Field(None, description="설비가 위치한 공간 ID")
    status: str = Field("ACTIVE", description="설비 상태")
    metadata_info: Dict[str, Any] = Field(
        default_factory=dict, description="제조사, 규격 등 상세 정보"
    )


class FacilityCreate(FacilityBase):
    """설비 생성 스키마입니다."""

    pass


class FacilityUpdate(BaseModel):
    """설비 수정 스키마입니다."""

    name: Optional[str] = None
    space_id: Optional[int] = None
    status: Optional[str] = None
    metadata_info: Optional[Dict[str, Any]] = None


class FacilityRead(FacilityBase):
    """설비 조회 스키마입니다."""

    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
