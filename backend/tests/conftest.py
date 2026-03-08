"""테스트 환경 설정 및 공통 픽스처(Fixture)를 정의하는 모듈입니다.

이 모듈은 pytest 실행 시 자동으로 로드되며, 데이터베이스 연결, Redis 초기화,
테스트용 HTTP 클라이언트 및 인증 토큰 등을 모든 테스트 케이스에 제공합니다.
"""

import pytest
from httpx import ASGITransport, AsyncClient
from redis.asyncio import from_url
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core import cache, database
from app.core.config import settings
from app.main import app


@pytest.fixture(scope="session")
def anyio_backend():
    """AnyIO 테스트에서 사용할 백엔드 엔진을 지정합니다."""
    return "asyncio"


@pytest.fixture(scope="session", autouse=True)
async def setup_infrastructure(anyio_backend):
    """전체 테스트 세션 시작 시 데이터베이스 및 Redis 인프라를 초기화합니다.

    모든 테스트가 깨끗한 상태에서 시작되도록 Redis 데이터를 비우고,
    애플리케이션 전역에서 사용할 엔진과 세션 팩토리를 테스트용으로 교체합니다.
    """
    test_engine = create_async_engine(settings.DATABASE_URL, echo=False)
    test_session_factory = async_sessionmaker(test_engine, expire_on_commit=False)
    test_redis = from_url(settings.REDIS_URL, decode_responses=True)

    # [중요] 전체 테스트 시작 시 Redis 데이터를 완전히 비웁니다.
    # 이전 테스트의 블랙리스트나 Rate Limit 정보가 남아 간섭하는 것을 방지합니다.
    await test_redis.flushdb()

    database.engine = test_engine
    database.AsyncSessionLocal = test_session_factory
    cache.redis_client = test_redis

    yield

    await test_engine.dispose()
    await test_redis.aclose()


@pytest.fixture(scope="session")
async def client(anyio_backend):
    """애플리케이션 API를 호출하기 위한 비동기 HTTP 클라이언트를 제공합니다."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac


@pytest.fixture(scope="function")
async def auth_token(anyio_backend):
    """테스트마다 독립적으로 사용할 관리자 인증 토큰을 제공합니다.

    기존 client 픽스처를 사용할 경우 쿠키 세션 등이 공유되어 테스트 간 간섭이
    발생할 수 있으므로, 매번 새로운 클라이언트를 생성하여 인증을 수행합니다.
    또한 Rate Limiting에 걸리지 않도록 관련 키를 매번 초기화합니다.

    Returns:
        str: 발급된 JWT 액세스 토큰 문자열

    """
    import asyncio

    from app.core.cache import redis_client

    # 로그인 시도 횟수 제한 초기화
    await redis_client.delete("rate_limit:login:127.0.0.1")
    await redis_client.delete("rate_limit:login:testclient")

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        response = await ac.post(
            "/api/v1/auth/login", json={"login_id": "admin", "password": "admin1234"}
        )
        if response.status_code != 200:
            pytest.fail(
                f"Login failed for auth_token fixture: {response.status_code} - {response.text}"
            )

        data = response.json()
        token = data["data"]["access_token"]

        # Redis 전파를 위한 아주 짧은 지연
        await asyncio.sleep(0.01)

        return token
