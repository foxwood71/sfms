"""SFMS Database and MinIO configuration.

Provides Pydantic Settings for SQLAlchemy database and MinIO S3-compatible storage.
Used in FastAPI dependency injection and configuration management.
"""

import os

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """SFMS application configuration using Pydantic.

    Loads environment variables with sensible defaults for development.
    Supports .env override for production deployment.

    Attributes:
        MINIO_ENDPOINT: MinIO 서버 주소 (기본: localhost:9000).
        MINIO_ACCESS_KEY: MinIO 액세스 키 (기본: sfms_storage_admin).
        MINIO_SECRET_KEY: MinIO 시크릿 키 (기본: minio_storage_password).
        MINIO_BUCKET: MinIO 버킷 이름 (기본: sfms-attachments).

    """

    MINIO_ENDPOINT: str = os.getenv("MINIO_ENDPOINT", "localhost:9000")
    MINIO_ACCESS_KEY: str = os.getenv("MINIO_ACCESS_KEY", "sfms_storage_admin")
    MINIO_SECRET_KEY: str = os.getenv("MINIO_SECRET_KEY", "minio_storage_password")
    MINIO_BUCKET: str = "sfms-attachments"
