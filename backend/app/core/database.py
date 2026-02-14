import os
from pathlib import Path
from dotenv import load_dotenv

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 1. .env 파일 로드
BASE_DIR = Path(__file__).resolve().parent.parent.parent
env_path = BASE_DIR / ".env"
# load_dotenv(dotenv_path=env_path)
# override=True: 시스템 환경변수보다 .env를 우선시함
is_loaded = load_dotenv(dotenv_path=env_path, override=True)

# 2. 혹시 URL이 없으면 에러가 나도록 안전장치 추가
# 디버깅: 경로와 값을 출력해 봅니다 (서버 뜨면 콘솔 확인)
print("="*50)
print(f"[DEBUG] .env file path: {env_path}")
print(f"[DEBUG] File exists?: {env_path.exists()}")
print(f"[DEBUG] load_dotenv result: {is_loaded}")

# 실제 로드된 키 확인 (SQL로 시작하는 변수가 있는지?)
env_vars = {k: v for k, v in os.environ.items() if k.startswith("SQLALCHEMY")}
print(f"[DEBUG] Loaded SQL vars: {env_vars}")
print("="*50)

# 3. 환경 변수 가져오기
SQLALCHEMY_DATABASE_URL = os.getenv("SQLALCHEMY_DATABASE_URL")

if not SQLALCHEMY_DATABASE_URL:
    raise ValueError("SQLALCHEMY_DATABASE_URL이 설정되지 않았습니다. .env 파일을 확인해주세요.")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
#  autocommit/autoflush 설정을 명시적으로 관리
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
