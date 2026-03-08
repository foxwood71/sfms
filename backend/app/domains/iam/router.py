"""인증 및 권한 관리(IAM) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다.

이 모듈은 사용자 인증(로그인, 토큰 갱신, 로그아웃), 역할(Role) 관리,
그리고 사용자별 역할 부여를 위한 RESTful API를 제공합니다.
"""

import time
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode, SuccessCode
from app.core.config import settings
from app.core.dependencies import get_current_active_superuser, get_current_user, get_db
from app.core.exceptions import BadRequestException, UnauthorizedException
from app.core.responses import APIResponse
from app.core.security import (
    add_token_to_blacklist,
    create_access_token,
    create_refresh_token,
    is_token_blacklisted,
    oauth2_scheme,
    verify_token,
)
from app.domains.iam.schemas import (
    LoginRequest,
    RoleCreate,
    RoleRead,
    RoleUpdate,
    Token,
    UserRoleUpdate,
)
from app.domains.iam.services import (
    AuthService,
    PermissionService,
    RoleService,
    UserRoleService,
)
from app.domains.usr.models import User
from app.domains.usr.schemas import UserRead

from . import DOMAIN

auth_router = APIRouter(prefix="/auth", tags=["인증 (Auth)"])


@auth_router.post("/login", response_model=APIResponse[Token])
async def login(
    request: Request,
    login_in: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """사용자 로그인을 처리하고 새로운 JWT 토큰 세트를 발급합니다.

    아이디와 비밀번호가 일치하면 Access Token과 Refresh Token을 반환합니다.
    성공적인 로그인 이벤트는 시스템 감사 로그에 기록됩니다.

    Args:
        request (Request): FastAPI 요청 객체 (IP 및 User-Agent 추출용)
        login_in (LoginRequest): 로그인 아이디 및 패스워드 정보
        db (AsyncSession): 데이터베이스 비동기 세션

    Returns:
        APIResponse[Token]: 발급된 토큰 정보 및 만료 시간
    """
    user_agent = request.headers.get("User-Agent", "unknown")
    client_ip = request.client.host if request.client else "unknown"

    user = await AuthService.authenticate_user(db, login_in=login_in, ip=client_ip, user_agent=user_agent)

    access_token = create_access_token(subject=str(user.id))
    refresh_token = create_refresh_token(subject=str(user.id))

    token_data = Token(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        token_type="bearer",
    )

    return APIResponse(domain=DOMAIN, data=token_data, success_code=SuccessCode.LOGIN_SUCCESS)


@auth_router.post("/refresh", response_model=APIResponse[Token])
async def refresh_token(refresh_in: dict[str, str]):
    """만료된 Access Token을 Refresh Token을 사용하여 재발급합니다.

    Refresh Token Rotation(RTR) 정책에 따라 기존에 사용된 리프레시 토큰은 블랙리스트에 등록되어 무효화되며,
    보안 강화를 위해 매 갱신 시 새로운 리프레시 토큰이 함께 발급됩니다.

    Args:
        refresh_in (dict[str, str]): 'refresh_token' 필드를 포함한 JSON 바디

    Returns:
        APIResponse[Token]: 새로 발급된 토큰 세트

    Raises:
        UnauthorizedException: 리프레시 토큰이 누락되었거나 변조/만료되었을 때 발생
    """
    token = refresh_in.get("refresh_token")
    if not token:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.REFRESH_TOKEN_REQUIRED)

    if await is_token_blacklisted(token):
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_BLACKLISTED)

    payload = verify_token(token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_INVALID)

    user_id = payload.get("sub")
    await add_token_to_blacklist(token, expire=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400)

    new_access = create_access_token(subject=str(user_id))
    new_refresh = create_refresh_token(subject=str(user_id))

    token_data = Token(
        access_token=new_access,
        refresh_token=new_refresh,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        token_type="bearer",
    )

    return APIResponse(domain=DOMAIN, data=token_data, success_code=SuccessCode.TOKEN_REFRESH_SUCCESS)


@auth_router.get("/me", response_model=APIResponse[UserRead])
async def get_my_info(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """현재 로그인된 사용자의 상세 프로필 정보를 조회합니다.

    Args:
        current_user (User): 인증 필터를 통해 획득한 현재 사용자 모델

    Returns:
        APIResponse[UserRead]: 사용자 프로필 및 소속 부서 정보
    """
    return APIResponse(domain=DOMAIN, data=current_user)


@auth_router.post("/logout", response_model=APIResponse[None])
async def logout(
    token: Annotated[str, Depends(oauth2_scheme)],
):
    """사용자 로그아웃을 수행하고 현재 토큰을 블랙리스트에 등록합니다.

    블랙리스트에 등록된 토큰은 만료 전이라도 시스템 접근이 즉시 차단됩니다.

    Args:
        token (str): 현재 요청에 사용된 OAuth2 Bearer 토큰

    Returns:
        APIResponse[None]: 로그아웃 성공 응답
    """
    payload = verify_token(token)
    remain_expire = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60

    if payload:
        exp = payload.get("exp")
        if exp:
            remain_expire = exp - int(time.time())

    if remain_expire > 0:
        await add_token_to_blacklist(token, expire=remain_expire)

    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.LOGOUT_SUCCESS)


