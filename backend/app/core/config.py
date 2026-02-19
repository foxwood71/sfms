"""애플리케이션 전역 환경 설정을 관리하는 모듈입니다."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    환경 변수에서 설정을 불러오는 클래스입니다.

    .env 파일의 내용을 읽어 속성에 매핑합니다.
    """

    PROJECT_NAME: str = "SFMS Backend"
    API_V1_STR: str = "/api/v1"
    DATABASE_URL: str

    model_config = SettingsConfigDict(env_file=".env", env_ignore_empty=True)


settings = Settings()
