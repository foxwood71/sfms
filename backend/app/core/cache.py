"""SFMS 시스템의 Redis 캐시 및 세션(토큰 블랙리스트)을 관리하는 모듈입니다."""

import json
from typing import Any

from redis.asyncio import Redis

from app.core.config import settings
from app.core.logger import logger

REDIS_URL = settings.REDIS_URL

# 전역 비동기 Redis 클라이언트 인스턴스
# 전역 비동기 Redis 클라이언트 인스턴스
# decode_responses=True를 설정하면 바이트 대신 문자열(str)로 반환되어 다루기 편합니다.
redis_client: Redis = Redis.from_url(REDIS_URL, decode_responses=True)


async def set_cache(key: str, value: Any, expire: int | None = None) -> None:
    """Redis에 데이터를 캐싱합니다.

    Args:
        key (str): 캐시 키
        value (Any): 저장할 데이터 (딕셔너리/리스트는 JSON 문자열로 자동 변환)
        expire (Optional[int]): 만료 시간(초). 지정하지 않으면 영구 저장.

    """
    try:
        if isinstance(value, (dict, list)):
            value = json.dumps(value)

        if expire:
            await redis_client.setex(key, expire, value)
        else:
            await redis_client.set(key, value)
    except Exception as e:
        logger.error(f"Redis set_cache 오류 (key: {key}): {e}")


async def get_cache(key: str) -> str | None:
    """Redis에서 특정 키에 캐시된 데이터를 가져옵니다."""
    try:
        return await redis_client.get(key)
    except Exception as e:
        logger.error(f"Redis get_cache 오류 (key: {key}): {e}")
        return None


async def delete_cache(key: str) -> None:
    """Redis에서 특정 키의 캐시를 삭제합니다."""
    try:
        await redis_client.delete(key)
    except Exception as e:
        logger.error(f"Redis delete_cache 오류 (key: {key}): {e}")
