"""CMM 도메인 비즈니스 로직 처리 서비스.

공통 코드의 CRUD 처리, 시퀀스 번호 생성 요청,
그리고 MinIO와 연동된 파일 메타데이터 관리를 수행합니다.
"""

from io import BytesIO

import boto3
from botocore.exceptions import ClientError
from fastapi import HTTPException, UploadFile, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.config import Settings

from .models import (
    Attachment,
    CodeDetail,
    CodeGroup,
    SystemDomain,
)
from .schemas import (
    AttachmentUpdate,
    CodeDetailCreate,
    CodeDetailUpdate,
    CodeGroupCreate,
    CodeGroupUpdate,
)

settings = Settings()


class CmmService:
    """CMM 공통 코드 관리 서비스.

    코드그룹/상세 CRUD, 시퀀스 생성, DB 트랜잭션 관리.

    Attributes:
        settings: 전역 설정 인스턴스.

    """

    @staticmethod
    def create_code_group(
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
    def create_code_detail(db: Session, data: "CodeDetailCreate") -> CodeDetail:
        """새로운 상세 코드를 생성합니다.

        기존에 동일한 그룹 내 동일한 코드가 존재하는지 확인 후,
        JSONB 속성(props)을 포함하여 DB에 저장합니다.

        Args:
            db (Session): SQLAlchemy 데이터베이스 세션.
            data (CodeDetailCreate): 검증된 생성 요청 데이터.

        Returns:
            CodeDetail: 생성된 상세 코드 엔티티 인스턴스.

        Raises:
            HTTPException (409): 중복된 코드가 존재할 경우.
            HTTPException (500): 데이터베이스 저장 오류 발생 시.
        """
        # 1. 중복 코드 존재 여부 확인
        existing = (
            db.query(CodeDetail)
            .filter(
                CodeDetail.group_code == data.group_code,
                CodeDetail.detail_code == data.detail_code,
            )
            .first()
        )

        if existing:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"그룹[{data.group_code}] 내에 코드[{data.detail_code}]가 이미 존재합니다.",
            )

        # 2. 엔티티 생성 및 데이터 매핑
        new_detail = CodeDetail(
            group_code=data.group_code,
            detail_code=data.detail_code,
            detail_name=data.detail_name,
            props=data.props,  # JSONB 필드 대응
            sort_order=data.sort_order,
            is_active=data.is_active,
        )

        # 3. 데이터베이스 저장
        try:
            db.add(new_detail)
            db.commit()  # 트랜잭션 확정
            db.refresh(new_detail)  # DB 반영된 값(created_at 등) 로드
            return new_detail

        except IntegrityError as e:
            db.rollback()  # 무결성 위반 시 롤백
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="데이터 무결성 위반으로 생성이 실패했습니다.",
            ) from e
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="상세 코드 저장 중 서버 오류가 발생했습니다.",
            ) from e

    @staticmethod
    def get_code_groups(db: Session) -> list[CodeGroup]:
        """활성 코드그룹 전체 목록 조회.

        Args:
            db: SQLAlchemy 세션.

        Returns:
            list[CmmCodeGroup]: 모든 활성 그룹 (is_active=True).

        """
        return db.query(CodeGroup).all()

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
    def update_code_group(
        db: Session, group_code: str, data: CodeGroupUpdate
    ) -> CodeGroup:
        """코드 그룹 정보를 수정합니다."""
        group = db.query(CodeGroup).filter(CodeGroup.group_code == group_code).first()
        if not group:
            raise HTTPException(status_code=404, detail="그룹을 찾을 수 없습니다.")

        # 전달된 값만 반영 (Dynamic Update)
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(group, key, value)

        try:
            db.commit()
            db.refresh(group)
            return group
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="그룹 수정 실패") from e

    @staticmethod
    def update_code_detail(
        db: Session, group_code: str, detail_code: str, data: CodeDetailUpdate
    ) -> CodeDetail:
        """상세 코드의 명칭, 속성(props), 순서 등을 수정합니다."""
        detail = (
            db.query(CodeDetail)
            .filter(
                CodeDetail.group_code == group_code,
                CodeDetail.detail_code == detail_code,
            )
            .first()
        )

        if not detail:
            raise HTTPException(status_code=404, detail="상세 코드를 찾을 수 없습니다.")

        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(detail, key, value)  # props(JSONB) 필드도 여기서 처리됨

        try:
            db.commit()
            db.refresh(detail)
            return detail
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="상세 코드 수정 실패") from e

    @staticmethod
    def delete_code_group(db: Session, group_code: str) -> bool:
        """공통 코드 그룹을 삭제합니다.

        스키마 정의에 따라 관련 상세 코드도 함께 삭제(Cascade)됩니다.

        Args:
            db (Session): 데이터베이스 세션.
            group_code (str): 삭제할 그룹 코드.

        Returns:
            bool: 삭제 성공 여부.
        """
        group = db.query(CodeGroup).filter(CodeGroup.group_code == group_code).first()
        if not group:
            return False

        try:
            db.delete(group)
            db.commit()
            return True
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="코드 그룹 삭제 실패") from e

    @staticmethod
    def delete_code_detail(db: Session, group_code: str, detail_code: str) -> bool:
        """특정 상세 코드를 삭제합니다.

        Args:
            db (Session): 데이터베이스 세션.
            group_code (str): 그룹 코드.
            detail_code (str): 상세 코드.

        Returns:
            bool: 삭제 성공 여부.
        """
        detail = (
            db.query(CodeDetail)
            .filter(
                CodeDetail.group_code == group_code,
                CodeDetail.detail_code == detail_code,
            )
            .first()
        )

        if not detail:
            return False

        try:
            db.delete(detail)
            db.commit()
            return True
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="상세 코드 삭제 실패") from e

    @staticmethod
    def get_attachment(db: Session, file_id: str) -> Attachment:
        """파일 메타데이터를 조회합니다 (삭제된 파일 제외)."""
        return (
            db.query(Attachment)
            .filter(
                Attachment.file_id == file_id,
                Attachment.is_deleted.is_(
                    False
                ),  # 논리 삭제 처리된 파일은 제외, SQL의 IS FALSE 구문을 명시적으로 생성합니다.
            )
            .first()
        )

    @staticmethod
    def register_attachment(db: Session, data: dict) -> dict:
        """S3 업로드 후 파일 메타데이터를 DB(cmm.attachments)에 기록합니다."""
        from .models import Attachment  # 순환 참조 방지용 내부 임포트

        new_file = Attachment(
            domain_code=data["domain_code"],
            ref_id=data["ref_id"],
            file_name=data["file_name"],
            file_path=data["file_path"],
            file_size=data["file_size"],
            content_type=data["content_type"],
        )

        try:
            db.add(new_file)
            db.commit()
            db.refresh(new_file)
            return {
                "file_id": str(new_file.file_id),
                "object_name": new_file.file_path,
                "status": "success",
            }
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="파일 정보 DB 등록 실패",
            ) from e

    @staticmethod
    def update_attachment_metadata(
        db: Session, file_id: str, data: AttachmentUpdate
    ) -> Attachment:
        """첨부파일의 메타데이터(참조 ID 등)를 수정합니다.

        Args:
            db (Session): 데이터베이스 세션.
            file_id (str): 수정할 파일의 UUID[cite: 9].
            data (AttachmentUpdate): 수정할 데이터 필드.

        Returns:
            Attachment: 수정된 파일 메타데이터 인스턴스.
        """
        #  1. 대상 파일 존재 확인
        attachment = (
            db.query(Attachment)
            .filter(
                Attachment.file_id == file_id,
                Attachment.is_deleted.is_(
                    False
                ),  # 삭제되지 않은 파일만 수정 가능, SQL의 IS FALSE 구문을 명시적으로 생성합니다.
            )
            .first()
        )

        if not attachment:
            raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

        #  2. 데이터 반영
        update_data = data.model_dump(exclude_unset=True)
        for key, value in update_data.items():
            setattr(attachment, key, value)

        try:
            db.commit()
            db.refresh(attachment)
            return attachment
        except SQLAlchemyError as e:
            db.rollback()
            raise HTTPException(status_code=500, detail="파일 정보 수정 실패") from e

    @staticmethod
    def delete_attachment(db: Session, file_id: str) -> bool:
        """파일을 논리적으로 삭제 처리합니다."""
        attachment = db.query(Attachment).filter(Attachment.file_id == file_id).first()
        if not attachment:
            return False

        attachment.is_deleted = True  # 스키마의 is_deleted 컬럼 활용
        try:
            db.commit()
            return True
        except SQLAlchemyError:
            db.rollback()
            return False

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

    @staticmethod
    def download_file(object_name: str) -> BytesIO:
        """MinIO로부터 파일 스트림을 가져옵니다."""
        s3_client = S3Service.get_s3_client()
        file_stream = BytesIO()
        try:
            # MinIO 버킷에서 객체 다운로드 [cite: 9]
            s3_client.download_fileobj(settings.MINIO_BUCKET, object_name, file_stream)
            file_stream.seek(0)
            return file_stream
        except ClientError:
            return None

    @staticmethod
    def delete_file(object_name: str) -> bool:
        """MinIO 버킷에서 물리적으로 파일을 삭제합니다.

        Args:
            object_name (str): S3 객체 경로 (도메인/ref_id/파일명).

        Returns:
            bool: 삭제 성공 여부.
        """
        s3_client = S3Service.get_s3_client()
        try:
            #  MinIO 버킷에서 해당 경로의 객체를 영구 제거
            s3_client.delete_object(Bucket=settings.MINIO_BUCKET, Key=object_name)
            return True
        except ClientError:
            return False  # 네트워크 오류 또는 권한 문제 발생 시
