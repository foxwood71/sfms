"""비동기 데이터베이스 연결 및 세션을 관리하는 모듈입니다."""


from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings

# 1. 비동기 DB 엔진 생성
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True,  # 개발 환경용 SQL 로깅 활성화
    future=True,
)

# 2. 비동기 세션 팩토리 생성
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,
)


# 3. 모든 ORM 모델의 부모 클래스
# Base = declarative_base()
class Base(DeclarativeBase):  # -> Pydantic v2
    """SQLAlchemy ORM 모델을 위한 통합 기본 클래스입니다.

    이 클래스는 프로젝트 내 모든 데이터베이스 모델의 '뿌리' 역할을 하며,
    이를 상속받는 클래스들은 자동으로 SQLAlchemy의 선언적 매핑(Declarative Mapping) 시스템에 등록됩니다.

    Attributes:
        metadata (MetaData): 모든 테이블 스키마 정보를 담고 있는 레지스트리입니다.

    """

    pass
