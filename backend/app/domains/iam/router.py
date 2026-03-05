"""
인증 및 권한 관리(IAM)의 라우터 엔드포인트를 정의합니다.
모든 함수는 명세서 2.1~2.4 보안 정책을 준수하며 Pylance/Ruff 가이드를 반영합니다.
"""

import time
from typing import Dict, List, Optional

from fastapi import APIRouter, Depends, Header, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import UnauthorizedException
from app.core.schemas import APIResponse
from app.core.security import (
    add_token_to_blacklist,
    create_access_token,
    create_refresh_token,
    get_current_user,
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
from app.domains.iam.services import AuthService, RoleService, UserRoleService
from app.domains.usr.schemas import UserRead
from app.domains.usr.services import UserService

# --------------------------------------------------------
# [Auth] 라우터 설정
# --------------------------------------------------------
auth_router = APIRouter(prefix="/auth", tags=["인증 (Auth)"])


@auth_router.post("/login", response_model=APIResponse[Token])
async def login(
    request: Request,
    login_in: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    2.1 사용자 로그인 처리
        실제 JWT 토큰(Access/Refresh)을 발급합니다.
    """
    # 0. 헤더에서 'User-Agent' 정보를 추출합니다. (없으면 "unknown")
    user_agent = request.headers.get("User-Agent", "unknown")

    # 1. DB에서 사용자 ID/비밀번호 검증
    client_ip = request.client.host if request.client else "unknown"
    user = await AuthService.authenticate_user(
        db, login_in=login_in, ip=client_ip, user_agent=user_agent
    )

    # 2. app.core.security 모듈을 사용하여 진짜 토큰 발급!
    access_token = create_access_token(subject=str(user.id))
    refresh_token = create_refresh_token(subject=str(user.id))

    # 3. 응답 데이터 조립 (만료 시간은 '분'을 '초'로 변환)
    token_data = Token(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return APIResponse(
        success=True,
        code=200,
        message="로그인에 성공했습니다.",
        data=token_data,
    )


# Refresh Token Rotation(RTR) 적용
@auth_router.post("/refresh", response_model=APIResponse[Token])
async def refresh_token(refresh_in: Dict[str, str]):
    """
    2.2 토큰 갱신(Refresh Token)
        기존 리프레시 토큰을 검증하고 새로운 액세스 및 리프레시 토큰을 발급합니다.
    """
    token = refresh_in.get("refresh_token")

    # Pylance 에러 해결: token이 None인지 먼저 체크하여 str임을 보장합니다.
    if not token:
        raise UnauthorizedException(message="리프레시 토큰이 누락되었습니다.")

    # 이제 token은 무조건 str이므로 Pylance가 화내지 않아요! n.n
    if await is_token_blacklisted(token):
        raise UnauthorizedException(message="이미 사용된 리프레시 토큰입니다.")

    payload = verify_token(token)
    if not payload or payload.get("type") != "refresh":
        raise UnauthorizedException(message="유효하지 않은 리프레시 토큰입니다.")

    user_id = payload.get("sub")

    # Rotation 정책: 기존 토큰 무효화 및 새 토큰 발급
    await add_token_to_blacklist(
        token, expire=settings.REFRESH_TOKEN_EXPIRE_DAYS * 86400
    )
    # 신규 토큰 발급 로직
    new_access = create_access_token(subject=str(user_id))
    new_refresh = create_refresh_token(subject=str(user_id))

    return APIResponse(
        success=True,
        code=200,
        message="Ok",
        data=Token(
            access_token=new_access,
            refresh_token=new_refresh,
            expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        ),
    )


@auth_router.get("/me", response_model=APIResponse[UserRead])
async def get_my_info(
    token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)
):
    """
    2.3 내 정보 조회
        현재 로그인한 사용자의 상세 정보를 조회합니다.
    """
    payload = verify_token(token)
    if not payload:
        raise UnauthorizedException(message="인증 정보가 유효하지 않습니다.")

    # sub 값이 있는지 명확히 확인
    sub_val = payload.get("sub")
    if sub_val is None:
        raise UnauthorizedException(message="사용자 식별 정보가 없습니다.")

    # 안전하게 int로 변환 후 호출
    user = await UserService.get_user(db, user_id=int(sub_val))

    return APIResponse(success=True, code=200, message="Ok", data=user)


@auth_router.post("/logout", response_model=APIResponse[None])
async def logout(
    token: str = Depends(oauth2_scheme),
):
    """
    2.4 사용자 로그아웃
        JWT 토큰에서 만료 시간(exp)을 추출하여 실제 남은 시간만큼만
        Redis 블랙리스트에 등록하여 무효화합니다.
    """
    payload = verify_token(token)

    # 기본 만료 시간 설정 (토큰 해독 실패 시를 대비한 예비값)
    remain_expire = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60

    if payload:
        exp = payload.get("exp")
        if exp:
            # 현재 유닉스 타임스탬프와 비교하여 남은 초(seconds) 계산
            current_time = int(time.time())
            remain_expire = exp - current_time

    # 남은 시간이 있는 경우에만 블랙리스트에 추가 (이미 만료된 건 패스)
    if remain_expire > 0:
        await add_token_to_blacklist(token, expire=remain_expire)

    return APIResponse(
        success=True,
        code=200,
        message="로그아웃 되었습니다.",
        data=None,
    )


# --------------------------------------------------------
# [Roles] 라우터 설정
# --------------------------------------------------------
role_router = APIRouter(prefix="/roles", tags=["권한 관리 (Roles)"])


@role_router.get("", response_model=APIResponse[List[RoleRead]])
async def get_roles(
    keyword: Optional[str] = None,
    page: int = 1,
    size: int = 20,
    db: AsyncSession = Depends(get_db),
):
    """3.1: 역할 목록을 조회합니다. (검색/페이징 포함)"""
    roles = await RoleService.get_roles(db, keyword, page, size)
    return APIResponse(success=True, code=200, message="Ok", data=roles)


@role_router.get("/{role_id}", response_model=APIResponse[RoleRead])
async def get_role(role_id: int, db: AsyncSession = Depends(get_db)):
    """3.2: 특정 역할의 상세 정보를 조회합니다."""
    role = await RoleService.get_role(db, role_id)
    return APIResponse(success=True, code=200, message="Ok", data=role)


@role_router.post(
    "", response_model=APIResponse[RoleRead], status_code=status.HTTP_201_CREATED
)
async def create_role(role_in: RoleCreate, db: AsyncSession = Depends(get_db)):
    """3.3: 신규 역할을 생성합니다. (코드 중복 체크)"""
    new_role = await RoleService.create_role(db, role_in)
    return APIResponse(success=True, code=201, message="Created", data=new_role)


@role_router.patch("/{role_id}", response_model=APIResponse[RoleRead])
async def update_role(
    role_id: int, role_in: RoleUpdate, db: AsyncSession = Depends(get_db)
):
    """3.4: 역할 정보를 수정합니다. (시스템 역할 보호)"""
    updated_role = await RoleService.update_role(db, role_id, role_in)
    return APIResponse(success=True, code=200, message="Updated", data=updated_role)


@role_router.delete("/{role_id}", response_model=APIResponse[None])
async def delete_role(role_id: int, db: AsyncSession = Depends(get_db)):
    """3.5: 역할을 삭제합니다. (시스템/사용 중 체크)"""
    await RoleService.delete_role(db, role_id)
    return APIResponse(success=True, code=200, message="Deleted", data=None)


@role_router.put("/users/{user_id}/roles", response_model=APIResponse[None])
async def assign_user_roles(
    user_id: int,
    assignment_in: UserRoleUpdate,
    request: Request,  # IP 추출을 위해 추가
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),  # 수정자(actor_id) 정보를 위해 추가
):
    """
    사용자에게 역할을 할당합니다. (Full Replace 방식)

    기존 권한을 모두 지우고 새롭게 전달받은 권한 ID 목록으로 덮어씌웁니다.
    """
    # 1. URL의 ID와 페이로드 ID 검증 (오빠가 짠 안전장치!)
    if user_id != assignment_in.user_id:
        return APIResponse(
            success=False,
            code=4000,
            message="URL의 사용자 ID와 페이로드의 사용자 ID가 일치하지 않습니다.",
            data=None,
        )

    # 2. 클라이언트 IP 추출
    client_ip = request.client.host if request.client else "unknown"

    # 3. 헤더에서 'User-Agent' 정보를 추출합니다. (없으면 "unknown")
    user_agent = request.headers.get("User-Agent", "unknown")

    await UserRoleService.assign_roles_to_user(
        db,
        user_id=user_id,
        role_ids=assignment_in.role_ids,
        ip=client_ip,
        user_agent=user_agent,
        actor_id=current_user.id,
    )
    return APIResponse(
        success=True,
        code=200,
        message="사용자 권한이 성공적으로 업데이트되었습니다.",
        data=None,
    )
