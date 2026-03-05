"""SFMS 시스템의 보안(비밀번호 해싱 및 JWT 토큰 관리)을 담당하는 모듈입니다."""

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Union

import jwt
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import redis_client
from app.core.config import settings
from app.core.database import get_db
from app.core.exceptions import UnauthorizedException
from app.domains.usr.models import User
from app.domains.usr.services import UserService

# Bcrypt 기반의 비밀번호 해싱 컨텍스트 설정
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 시스템 전체에서 공유할 인증 스키마 (자물쇠 규격)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    평문 비밀번호와 해싱된 비밀번호를 비교하여 일치 여부를 반환합니다.

    Args:
        plain_password (str): 사용자가 입력한 비밀번호
        hashed_password (str): DB에 저장된 해시값
    """
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """
    비밀번호를 bcrypt 알고리즘으로 해싱하여 반환합니다.

    Args:
        password (str): 해싱할 평문 비밀번호
    """
    return pwd_context.hash(password)


def create_access_token(
    subject: Union[str, int], expires_delta: Optional[timedelta] = None
) -> str:
    """
    JWT Access Token을 생성합니다.

    Args:
        subject (Union[str, int]): 토큰의 주체 (일반적으로 user_id)
        expires_delta (Optional[timedelta], optional): 만료 시간 지정. 미지정 시 기본값을 사용합니다.
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode = {"exp": expire, "sub": str(subject), "type": "access"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def create_refresh_token(
    subject: Union[str, int], expires_delta: Optional[timedelta] = None
) -> str:
    """
    JWT Refresh Token을 생성합니다.

    Args:
        subject (Union[str, int]): 토큰의 주체 (일반적으로 user_id)
        expires_delta (Optional[timedelta], optional): 만료 시간 지정. 미지정 시 기본값을 사용합니다.
    """
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            days=settings.REFRESH_TOKEN_EXPIRE_DAYS
        )

    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def decode_token(token: str) -> Dict[str, Any]:
    """
    JWT 토큰을 검증하고 페이로드를 디코딩하여 반환합니다.

    만료되었거나 서명이 유효하지 않은 토큰일 경우 jwt 라이브러리의 예외가 발생합니다.
    """
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """
    JWT 토큰의 서명과 유효성을 검증하고 페이로드(내용물)를 반환합니다.

    Args:
        token (str): 검증할 JWT 토큰 문자열

    Returns:
        Optional[Dict[str, Any]]: 검증 성공 시 페이로드 딕셔너리, 실패 시 None
    """
    try:
        # 토큰 디코딩 (서명 검증 포함)
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return payload
    except InvalidTokenError:
        # 토큰이 변조되었거나, 만료되었거나, 형식이 잘못된 경우
        return None


def get_token_payload(token: str) -> Dict[str, Any]:
    """
    토큰을 검증한 후 페이로드를 반환하며, 실패 시 예외를 발생시킵니다.
    (AuthService 등에서 상세한 에러 처리가 필요할 때 사용)
    """
    payload = verify_token(token)
    if not payload:
        from app.core.exceptions import UnauthorizedException

        raise UnauthorizedException(
            message="인증 토큰이 유효하지 않거나 만료되었습니다."
        )
    return payload


async def add_token_to_blacklist(token: str, expire: int) -> None:
    """
    토큰을 Redis 블랙리스트에 추가합니다.

    Args:
        token (str): 블랙리스트에 등록할 JWT 토큰
        expire (int): 토큰의 남은 만료 시간 (초 단위)
    """
    key = f"blacklist:{token}"
    # 토큰의 남은 시간만큼만 Redis에 보관하고 자동 삭제되도록 설정
    await redis_client.setex(key, expire, "true")


async def is_token_blacklisted(token: str) -> bool:
    """
    해당 토큰이 블랙리스트에 등록되어 있는지 확인합니다.
    """
    key = f"blacklist:{token}"
    return await redis_client.exists(key) > 0


async def remove_token_from_blacklist(token: str) -> None:
    """
    필요 시 블랙리스트에서 토큰을 수동으로 제거합니다. (토큰 복구 등)
    """
    key = f"blacklist:{token}"
    await redis_client.delete(key)


async def get_current_user(
    db: AsyncSession = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> User:
    """
    현재 요청의 토큰을 검증하고 사용자 객체를 반환합니다.

    Raises:
        UnauthorizedException: 토큰이 유효하지 않거나 사용자를 찾을 수 없을 때
    """
    # 1. 토큰 복호화 및 페이로드 추출
    payload = verify_token(token)
    if not payload:
        raise UnauthorizedException(
            message="로그인이 만료되었거나 토큰이 유효하지 않습니다."
        )

    # 2. 페이로드에서 사용자 식별자(sub) 추출
    user_id_str: str = payload.get("sub", "")
    if not user_id_str:
        raise UnauthorizedException(message="토큰에 사용자 정보가 없습니다.")

    # 3. DB에서 실제 사용자 조회
    user = await UserService.get_user_by_id(db, user_id=int(user_id_str))
    if not user:
        raise UnauthorizedException(message="사용자를 찾을 수 없습니다.")

    # 4. 계정 활성화 상태 체크 (필요 시)
    if not user.is_active:
        raise UnauthorizedException(message="비활성화된 계정입니다.")

    return user
