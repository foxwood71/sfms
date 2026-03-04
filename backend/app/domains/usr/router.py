"""사용자(User) 및 조직(Organization) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다."""

from typing import Any, Dict, List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.domains.usr.schemas import OrgCreate, OrgRead, OrgUpdate, UserCreate, UserRead
from app.domains.usr.services import OrgService, UserService

# TODO: APIResponse가 main.py에 있으면 순환 참조가 발생할 수 있으므로,
# 추후 app/core/responses.py 같은 별도 파일로 분리하는 것을 권장합니다!
from app.main import APIResponse

router = APIRouter(prefix="/usr", tags=["사용자 및 조직 관리 (USR)"])


# --------------------------------------------------------
# [Organization] 조직(부서) API
# --------------------------------------------------------
@router.get("/organizations", response_model=APIResponse[List[Dict[str, Any]]])
async def get_organizations(db: AsyncSession = Depends(get_db)):
    """
    활성화된 전체 조직도를 조회합니다.

    기본적으로 계층형 트리(Tree) 구조의 JSON 배열을 반환합니다.
    """
    tree_data = await OrgService.get_org_tree(db)
    return APIResponse(
        success=True,
        code=200,
        message="조직도 조회에 성공했습니다.",
        data=tree_data,
    )


@router.post(
    "/organizations",
    response_model=APIResponse[OrgRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_organization(
    org_in: OrgCreate,
    db: AsyncSession = Depends(get_db),
):
    """신규 조직(부서)을 생성합니다."""
    new_org = await OrgService.create_org(db, obj_in=org_in)
    return APIResponse(
        success=True,
        code=201,
        message="조직이 성공적으로 생성되었습니다.",
        data=new_org,
    )


@router.patch("/organizations/{org_id}", response_model=APIResponse[OrgRead])
async def update_organization(
    org_id: int,
    org_in: OrgUpdate,
    db: AsyncSession = Depends(get_db),
):
    """
    기존 조직의 정보를 수정합니다.

    상위 부서(parent_id) 변경 시 순환 참조(Circular Reference) 여부를 자동으로 검증합니다.
    """
    updated_org = await OrgService.update_org(db, org_id=org_id, obj_in=org_in)
    return APIResponse(
        success=True,
        code=200,
        message="조직 정보가 성공적으로 수정되었습니다.",
        data=updated_org,
    )


@router.delete("/organizations/{org_id}", response_model=APIResponse[None])
async def delete_organization(
    org_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    조직을 삭제합니다.

    하위 부서나 소속된 사용자가 존재할 경우 삭제가 차단됩니다. (409 Conflict)
    """
    await OrgService.delete_org(db, org_id=org_id)
    return APIResponse(
        success=True,
        code=200,
        message="조직이 성공적으로 삭제되었습니다.",
        data=None,
    )


# --------------------------------------------------------
# [User] 사용자 API
# --------------------------------------------------------
@router.post(
    "/users", response_model=APIResponse[UserRead], status_code=status.HTTP_201_CREATED
)
async def create_user(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    """
    신규 사용자(사원)를 등록합니다.

    로그인 ID, 사번, 이메일의 중복 여부를 검증합니다.
    """
    new_user = await UserService.create_user(db, obj_in=user_in)
    return APIResponse(
        success=True,
        code=201,
        message="사용자가 성공적으로 등록되었습니다.",
        data=new_user,
    )


@router.delete("/users/{user_id}", response_model=APIResponse[None])
async def delete_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    사용자를 삭제(비활성화) 처리합니다.

    물리적 삭제(Hard Delete) 대신 논리적 삭제(Soft Delete)를 수행하여 데이터 이력을 보존합니다.
    """
    await UserService.delete_user(db, user_id=user_id)
    return APIResponse(
        success=True,
        code=200,
        message="사용자가 성공적으로 비활성화(퇴사 처리) 되었습니다.",
        data=None,
    )
