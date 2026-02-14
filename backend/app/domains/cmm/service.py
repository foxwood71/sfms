"""CMM (Common Module Management) 비즈니스 서비스 레이어.

공통 코드 CRUD, 시퀀스 생성, MinIO S3 파일 업로드 로직.
SQLAlchemy + FastAPI + boto3 통합.
"""

import boto3
from botocore.exceptions import ClientError
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.config import Settings

from .models import CodeDetail, CodeGroup
from .schemas import CodeGroupCreate

settings = Settings()


class CmmService:
    """CMM 공통 코드 관리 서비스.

    코드그룹/상세 CRUD, 시퀀스 생성, DB 트랜잭션 관리.

    Attributes:
        settings: 전역 설정 인스턴스.

    """

    def get_code_groups(self, db: Session) -> list[CodeGroup]:
        """활성 코드그룹 전체 목록 조회.

        Args:
            db: SQLAlchemy 세션.

        Returns:
            list[CmmCodeGroup]: 모든 활성 그룹 (is_active=True).

        """
        return db.query(CodeGroup).all()

        # [추가] 코드 그룹 생성 함수

    def create_code_group(
        self,
        db: Session,
        group_data: CodeGroupCreate,
    ) -> CodeGroup:
        """새 코드그룹 생성 (중복 체크 포함).

        트랜잭션 롤백 처리 포함.

        Args:
            db: SQLAlchemy 세션.
            group_data: 생성 데이터 (Pydantic 검증됨).

        Returns:
            CmmCodeGroup: 생성된 그룹 인스턴스.

        Raises:
            HTTPException(409): group_code 중복.
            HTTPException(500): DB 저장 실패.

        """
        # 1. 중복 체크
        existing_group = (
            db.query(CodeGroup)
            .filter(
                CodeGroup.group_code == group_data.group_code,
            )
            .first()
        )

        if existing_group:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="이미 존재하는 그룹 코드입니다.",
            )

        # 2. 데이터 생성
        new_group = CodeGroup(
            group_code=group_data.group_code,
            group_name=group_data.group_name,
            description=group_data.description,
            is_active=group_data.is_active,
            is_system=group_data.is_system,
        )

        # 3. 저장 및 커밋
        try:
            db.add(new_group)
            db.commit()
            db.refresh(new_group)

        except IntegrityError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="데이터 무결성 위반",
            ) from e  # ✅ from e 추가
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="DB 저장 실패",
            ) from e
        return new_group

    @staticmethod
    def get_codes_by_group(db: Session, group_code: str) -> list[CodeDetail]:
        """특정 그룹의 활성 상세 코드 목록 조회.

        Args:
            db: SQLAlchemy 세션.
            group_code: 조회할 그룹코드.

        Returns:
            list[CodeDetail]: 정렬된 활성 코드 목록.

        """
        return (
            db.query(CodeDetail)
            .filter(
                CodeDetail.group_code == group_code,
                CodeDetail.is_active,
            )
            .order_by(CodeDetail.sort_order)
            .all()
        )

    @staticmethod
    def generate_next_sequence(db: Session, domain_code: str) -> str:
        """PostgreSQL 커스텀 함수로 도메인별 시퀀스 생성.

        예: FAC → "FAC-001", WWT → "WWT-20260214-001".

        Args:
            db: SQLAlchemy 세션.
            domain_code: 도메인 코드 (FAC, WWT 등).

        Returns:
            str: 새 시퀀스 번호.

        """
        """DB 채번 함수를 호출하여 새 번호를 생성합니다."""
        query = text("SELECT cmm.get_next_sequence(:domain)")
        result = db.execute(query, {"domain": domain_code}).scalar()
        db.commit()  # 채번 상태 확정
        return str(result)


class S3Service:
    """MinIO S3-compatible 파일 업로드 서비스.

    boto3 클라이언트 wrapper로 SFMS 파일 첨부 처리.
    """

    @staticmethod
    def get_s3_client() -> boto3.client:
        """MinIO S3 클라이언트 인스턴스 생성.

        settings에서 endpoint/credentials 자동 로드.

        Returns:
            boto3.client: S3 클라이언트.

        """
        """MinIO(S3 호환) 클라이언트를 생성합니다."""
        return boto3.client(
            "s3",
            endpoint_url=f"http://{settings.MINIO_ENDPOINT}",
            aws_access_key_id=settings.MINIO_ACCESS_KEY,
            aws_secret_access_key=settings.MINIO_SECRET_KEY,
        )

    @staticmethod
    def upload_file(file_obj: UploadFile, object_name: str) -> bool:
        """파일 스트림을 MinIO 버킷에 업로드.

        Args:
            file_obj: FastAPI UploadFile 스트림.
            object_name: S3 object 경로 (도메인/ref_id/filename).

        Returns:
            bool: 업로드 성공 여부.

        Raises:
            ClientError: MinIO 연결/권한 오류.

        """
        """파일 객체를 MinIO 버킷에 업로드합니다."""
        s3_client = S3Service.get_s3_client()
        try:
            s3_client.upload_fileobj(
                file_obj,
                settings.MINIO_BUCKET,
                object_name,
            )  # MinIO 서버로 파일 전송
        except ClientError:
            return False
        return True
