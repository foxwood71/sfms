import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core import database, cache
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from redis.asyncio import from_url
from app.core.config import settings

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture(scope="session", autouse=True)
async def setup_infrastructure(anyio_backend):
    test_engine = create_async_engine(settings.DATABASE_URL, echo=False)
    test_session_factory = async_sessionmaker(test_engine, expire_on_commit=False)
    test_redis = from_url(settings.REDIS_URL, decode_responses=True)
    
    # 로그인 제한 키 초기화 (테스트 방해 요소 제거)
    await test_redis.delete("rate_limit:login:127.0.0.1")
    await test_redis.delete("rate_limit:login:testclient")
    
    database.engine = test_engine
    database.AsyncSessionLocal = test_session_factory
    cache.redis_client = test_redis
    
    yield
    
    await test_engine.dispose()
    await test_redis.aclose()

@pytest.fixture(scope="session")
async def client(anyio_backend):
    async with AsyncClient(
        transport=ASGITransport(app=app), 
        base_url="http://test"
    ) as ac:
        yield ac

@pytest.fixture(scope="session")
async def auth_token(client):
    """세션 전체에서 재사용할 관리자 인증 토큰을 제공합니다."""
    response = await client.post("/api/v1/auth/login", json={"login_id": "admin", "password": "admin1234"})
    return response.json()["data"]["access_token"]
