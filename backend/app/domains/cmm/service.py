import boto3
from botocore.exceptions import ClientError

from sqlalchemy.orm import Session
from sqlalchemy import text
from fastapi import HTTPException, status

from app.core.config import Settings
from .models import CmmCodeGroup, CodeDetail
from .schemas import CodeGroupCreate  # 상대 경로 임포트


settings = Settings()


class CmmService:

    def get_code_groups(self, db: Session):
        return db.query(CmmCodeGroup).all()

        # [추가] 코드 그룹 생성 함수
    def create_code_group(self, db: Session, group_data: CodeGroupCreate):
        # 1. 중복 체크
        existing_group = db.query(CmmCodeGroup).filter(
            CmmCodeGroup.group_code == group_data.group_code
        ).first()

        if existing_group:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 존재하는 그룹 코드입니다."
            )

        # 2. 데이터 생성
        new_group = CmmCodeGroup(
            group_code=group_data.group_code,
            group_name=group_data.group_name,
            description=group_data.description,
            is_active=group_data.is_active,
            is_system=group_data.is_system
        )

        # 3. 저장 및 커밋
        try:
            db.add(new_group)
            db.commit()
            db.refresh(new_group)
            return new_group
        except Exception as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"저장 중 오류가 발생했습니다: {str(e)}"
            )

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
