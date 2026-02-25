"""애플리케이션 전역 환경 설정을 관리하는 모듈입니다."""

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    환경 변수에서 설정을 불러오는 클래스입니다.

    .env 파일 및 도커 시크릿의 내용을 읽어 속성에 매핑합니다.
    """

    PROJECT_NAME: str = "SFMS Backend"
    API_V1_STR: str = "/api/v1"

    # .env 파일에서 읽어올 변수들
    DATABASE_URL: str = ""
    REDIS_URL: str = ""
    S3_ENDPOINT: str = ""
    BACKEND_CORS_ORIGINS: str = ""

    # Docker 시크릿 파일에서 읽어올 변수
    BACKEND_PASSWORD: str = Field(
        default="",
        alias="sfms-backend-password",  # 시크릿 파일명과 연결
    )

    model_config = SettingsConfigDict(
        env_file=".env",
        env_ignore_empty=True,
        secrets_dir="/run/secrets",  # 도커 시크릿 마운트 경로 지정
        extra="ignore",  # 정의되지 않은 환경변수 무시
    )


settings = Settings()
