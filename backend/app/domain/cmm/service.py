import boto3
from sqlalchemy.orm import Session
from sqlalchemy import text
from botocore.exceptions import ClientError
from app.core.config import Settings
from .models import CodeDetail  # 상대 경로 임포트


settings = Settings()


class CmmService:
    @staticmethod
    def get_codes_by_group(db: Session, group_code: str):
        """특정 그룹의 상세 코드 목록을 조회합니다."""
        return db.query(CodeDetail).filter(
            CodeDetail.group_code == group_code,
            CodeDetail.is_active
        ).order_by(CodeDetail.sort_order).all()

    @staticmethod
    def generate_next_sequence(db: Session, domain_code: str) -> str:
        """DB 채번 함수를 호출하여 새 번호를 생성합니다."""
        query = text("SELECT cmm.get_next_sequence(:domain)")
        result = db.execute(query, {"domain": domain_code}).scalar()
        db.commit()  # 채번 상태 확정
        return str(result)


class S3Service:
    @staticmethod
    def get_s3_client():
        """MinIO(S3 호환) 클라이언트를 생성합니다."""
        return boto3.client(
            "s3",
            endpoint_url=f"http://{settings.MINIO_ENDPOINT}",
            aws_access_key_id=settings.MINIO_ACCESS_KEY,
            aws_secret_access_key=settings.MINIO_SECRET_KEY
        )

    @staticmethod
    def upload_file(file_obj, object_name: str):
        """파일 객체를 MinIO 버킷에 업로드합니다."""
        s3_client = S3Service.get_s3_client()
        try:
            s3_client.upload_fileobj(
                file_obj,
                settings.MINIO_BUCKET,
                object_name
            )  # MinIO 서버로 파일 전송
            return True
        except ClientError:
            return False