role_router = APIRouter(prefix="/roles", tags=["권한 관리 (Roles)"])


@role_router.get("", response_model=APIResponse[list[RoleRead]])
async def get_roles(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    keyword: str | None = None,
    page: int = 1,
    size: int = 20,
):
    """시스템에 정의된 역할 목록을 조회합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보
        keyword (str | None, optional): 역할명 또는 코드 검색 키워드. 기본값은 None.
        page (int, optional): 페이지 번호. 기본값은 1.
        size (int, optional): 페이지 크기. 기본값은 20.

    Returns:
        APIResponse[list[RoleRead]]: 역할 정보 리스트
    """
    roles = await RoleService.get_roles(db, keyword, page, size)
    return APIResponse(domain=DOMAIN, data=roles)


@role_router.get("/{role_id}", response_model=APIResponse[RoleRead])
async def get_role(
    role_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 역할의 상세 정보와 설정된 권한 매트릭스를 조회합니다.

    Args:
        role_id (int): 조회할 역할의 고유 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[RoleRead]: 역할 상세 정보
    """
    role = await RoleService.get_role(db, role_id)
    return APIResponse(domain=DOMAIN, data=role)


@role_router.post("", response_model=APIResponse[RoleRead], status_code=status.HTTP_201_CREATED)
async def create_role(
    role_in: RoleCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """새로운 시스템 역할을 생성합니다.

    이 API는 시스템 최고 관리자만 호출 가능합니다.

    Args:
        role_in (RoleCreate): 역할 생성 정보 (코드, 명칭, 권한 리스트 등)
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[RoleRead]: 생성 완료된 역할 정보
    """
    new_role = await RoleService.create_role(db, role_in, actor_id=current_admin.id)
    return APIResponse(domain=DOMAIN, data=new_role, success_code=SuccessCode.ROLE_CREATED)


@role_router.patch("/{role_id}", response_model=APIResponse[RoleRead])
async def update_role(
    role_id: int,
    role_in: RoleUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """기존 역할 정보를 수정합니다.

    시스템 필수 역할의 경우 식별 코드 수정은 차단되며, 명칭과 권한만 수정 가능합니다.

    Args:
        role_id (int): 수정할 대상 역할 ID
        role_in (RoleUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[RoleRead]: 수정 완료된 역할 정보
    """
    updated_role = await RoleService.update_role(db, role_id, role_in, actor_id=current_admin.id)
    return APIResponse(domain=DOMAIN, data=updated_role, success_code=SuccessCode.ROLE_UPDATED)


@role_router.delete("/{role_id}", response_model=APIResponse[None])
async def delete_role(
    role_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """특정 역할을 영구 삭제합니다. 사용 중인 역할은 삭제할 수 없습니다.

    Args:
        role_id (int): 삭제할 역할 고유 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 삭제 성공 응답
    """
    await RoleService.delete_role(db, role_id)
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.ROLE_DELETED)


@role_router.put("/users/{user_id}/roles", response_model=APIResponse[None])
async def assign_user_roles(
    user_id: int,
    assignment_in: UserRoleUpdate,
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """사용자에게 특정 역할 목록을 일괄 할당합니다.

    이 API는 'Full Replace' 방식으로 작동하며, 전달된 목록으로 기존 권한을 완전히 대체합니다.
    작업 성공 시 Redis에 저장된 해당 사용자의 권한 캐시가 초기화됩니다.

    Args:
        user_id (int): 대상 사용자 ID
        assignment_in (UserRoleUpdate): 할당할 역할 ID 리스트 정보
        request (Request): 요청 객체
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 할당 성공 응답
    """
    if user_id != assignment_in.user_id:
        raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.ID_MISMATCH)

    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("User-Agent", "unknown")

    await UserRoleService.assign_roles_to_user(
        db,
        user_id=user_id,
        role_ids=assignment_in.role_ids,
        actor_id=current_admin.id,
        ip=client_ip,
        user_agent=user_agent,
    )
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.USER_ROLE_ASSIGNED)


@role_router.get("/permissions/resources", response_model=APIResponse[dict[str, Any]])
async def get_permission_resources(
    current_user: Annotated[User, Depends(get_current_user)],
):
    """프론트엔드 권한 설정 UI 구성을 위한 리소스 및 액션 메타데이터 목록을 조회합니다.

    Args:
        current_user (User): 현재 요청 사용자 정보

    Returns:
        APIResponse[dict[str, Any]]: 리소스별 액션 매트릭스 데이터
    """
    resources = await PermissionService.get_permission_resources()
    return APIResponse(domain=DOMAIN, data=resources)
