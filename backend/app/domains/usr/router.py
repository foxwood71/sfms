"""사용자(User) 및 조직(Organization) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다.

이 모듈은 조직 계층 구조 관리, 사용자 계정 생성/수정/삭제, 비밀번호 변경,
그리고 프로필 이미지 업로드 등을 위한 RESTful API를 제공합니다.
"""

from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Query, Request, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode, SuccessCode
from app.core.dependencies import check_domain_admin, get_current_user, get_db
from app.core.exceptions import BadRequestException
from app.core.responses import APIResponse
from app.domains.usr.models import User
from app.domains.usr.schemas import (
    OrgCreate,
    OrgRead,
    OrgUpdate,
    UserCreate,
    UserPasswordUpdate,
    UserRead,
    UserUpdate,
)
from app.domains.usr.services import OrgService, UserService

from . import DOMAIN

router = APIRouter(prefix="/usr", tags=["사용자 및 조직 관리 (USR)"])


# --------------------------------------------------------
# [Organization] 조직(부서) API
# --------------------------------------------------------


@router.get(
    "/organizations",
    response_model=APIResponse[list[OrgRead]],
)
async def get_organizations(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """활성화된 전체 조직도(Tree)를 계층 구조로 조회합니다.

    각 조직 객체는 'children' 필드에 하위 조직 목록을 포함하며, 
    비동기 환경의 안정성을 위해 모든 데이터가 사전에 직렬화되어 반환됩니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 인증된 사용자 정보

    Returns:
        APIResponse[list[OrgRead]]: 최상위 부서부터 시작하는 트리 구조 리스트
    """
    tree_data = await OrgService.get_organizations(db)
    return APIResponse(domain=DOMAIN, data=tree_data)


@router.post(
    "/organizations",
    response_model=APIResponse[OrgRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_organization(
    org_in: OrgCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(check_domain_admin("USR"))],
):
    """신규 조직(부서)을 생성합니다.

    이 API는 USR 도메인 관리 권한이 있는 사용자만 호출 가능합니다.
    조직 코드는 대문자로 자동 변환되며, 상위 부서 ID의 유효성을 검증합니다.

    Args:
        org_in (OrgCreate): 신규 부서 등록 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[OrgRead]: 생성 완료된 부서 정보
    """
    new_org = await OrgService.create_organizations(db, obj_in=org_in, actor_id=current_user.id)
    return APIResponse(domain=DOMAIN, data=new_org, success_code=SuccessCode.SUCCESS_CREATED)


@router.get(
    "/organizations/{org_id}",
    response_model=APIResponse[OrgRead],
)
async def get_organization(
    org_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 조직의 정보를 고유 ID로 조회합니다.

    Args:
        org_id (int): 조회할 조직 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 인증된 사용자 정보

    Returns:
        APIResponse[OrgRead]: 조직 상세 정보
    """
    org = await OrgService.get_organization(db, org_id=org_id)
    return APIResponse(domain=DOMAIN, data=org)


@router.patch(
    "/organizations/{org_id}",
    response_model=APIResponse[OrgRead],
)
async def update_organization(
    org_id: int,
    org_in: OrgUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(check_domain_admin("USR"))],
):
    """기존 조직(부서)의 정보를 수정합니다.

    이 API는 관리자 전용입니다. 부서명, 정렬 순서 등을 변경할 수 있으며, 
    상위 부서(`parent_id`) 수정 시 순환 참조 발생 여부를 체크합니다.

    Args:
        org_id (int): 수정할 대상 조직 ID
        org_in (OrgUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[OrgRead]: 수정 완료된 부서 정보
    """
    updated_org = await OrgService.update_organizations(
        db, org_id=org_id, obj_in=org_in, actor_id=current_user.id
    )
    return APIResponse(domain=DOMAIN, data=updated_org, success_code=SuccessCode.SUCCESS_UPDATED)


@router.delete(
    "/organizations/{org_id}",
    response_model=APIResponse[None],
)
async def delete_organization(
    org_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(check_domain_admin("USR"))],
):
    """특정 조직을 물리적으로 삭제합니다. 

    하위 부서가 있거나 소속된 사용자가 한 명이라도 존재하는 경우 삭제가 거부됩니다.

    Args:
        org_id (int): 삭제할 대상 조직 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 삭제 성공 응답
    """
    await OrgService.delete_organizations(db, org_id=org_id)
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED)


# --------------------------------------------------------
# [User] 사용자 API
# --------------------------------------------------------


@router.get(
    "",
    response_model=APIResponse[list[UserRead]],
)
async def get_users(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    sort: Annotated[str | None, Query(description="정렬 필드 (name, created_at)")] = None,
    keyword: Annotated[str | None, Query(description="검색어 (성명, ID, 사번)")] = None,
    page: Annotated[int, Query(ge=1, description="페이지 번호")] = 1,
    size: Annotated[int, Query(ge=1, le=100, description="페이지 크기")] = 20,
    org_id: Annotated[int | None, Query(description="특정 조직 ID")] = None,
    include_children: Annotated[bool, Query(description="하위 조직 포함 여부")] = False,
    is_active: Annotated[bool | None, Query(description="활성/비활성 필터")] = None,
):
    """사용자 목록을 조회하고 다양한 조건으로 검색합니다.

    부서 필터(`org_id`) 적용 시 `include_children=true`를 설정하면 하위 조직원까지 포함합니다.
    성명, 사번, 로그인 ID에 대한 통합 검색(Keyword Search)을 지원합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보
        sort (str | None, optional): 정렬 기준. 기본값은 None.
        keyword (str | None, optional): 통합 검색어. 기본값은 None.
        page (int, optional): 페이지 번호. 기본값은 1.
        size (int, optional): 조회 수 제한. 기본값은 20.
        org_id (int | None, optional): 부서 필터 ID. 기본값은 None.
        include_children (bool, optional): 하위 부서 포함 여부. 기본값은 False.
        is_active (bool | None, optional): 계정 상태 필터. 기본값은 None.

    Returns:
        APIResponse[list[UserRead]]: 페이징 처리된 사용자 목록
    """
    users = await UserService.get_users(
        db=db,
        page=page,
        size=size,
        sort=sort,
        org_id=org_id,
        include_children=include_children,
        keyword=keyword,
        is_active=is_active,
    )
    return APIResponse(domain=DOMAIN, data=users)


@router.post(
    "/users",
    response_model=APIResponse[UserRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_user(
    user_in: UserCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(check_domain_admin("USR"))],
):
    """신규 사용자 계정을 등록합니다.

    이 API는 관리자만 호출 가능합니다. 로그인 ID, 사번, 이메일의 중복 여부를 
    사전에 검증하며 초기 비밀번호를 안전하게 해싱하여 저장합니다.

    Args:
        user_in (UserCreate): 사용자 생성 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[UserRead]: 생성 완료된 사용자 정보
    """
    new_user = await UserService.create_user(db, obj_in=user_in, actor_id=current_user.id)
    return APIResponse(domain=DOMAIN, data=new_user, success_code=SuccessCode.SUCCESS_CREATED)


@router.get(
    "/{user_id}",
    response_model=APIResponse[UserRead],
)
async def get_user(
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 사용자의 프로필 및 상세 정보를 조회합니다.

    Args:
        user_id (int): 조회할 대상 사용자 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[UserRead]: 사용자 상세 정보
    """
    user = await UserService.get_user(db, user_id=user_id)
    return APIResponse(domain=DOMAIN, data=user)


@router.patch("/{user_id}", response_model=APIResponse[UserRead])
async def update_user(
    user_id: int,
    user_in: UserUpdate,
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """사용자의 정보를 수정합니다.

    보안 정책:
    1. 본인 정보 수정 또는 관리자(Superuser) 권한 필요.
    2. 일반 사용자는 자신의 부서(`org_id`) 및 계정 상태(`is_active`)를 수정할 수 없습니다. 
       (전달된 경우에도 서비스 레이어에서 무시됨)

    Args:
        user_id (int): 수정할 대상 사용자 ID
        user_in (UserUpdate): 업데이트할 필드 정보
        request (Request): 요청 객체 (IP/User-Agent 추출용)
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[UserRead]: 수정 완료된 사용자 프로필 정보
    """
    # 보안 체크: 본인이 아니면서 관리자도 아닌 경우 차단
    if user_id != current_user.id and not current_user.is_superuser:
        raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED)

    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("User-Agent", "unknown")

    updated_user = await UserService.update_user(
        db=db,
        user_id=user_id,
        user_in=user_in,
        actor_id=current_user.id,
        actor_is_admin=current_user.is_superuser,
        ip=client_ip,
        user_agent=user_agent,
    )
    return APIResponse(domain=DOMAIN, data=updated_user, success_code=SuccessCode.SUCCESS_UPDATED)


@router.put(
    "/{user_id}/password",
    response_model=APIResponse[None],
)
async def change_password(
    user_id: int,
    password_in: UserPasswordUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """사용자의 비밀번호를 변경합니다.

    본인이 직접 변경할 경우 기존 비밀번호 확인이 필수입니다.
    관리자는 본인 확인 없이 강제 변경이 가능하나 이 과정은 시스템에 기록됩니다.

    Args:
        user_id (int): 비밀번호를 변경할 사용자 ID
        password_in (UserPasswordUpdate): 현재/신규 비밀번호 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[None]: 변경 성공 응답
    """
    # 보안 체크: 본인이 아니면서 관리자도 아닌 경우 차단
    if user_id != current_user.id and not current_user.is_superuser:
        raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED)

    await UserService.change_password(
        db=db, user_id=user_id, password_in=password_in, current_user=current_user
    )
    return APIResponse(domain=DOMAIN, data=None)


@router.delete("/{user_id}", response_model=APIResponse[None])
async def delete_user(
    user_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(check_domain_admin("USR"))],
):
    """사용자 계정을 삭제(비활성화) 처리합니다.

    참조 무결성을 위해 물리적 삭제 대신 `is_active=False`로 변경하는 
    논리적 삭제(소프트 삭제)를 수행합니다.

    Args:
        user_id (int): 비활성화할 대상 사용자 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 비활성화 성공 응답
    """
    await UserService.delete_user(db, user_id=user_id, actor_id=current_user.id)
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED)


@router.post("/{user_id}/profile-image", response_model=APIResponse[UserRead])
async def upload_profile_image(
    user_id: int,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """사용자의 프로필 이미지를 업로드하고 연동합니다.

    업로드된 파일은 CMM 도메인의 통합 파일 스토리지에 보관됩니다.
    기존에 등록된 이미지가 있을 경우 자동으로 삭제 처리됩니다.

    Args:
        user_id (int): 대상 사용자 ID
        file (UploadFile): 업로드할 이미지 파일
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[UserRead]: 이미지 정보가 갱신된 사용자 정보
    """
    # 보안 체크: 본인이 아니면서 관리자도 아닌 경우 차단
    if user_id != current_user.id and not current_user.is_superuser:
        raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED)

    updated_user = await UserService.upload_profile_image(
        db=db, user_id=user_id, file=file, actor_id=current_user.id
    )
    return APIResponse(domain=DOMAIN, data=updated_user, success_code=SuccessCode.SUCCESS)
