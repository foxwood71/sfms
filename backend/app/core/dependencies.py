"""시스템 전역에서 사용되는 FastAPI 의존성(Depends)을 정의하는 모듈입니다."""

from collections.abc import AsyncGenerator, Callable
from typing import Annotated

from fastapi import Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.codes import ErrorCode
from app.core.database import AsyncSessionLocal
from app.core.exceptions import ForbiddenException, UnauthorizedException
from app.core.security import is_token_blacklisted, oauth2_scheme, verify_token
from app.domains.usr.models import User

from . import DOMAIN


async def get_db() -> AsyncGenerator[AsyncSession]:
    """비동기 데이터베이스 세션을 생성하고 반환합니다."""
    async with AsyncSessionLocal() as session:
        yield session


async def get_current_user(
    db: Annotated[AsyncSession, Depends(get_db)],
    token: Annotated[str, Depends(oauth2_scheme)],
) -> User:
    """현재 요청의 토큰을 검증하고 사용자 객체를 반환합니다."""
    payload = verify_token(token)
    if not payload:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_INVALID)

    if await is_token_blacklisted(token):
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_BLACKLISTED)

    user_id_str: str = payload.get("sub", "")
    if not user_id_str:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.TOKEN_INVALID)

    # User 모델의 .is_superuser 프로퍼티 및 권한 체크를 위해 roles를 즉시 로드합니다.
    stmt = select(User).where(User.id == int(user_id_str)).options(selectinload(User.roles))
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.USER_NOT_IDENTIFIED)

    if not user.is_active:
        raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.ACCOUNT_DISABLED)

    return user


async def get_current_active_superuser(
    current_user: Annotated[User, Depends(get_current_user)],
) -> User:
    """현재 사용자가 슈퍼 관리자(SUPER_ADMIN)인지 확인합니다."""
    if not current_user.is_superuser:
        raise ForbiddenException(
            domain="SYS",
            error_code=ErrorCode.ACCESS_DENIED,
            message="슈퍼 관리자 권한이 필요합니다.",
        )
    return current_user


def check_domain_admin(required_domain: str) -> Callable:
    """특정 도메인의 분임 관리 권한이 있는지 확인하는 의존성 주입 팩토리 함수입니다.

    슈퍼 관리자(SUPER_ADMIN)는 모든 도메인 권한을 자동으로 가집니다.

    Args:
        required_domain (str): 확인할 도메인 코드 (예: 'FAC', 'USR', 'SYS')

    Returns:
        Callable: FastAPI Depends에서 사용할 비동기 권한 체크 함수

    """

    async def _check_permission(
        current_user: Annotated[User, Depends(get_current_user)],
    ) -> User:
        # 1. 슈퍼 관리자 확인 (초월 권한)
        if current_user.is_superuser:
            return current_user

        # 2. 역할(Role) 내 권한 매트릭스 확인
        # role.permissions 예시: {"FAC": ["READ", "MANAGE"], "USR": ["READ"]}
        for role in current_user.roles:
            domain_perms = role.permissions.get(required_domain, [])
            if "MANAGE" in domain_perms or "ADMIN" in domain_perms:
                return current_user

        raise ForbiddenException(
            domain=required_domain,
            error_code=ErrorCode.ACCESS_DENIED,
            message=f"{required_domain} 도메인에 대한 관리자 권한이 없습니다.",
        )

    return _check_permission
