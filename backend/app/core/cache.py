"""SFMS 시스템의 Redis 캐시 및 세션(토큰 블랙리스트)을 관리하는 모듈입니다."""

import json
from typing import Any, Optional

import redis.asyncio as redis

# TODO: 실제 운영 환경에서는 app.core.config의 settings에서 REDIS_URL을 가져와야 합니다.
REDIS_URL = "redis://localhost:6379/0"  # 기본 Redis 로컬 주소

# 전역 비동기 Redis 클라이언트 인스턴스
# decode_responses=True를 설정하면 바이트 대신 문자열(str)로 반환되어 다루기 편합니다.
redis_client = redis.from_url(REDIS_URL, decode_responses=True)


async def set_cache(key: str, value: Any, expire: Optional[int] = None) -> None:
    """
    Redis에 데이터를 캐싱합니다.

    Args:
        key (str): 캐시 키
        value (Any): 저장할 데이터 (딕셔너리/리스트는 JSON 문자열로 자동 변환)
        expire (Optional[int]): 만료 시간(초). 지정하지 않으면 영구 저장.
    """
    if isinstance(value, (dict, list)):
        value = json.dumps(value)

    if expire:
        await redis_client.setex(key, expire, value)
    else:
        await redis_client.set(key, value)


async def get_cache(key: str) -> Optional[str]:
    """Redis에서 특정 키에 캐시된 데이터를 가져옵니다."""
    return await redis_client.get(key)


async def delete_cache(key: str) -> None:
    """Redis에서 특정 키의 캐시를 삭제합니다."""
    await redis_client.delete(key)


# --------------------------------------------------------
# [Auth] JWT 토큰 블랙리스트 (로그아웃 처리)
# --------------------------------------------------------
async def add_token_to_blacklist(token: str, expire: int) -> None:
    """
    로그아웃 시 JWT 토큰을 블랙리스트에 추가하여 무효화합니다.

    Args:
        token (str): 무효화할 JWT 토큰 문자열 (또는 JTI)
        expire (int): 토큰의 남은 만료 시간(초). 이 시간이 지나면 Redis에서도 자동 삭제되어 메모리를 아낍니다.
    """
    key = f"blacklist:{token}"  # 블랙리스트 키 접두사
    await redis_client.setex(key, expire, "true")


async def is_token_blacklisted(token: str) -> bool:
    """
    특정 토큰이 블랙리스트에 존재하는지(로그아웃 처리되었는지) 확인합니다.

    이 함수는 인증 의존성(Depends)에서 토큰을 검증할 때 매번 호출됩니다.
    """
    key = f"blacklist:{token}"
    result = await redis_client.get(key)

    return result is not None
