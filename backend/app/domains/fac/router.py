"""시설 및 공간 관리(FAC) 도메인의 API 라우터 모듈입니다."""

from typing import Any, Dict, List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.schemas import APIResponse
from app.domains.fac.schemas import (
    FacilityCreate,
    FacilityRead,
    SpaceCreate,
    SpaceRead,
    SpaceUpdate,
)
from app.domains.fac.services import FacilityService, SpaceService

router = APIRouter(prefix="/fac", tags=["시설 및 공간 관리 (FAC)"])


# --------------------------------------------------------
# [Space] 공간 API
# --------------------------------------------------------
@router.get("/spaces", response_model=APIResponse[List[Dict[str, Any]]])
async def get_spaces(db: AsyncSession = Depends(get_db)):
    """전체 공간을 트리 구조로 조회합니다."""
    tree_data = await SpaceService.get_space_tree(db)
    return APIResponse(
        success=True,
        code=200,
        message="공간 트리 조회에 성공했습니다.",
        data=tree_data,
    )


@router.post(
    "/spaces",
    response_model=APIResponse[SpaceRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_space(
    space_in: SpaceCreate,
    db: AsyncSession = Depends(get_db),
):
    """신규 공간을 생성합니다."""
    new_space = await SpaceService.create_space(db, obj_in=space_in)
    return APIResponse(
        success=True,
        code=201,
        message="공간이 성공적으로 생성되었습니다.",
        data=new_space,
    )


@router.patch("/spaces/{space_id}", response_model=APIResponse[SpaceRead])
async def update_space(
    space_id: int,
    space_in: SpaceUpdate,
    db: AsyncSession = Depends(get_db),
):
    """공간 정보를 수정합니다. (순환 참조 방지 적용)"""
    updated_space = await SpaceService.update_space(
        db, space_id=space_id, obj_in=space_in
    )
    return APIResponse(
        success=True,
        code=200,
        message="공간 정보가 성공적으로 수정되었습니다.",
        data=updated_space,
    )


# --------------------------------------------------------
# [Facility] 설비 API
# --------------------------------------------------------
@router.post(
    "/facilities",
    response_model=APIResponse[FacilityRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_facility(
    facility_in: FacilityCreate,
    db: AsyncSession = Depends(get_db),
):
    """신규 설비를 등록합니다."""
    new_facility = await FacilityService.create_facility(db, obj_in=facility_in)
    return APIResponse(
        success=True,
        code=201,
        message="설비가 성공적으로 등록되었습니다.",
        data=new_facility,
    )
