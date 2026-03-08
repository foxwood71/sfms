"""시설 및 공간 관리(FAC) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다."""

from typing import Annotated, Any

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import SuccessCode
from app.core.dependencies import check_domain_admin, get_current_user, get_db
from app.core.responses import APIResponse
from app.domains.fac.schemas import (
    FacilityCreate,
    FacilityRead,
    FacilityUpdate,
    SpaceCreate,
    SpaceRead,
    SpaceUpdate,
)
from app.domains.fac.services import FacilityService, SpaceService
from app.domains.usr.models import User

from . import DOMAIN

router = APIRouter(prefix="/fac", tags=["시설 및 공간 관리 (FAC)"])


# --------------------------------------------------------
# [Facility] 최상위 시설 API
# --------------------------------------------------------


@router.get("/facilities", response_model=APIResponse[list[FacilityRead]])
async def list_facilities(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """시스템에 등록된 모든 최상위 시설(사업소/처리장 등) 목록을 조회합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 인증된 사용자 정보

    Returns:
        APIResponse[list[FacilityRead]]: 시설 정보 리스트

    """
    facilities = await FacilityService.list_facilities(db)
    return APIResponse(domain=DOMAIN, data=facilities)


@router.get("/facilities/{facility_id}", response_model=APIResponse[FacilityRead])
async def get_facility(
    facility_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 시설의 상세 정보를 고유 ID로 조회합니다.

    Args:
        facility_id (int): 조회할 시설 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 인증된 사용자 정보

    Returns:
        APIResponse[FacilityRead]: 시설 상세 정보

    """
    facility = await FacilityService.get_facility(db, facility_id)
    return APIResponse(domain=DOMAIN, data=facility)


@router.post(
    "/facilities",
    response_model=APIResponse[FacilityRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_facility(
    facility_in: FacilityCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("FAC"))],
):
    """신규 최상위 시설을 등록합니다.

    이 API는 FAC 도메인 관리 권한이 있는 사용자만 호출 가능합니다.

    Args:
        facility_in (FacilityCreate): 신규 시설 등록 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[FacilityRead]: 생성 완료된 시설 정보

    """
    new_facility = await FacilityService.create_facility(
        db, obj_in=facility_in, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=new_facility, success_code=SuccessCode.SUCCESS_CREATED
    )


@router.patch("/facilities/{facility_id}", response_model=APIResponse[FacilityRead])
async def update_facility(
    facility_id: int,
    facility_in: FacilityUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("FAC"))],
):
    """기존 시설의 정보를 수정합니다.

    Args:
        facility_id (int): 수정할 대상 시설 ID
        facility_in (FacilityUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[FacilityRead]: 수정 완료된 시설 정보

    """
    updated_facility = await FacilityService.update_facility(
        db, facility_id=facility_id, obj_in=facility_in, actor_id=current_admin.id
    )
    return APIResponse(domain=DOMAIN, data=updated_facility)


# --------------------------------------------------------
# [Space] 공간 API
# --------------------------------------------------------


@router.get("/facilities/{facility_id}/spaces", response_model=APIResponse[list[Any]])
async def get_spaces(
    facility_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 시설 내부에 정의된 전체 공간을 계층적 트리 구조로 조회합니다.

    Args:
        facility_id (int): 시설 고유 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 인증된 사용자 정보

    Returns:
        APIResponse[list[Any]]: 최상위 노드부터 하위 children이 포함된 트리 구조

    """
    tree_data = await SpaceService.get_space_tree(db, facility_id=facility_id)
    return APIResponse(domain=DOMAIN, data=tree_data)


@router.post(
    "/spaces",
    response_model=APIResponse[SpaceRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_space(
    space_in: SpaceCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("FAC"))],
):
    """시설 내부에 새로운 관리 공간(건물, 층, 호실 등)을 생성합니다.

    이 API는 FAC 도메인 관리 권한이 있는 사용자만 호출 가능합니다.

    Args:
        space_in (SpaceCreate): 신규 공간 생성 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[SpaceRead]: 생성 완료된 공간 정보

    """
    new_space = await SpaceService.create_space(
        db, obj_in=space_in, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=new_space, success_code=SuccessCode.SUCCESS_CREATED
    )


@router.patch("/spaces/{space_id}", response_model=APIResponse[SpaceRead])
async def update_space(
    space_id: int,
    space_in: SpaceUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """기존 공간의 정보를 수정합니다.

    보안 정책:
    1. 시스템 관리자(Superuser) 또는 FAC 도메인 관리자는 모든 공간 수정 가능.
    2. 일반 사용자의 경우, 해당 공간의 관리 책임 부서(`org_id`)와 본인의 부서가 일치하고,
       사용자 메타데이터상 '팀장' 또는 '부서장' 직책인 경우에만 허용됩니다.

    Args:
        space_id (int): 수정할 대상 공간 ID
        space_in (SpaceUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보 (권한 검증용)

    Returns:
        APIResponse[SpaceRead]: 수정 완료된 공간 정보

    """
    updated_space = await SpaceService.update_space(
        db, space_id=space_id, obj_in=space_in, actor=current_user
    )
    return APIResponse(domain=DOMAIN, data=updated_space)
