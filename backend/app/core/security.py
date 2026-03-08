"""SFMS 시스템의 보안(비밀번호 해싱 및 JWT 토큰 관리)을 담당하는 모듈입니다."""

from datetime import UTC, datetime, timedelta
from typing import Any

import bcrypt
import jwt
from fastapi.security import OAuth2PasswordBearer
from jwt.exceptions import InvalidTokenError

from app.core.cache import redis_client
from app.core.config import settings
from app.core.logger import logger

# 시스템 전체에서 공유할 인증 스키마 (자물쇠 규격)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """평문 비밀번호와 해싱된 비밀번호를 비교하여 일치 여부를 반환합니다.

    Args:
        plain_password (str): 사용자가 입력한 평문 비밀번호
        hashed_password (str): 데이터베이스에 저장된 해싱된 비밀번호

    Returns:
        bool: 일치하면 True, 그렇지 않으면 False

    """
    try:
        return bcrypt.checkpw(
            plain_password.encode("utf-8"), hashed_password.encode("utf-8")
        )
    except Exception as e:
        logger.error(f"비밀번호 검증 오류: {e}")
        return False


def get_password_hash(password: str) -> str:
    """비밀번호를 bcrypt 알고리즘으로 해싱하여 반환합니다.

    Args:
        password (str): 해싱할 평문 비밀번호

    Returns:
        str: bcrypt로 해싱된 비밀번호 문자열

    """
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode("utf-8"), salt)
    return hashed.decode("utf-8")


def create_access_token(
    subject: str | int, expires_delta: timedelta | None = None
) -> str:
    """JWT Access Token을 생성합니다.

    Args:
        subject (str | int): 토큰의 주체 (통상 사용자 ID)
        expires_delta (timedelta | None, optional): 커스텀 만료 시간. 기본값은 settings 설정 참조.

    Returns:
        str: 생성된 JWT 액세스 토큰 문자열

    """
    if expires_delta:
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode = {"exp": expire, "sub": str(subject), "type": "access"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def create_refresh_token(
    subject: str | int, expires_delta: timedelta | None = None
) -> str:
    """JWT Refresh Token을 생성합니다.

    Args:
        subject (str | int): 토큰의 주체 (통상 사용자 ID)
        expires_delta (timedelta | None, optional): 커스텀 만료 시간. 기본값은 settings 설정 참조.

    Returns:
        str: 생성된 JWT 리프레시 토큰 문자열

    """
    if expires_delta:
        expire = datetime.now(UTC) + expires_delta
    else:
        expire = datetime.now(UTC) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)

    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )

    return encoded_jwt


def decode_token(token: str) -> dict[str, Any]:
    """JWT 토큰을 검증하고 페이로드를 디코딩하여 반환합니다.

    Args:
        token (str): 디코딩할 JWT 토큰

    Returns:
        dict[str, Any]: 디코딩된 토큰 페이로드

    Raises:
        InvalidTokenError: 토큰이 유효하지 않을 때 발생

    """
    return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])


def verify_token(token: str) -> dict[str, Any] | None:
    """JWT 토큰의 서명과 유효성을 검증하고 페이로드(내용물)를 반환합니다.

    Args:
        token (str): 검증할 JWT 토큰

    Returns:
        dict[str, Any] | None: 유효한 경우 페이로드 딕셔너리, 그렇지 않으면 None

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


def get_token_payload(token: str) -> dict[str, Any] | None:
    """토큰을 검증한 후 페이로드를 반환하며, 실패 시 None을 반환합니다.

    Args:
        token (str): 페이로드를 추출할 토큰

    Returns:
        dict[str, Any] | None: 추출된 페이로드 또는 None

    """
    try:
        payload = verify_token(token)
        return payload
    except InvalidTokenError:
        return None


async def add_token_to_blacklist(token: str, expire: int) -> None:
    """토큰을 Redis 블랙리스트에 추가하여 재사용을 방지합니다.

    Args:
        token (str): 블랙리스트에 등록할 토큰 문자열
        expire (int): 토큰의 남은 만료 시간 (초 단위)

    """
    key = f"blacklist:{token}"
    try:
        # 토큰의 남은 시간만큼만 Redis에 보관하고 자동 삭제되도록 설정
        await redis_client.setex(key, expire, "true")
    except Exception as e:
        logger.error(f"Redis 블랙리스트 추가 오류 (token: {token[:10]}...): {e}")


async def is_token_blacklisted(token: str) -> bool:
    """해당 토큰이 블랙리스트에 등록되어 있는지 확인합니다.

    Args:
        token (str): 확인할 토큰 문자열

    Returns:
        bool: 블랙리스트에 있으면 True, 없으면 False

    """
    key = f"blacklist:{token}"
    try:
        return await redis_client.exists(key) > 0
    except Exception as e:
        logger.error(f"Redis 블랙리스트 조회 오류: {e}")
        return False
