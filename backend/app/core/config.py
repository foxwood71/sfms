"""애플리케이션 전역 환경 설정을 관리하는 모듈입니다."""

import os

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

SECRETS_DIR = "/run/secrets"  # 도커 시크릿 기본 마운트 경로
# 폴더가 존재하면 경로 문자열을, 없으면 None을 할당하여 타입 에러를 방지합니다.
active_secrets_dir = SECRETS_DIR if os.path.exists(SECRETS_DIR) else None


class Settings(BaseSettings):
    """환경 변수에서 설정을 불러오는 클래스입니다.

    .env 파일 및 도커 시크릿의 내용을 읽어 속성에 매핑합니다.
    """

    # [Project 설정]
    PROJECT_NAME: str = "SFMS Backend"
    VERSION: str = "0.1.0"
    API_V1_STR: str = "/api/v1"

    # [Auth 설정]
    # 실제 운영 환경에서는 반드시 .env 파일을 통해 복잡한 문자열로 변경해야 합니다!
    SECRET_KEY: str = "your-super-secret-key-change-me-in-production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # .env 파일에서 읽어올 변수들
    # [Postgresql 설정]
    DATABASE_URL: str = ""

    # [MinIO Storage 설정]
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"
    MINIO_SECURE: bool = False  # 로컬(HTTP)은 False, 운영(HTTPS)은 True
    MINIO_BUCKET_NAME: str = "sfms-bucket"
    # [Redis 설정]
    REDIS_URL: str = "redis://localhost:6379/0"
    # [Backend 설정]
    BACKEND_CORS_ORIGINS: str = ""

    # [Podman] 시크릿 파일에서 읽어올 변수
    BACKEND_PASSWORD: str = Field(
        default="",
        alias="sfms-backend-password",  # 시크릿 파일명과 연결
    )

    # Pydantic v2 통합 설정
    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        extra="ignore",  # 정의되지 않은 환경변수 무시
        secrets_dir=active_secrets_dir,  # 도커/포드만 시크릿 디렉토리
        case_sensitive=True,  # 환경 변수 이름의 대소문자를 엄격하게 구분
    )


settings = Settings()
