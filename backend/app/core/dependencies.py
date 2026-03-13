"""시스템 전역에서 사용되는 종속성 주입(Dependency Injection) 및 권한 검증 모듈입니다.

이 모듈은 FastAPI의 Depends를 통해 각 엔드포인트에서 공통적으로 필요한
데이터베이스 세션, 현재 로그인 사용자 정보, 도메인별 관리자 권한 등을 검증합니다.
모든 함수는 Google Style Docstring을 준수합니다.
"""

from collections.abc import AsyncGenerator
from typing import Annotated

from fastapi import Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode
from app.core.database import AsyncSessionLocal
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import oauth2_scheme, verify_token
from app.domains.usr.models import User

from . import DOMAIN


# 데이터베이스 세션 종속성
async def get_db() -> AsyncGenerator[AsyncSession]:
    """비동기 데이터베이스 세션을 생성하고 반환합니다."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def get_current_user(
    request: Request,
    db: Annotated[AsyncSession, Depends(get_db)],
    token: Annotated[str, Depends(oauth2_scheme)],
) -> User:
    payload = verify_token(token)
    if not payload:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_INVALID)

    user_id = payload.get("sub")
    if not user_id:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.USER_NOT_IDENTIFIED)

    from app.domains.usr.services import UserService
    try:
        user = await UserService.get_user(db, int(user_id))
        if user:
            return user
    except Exception:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND) from None

    raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)


async def check_superuser(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """슈퍼 관리자(Superuser) 권한을 가진 사용자인지 검증합니다.

    Args:
        current_user (User): 현재 요청 사용자

    Returns:
        User: 슈퍼 관리자 권한을 가진 사용자

    Raises:
        ForbiddenException: 슈퍼 관리자 권한이 없는 경우

    """
    if not current_user.is_superuser:
        raise ForbiddenException(domain=DOMAIN, error_code=ErrorCode.FORBIDDEN)

    return current_user


async def get_current_active_superuser(
    current_user: Annotated[User, Depends(check_superuser)],
) -> User:
    """활성화된 슈퍼 관리자 정보를 반환합니다."""
    if not current_user.is_active:
        raise ForbiddenException(domain=DOMAIN, error_code=ErrorCode.ACCOUNT_DISABLED)
    return current_user


def check_domain_admin(required_domain: str):
    """특정 도메인에 대한 관리자 권한을 가진 사용자인지 검증하는 종속성 팩토리를 생성합니다.

    Args:
        required_domain (str): 필요한 도메인 코드 (예: 'USR', 'FAC')

    Returns:
        Callable: 권한 검증 함수

    """

    async def _check_domain_admin(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        """도메인 관리자 권한 여부를 체크합니다."""
        # 슈퍼유저는 모든 도메인 통과
        if current_user.is_superuser:
            return current_user

        # 사용자 역할(Roles) 중 해당 도메인에 대한 ADMIN 권한이 있는지 체크
        is_admin = any(
            role.code.upper() in ["ADMIN", f"{required_domain}_ADMIN"]
            for role in current_user.roles
        )

        if not is_admin:
            raise ForbiddenException(domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED)

        return current_user

    return _check_domain_admin
