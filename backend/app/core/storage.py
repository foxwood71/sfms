"""SFMS 시스템의 MinIO(객체 스토리지) 파일 업로드 및 관리를 담당하는 모듈입니다."""

import io
from datetime import timedelta

from minio import Minio
from minio.error import S3Error

# TODO: 실제 운영 환경에서는 app.core.config의 settings에서 값을 가져와야 합니다.
MINIO_ENDPOINT = "localhost:9000"
MINIO_ACCESS_KEY = "minioadmin"
MINIO_SECRET_KEY = "minioadmin"
MINIO_SECURE = False  # 로컬 개발 환경에서는 HTTP 사용
DEFAULT_BUCKET_NAME = "sfms-bucket"

# MinIO 클라이언트 전역 인스턴스 생성
minio_client = Minio(
    endpoint=MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE,
)


def ensure_bucket_exists(bucket_name: str = DEFAULT_BUCKET_NAME) -> None:
    """
    지정된 버킷이 존재하는지 확인하고, 없다면 새로 생성합니다.
    서버 시작 시점이나 파일 업로드 전에 호출하여 안전성을 확보합니다.
    """
    try:
        if not minio_client.bucket_exists(bucket_name):
            minio_client.make_bucket(bucket_name)
    except S3Error as e:
        print(f"MinIO 버킷 확인/생성 중 오류 발생: {e}")


def upload_file_stream(
    object_name: str,
    file_data: bytes,
    content_type: str,
    bucket_name: str = DEFAULT_BUCKET_NAME,
) -> bool:
    """
    메모리에 있는 파일 데이터(bytes)를 MinIO 서버로 업로드합니다.

    Args:
        object_name (str): 스토리지에 저장될 파일명 (보통 UUID 사용)
        file_data (bytes): 업로드할 파일의 실제 데이터
        content_type (str): 파일의 MIME 타입
        bucket_name (str): 저장할 버킷명

    Returns:
        bool: 업로드 성공 여부
    """
    ensure_bucket_exists(bucket_name)

    try:
        # bytes 데이터를 읽을 수 있는 BytesIO 스트림 객체로 변환
        data_stream = io.BytesIO(file_data)
        data_length = len(file_data)

        minio_client.put_object(
            bucket_name=bucket_name,
            object_name=object_name,
            data=data_stream,
            length=data_length,
            content_type=content_type,
        )
        return True
    except S3Error as e:
        print(f"MinIO 파일 업로드 실패: {e}")
        return False


def delete_file(object_name: str, bucket_name: str = DEFAULT_BUCKET_NAME) -> bool:
    """
    MinIO 서버에서 특정 파일을 삭제합니다.
    """
    try:
        minio_client.remove_object(bucket_name=bucket_name, object_name=object_name)
        return True
    except S3Error as e:
        print(f"MinIO 파일 삭제 실패: {e}")
        return False


def get_presigned_url(
    object_name: str, bucket_name: str = DEFAULT_BUCKET_NAME, expires_minutes: int = 60
) -> str:
    """
    프론트엔드에서 파일을 직접 다운로드하거나 이미지 태그(<img src="...">)에
    사용할 수 있는 임시 서명된(Presigned) URL을 발급합니다.
    """
    try:
        url = minio_client.get_presigned_url(
            method="GET",
            bucket_name=bucket_name,
            object_name=object_name,
            expires=timedelta(minutes=expires_minutes),
        )
        return url
    except S3Error as e:
        print(f"MinIO Presigned URL 발급 실패: {e}")
        return ""
