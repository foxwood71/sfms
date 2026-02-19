"""비동기 데이터베이스 연결 및 세션을 관리하는 모듈입니다."""

from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True,  # 개발 환경용 SQL 로깅 활성화
    future=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """SQLAlchemy ORM 모델의 최상위 베이스 클래스입니다."""

    pass


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    비동기 데이터베이스 세션을 생성하고 반환합니다.

    FastAPI의 의존성 주입(Dependency Injection)을 통해 라우터에서 사용됩니다.
    요청이 끝나면 자동으로 세션을 닫습니다.
    """
    async with AsyncSessionLocal() as session:  # 비동기 세션 생성
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()  # 세션 안전하게 종료
