"""SFMS 시스템의 MinIO(객체 스토리지) 파일 업로드 및 관리를 담당하는 모듈입니다.

aioboto3를 활용하여 완벽한 비동기(Async) 논블로킹 통신을 수행합니다.
"""

from contextlib import asynccontextmanager

import aioboto3
from aiobotocore.config import AioConfig
from botocore.exceptions import ClientError

from app.core.config import settings
from app.core.logger import logger

# settings에서 환경 변수 값을 가져옵니다.
DEFAULT_BUCKET_NAME = settings.MINIO_BUCKET_NAME

# aioboto3는 전역 세션을 공유하고, 필요할 때마다 클라이언트를 생성합니다.
session = aioboto3.Session()

# endpoint_url을 조립합니다. (aioboto3는 http/https 스킴이 필수로 포함되어야 합니다)
SCHEME = "https" if getattr(settings, "MINIO_SECURE", False) else "http"
ENDPOINT_URL = f"{SCHEME}://{settings.MINIO_ENDPOINT}"


async def check_storage_connection() -> bool:
    """MinIO(스토리지) 서버와의 통신 상태를 확인하는 헬스 체크용 함수입니다.

    가장 가벼운 명령어인 list_buckets()를 호출하여 생존 여부를 판별합니다.
    """
    try:
        async with get_s3_client() as s3:
            await s3.list_buckets()
            return True
    except Exception as e:
        logger.error(f"MinIO 헬스 체크 실패(연결 오류): {e}")
        return False


@asynccontextmanager
async def get_s3_client():
    """비동기 S3 클라이언트를 생성하여 반환하는 컨텍스트 매니저입니다."""
    async with session.client(
        service_name="s3",
        endpoint_url=ENDPOINT_URL,
        aws_access_key_id=settings.MINIO_ACCESS_KEY,
        aws_secret_access_key=settings.MINIO_SECRET_KEY,
        region_name="us-east-1",  # MinIO 통신 시 더미 리전이 필요합니다.
        config=AioConfig(signature_version="s3v4"),
    ) as client:
        yield client


async def ensure_bucket_exists(bucket_name: str = DEFAULT_BUCKET_NAME) -> None:
    """지정된 버킷이 존재하는지 확인하고, 없다면 새로 생성합니다.

    서버 시작 시점이나 파일 업로드 전에 호출하여 안전성을 확보합니다.
    """
    async with get_s3_client() as s3:
        try:
            # 버킷 메타데이터를 조회하여 존재 여부를 확인합니다.
            await s3.head_bucket(Bucket=bucket_name)
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code")
            # 404 Not Found 에러인 경우 버킷을 생성합니다.
            if error_code == "404":
                try:
                    await s3.create_bucket(Bucket=bucket_name)
                except ClientError as create_error:
                    logger.error(f"MinIO 버킷 생성 중 오류 발생: {create_error}")
            else:
                logger.error(f"MinIO 버킷 확인 중 오류 발생: {e}")


async def upload_file_stream(
    object_name: str,
    file_data: bytes,
    content_type: str,
    bucket_name: str = DEFAULT_BUCKET_NAME,
) -> bool:
    """메모리에 있는 파일 데이터(bytes)를 MinIO 서버로 비동기 업로드합니다.

    Args:
        object_name (str): 스토리지에 저장될 파일명 (보통 UUID 사용)
        file_data (bytes): 업로드할 파일의 실제 데이터
        content_type (str): 파일의 MIME 타입
        bucket_name (str): 저장할 버킷명

    Returns:
        bool: 업로드 성공 여부

    """
    await ensure_bucket_exists(bucket_name)

    async with get_s3_client() as s3:
        try:
            # aioboto3는 bytes 데이터를 Body 매개변수로 직접 전달할 수 있습니다.
            await s3.put_object(
                Bucket=bucket_name,
                Key=object_name,
                Body=file_data,
                ContentType=content_type,
            )
            return True
        except ClientError as e:
            logger.error(f"MinIO 파일 업로드 실패: {e}")
            return False


async def delete_file(
    object_name: str,
    bucket_name: str = DEFAULT_BUCKET_NAME,
) -> bool:
    """MinIO 서버에서 특정 파일을 비동기로 삭제합니다."""
    async with get_s3_client() as s3:
        try:
            await s3.delete_object(Bucket=bucket_name, Key=object_name)
            return True
        except ClientError as e:
            logger.error(f"MinIO 파일 삭제 실패: {e}")
            return False


async def get_presigned_url(
    object_name: str,
    bucket_name: str = DEFAULT_BUCKET_NAME,
    expires_minutes: int = 60,
) -> str:
    """프론트엔드에서 파일을 직접 다운로드.

    이미지 태그에 사용할 수 있는 임시 서명된(Presigned) URL을 비동기로 발급합니다.
    """
    async with get_s3_client() as s3:
        try:
            url = await s3.generate_presigned_url(
                ClientMethod="get_object",
                Params={"Bucket": bucket_name, "Key": object_name},
                ExpiresIn=expires_minutes * 60,
            )
            return url
        except ClientError as e:
            logger.error(f"MinIO Presigned URL 발급 실패: {e}")
            return ""
