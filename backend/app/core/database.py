"""SFMS 데이터베이스 설정 및 세션 관리 모듈.

SQLAlchemy 엔진을 생성하고 FastAPI 요청 생명주기에 맞춘
세션 제너레이터(get_db)를 제공합니다.
"""

import os
from collections.abc import Generator
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker

# 1. .env 파일 로드
BASE_DIR = Path(__file__).resolve().parent.parent.parent
env_path = BASE_DIR / ".env"

# override=True: 시스템 환경변수보다 .env를 우선시함
is_loaded = load_dotenv(dotenv_path=env_path, override=True)

# 실제 로드된 키 확인 (SQL로 시작하는 변수가 있는지?)
env_vars = {k: v for k, v in os.environ.items() if k.startswith("SQLALCHEMY")}

# 3. 환경 변수 가져오기
SQLALCHEMY_DATABASE_URL = os.getenv("SQLALCHEMY_DATABASE_URL")

if not SQLALCHEMY_DATABASE_URL:
    msg = "SQLALCHEMY_DATABASE_URL이 설정되지 않았습니다. .env 파일을 확인해주세요."
    raise ValueError(msg)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
#  autocommit/autoflush 설정을 명시적으로 관리
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db() -> Generator[Session]:
    """데이터베이스 세션을 생성하고 관리하는 의존성 주입용 함수.

    FastAPI의 Depends와 함께 사용되어 요청마다 세션을 할당하고,
    작업이 완료되면 자동으로 세션을 종료(close)합니다.

    Yields:
        Session: SQLAlchemy 데이터베이스 세션 객체.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
