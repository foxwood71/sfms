import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    #  ... 기존 DB 설정들 ...
    MINIO_ENDPOINT: str = os.getenv("MINIO_ENDPOINT", "localhost:9000")
    MINIO_ACCESS_KEY: str = os.getenv("MINIO_ACCESS_KEY", "sfms_storage_admin")
    MINIO_SECRET_KEY: str = os.getenv("MINIO_SECRET_KEY", "minio_storage_password")
    MINIO_BUCKET: str = "sfms-attachments"
