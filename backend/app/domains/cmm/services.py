"""공통 관리(CMM) 도메인의 비즈니스 로직(Service)을 담당하는 모듈입니다."""

import uuid
from typing import Optional, Tuple

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ConflictException, NotFoundException
from app.domains.cmm.models import Attachment, AuditLog, SystemSequence
from app.domains.cmm.schemas import AttachmentCreate, AuditLogCreate

# TODO: 실제 MinIO 파일 업로드/삭제 처리를 위한 클라이언트(boto3 또는 minio) 연동 모듈 임포트 필요
# from app.core.storage import minio_client


class AuditLogService:
    """시스템 감사 로그(Audit Log) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def create_audit_log(db: AsyncSession, obj_in: AuditLogCreate) -> AuditLog:
        """
        사용자의 행위 및 데이터 변경 스냅샷을 감사 로그로 기록합니다.

        이 메서드는 다른 비즈니스 로직(예: 시설 등록, 권한 변경 등) 내부에서 호출되어
        블랙박스 역할을 수행합니다.
        """
        db_obj = AuditLog(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()  # DB에 반영하여 ID 확보
        return db_obj


class AttachmentService:
    """첨부 파일 메타데이터 및 스토리지 연동 관련 비즈니스 로직을 처리하는 클래스입니다."""

    @staticmethod
    async def create_attachment_metadata(
        db: AsyncSession, obj_in: AttachmentCreate
    ) -> Attachment:
        """
        업로드된 파일의 메타데이터를 데이터베이스에 저장합니다.

        실제 파일 스트림은 라우터(Router) 단에서 MinIO 서버로 전송되고,
        이 서비스 로직은 그 결과(Object Name, 버킷, 사이즈 등)를 DB에 기록하는 역할을 합니다.
        """
        db_obj = Attachment(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()
        return db_obj

    @staticmethod
    async def delete_attachment(db: AsyncSession, attachment_id: uuid.UUID) -> None:
        """
        첨부 파일 메타데이터를 삭제하고, 실제 MinIO 스토리지의 객체도 함께 삭제합니다.
        """
        attachment = await db.get(Attachment, attachment_id)
        if not attachment:
            raise NotFoundException(message="해당 첨부 파일 정보를 찾을 수 없습니다.")

        # 1. MinIO 스토리지에서 실제 파일(Object) 삭제 호출
        # try:
        #     await minio_client.remove_object(
        #         bucket_name=attachment.bucket_name,
        #         object_name=str(attachment.id)
        #     )
        # except Exception as e:
        #     raise ConflictException(message=f"스토리지 파일 삭제에 실패했습니다: {str(e)}")

        # 2. 메타데이터 DB에서 삭제
        await db.delete(attachment)


class SystemSequenceService:
    """도메인별 자동 채번(Sequence) 상태를 관리하는 서비스 클래스입니다."""

    @staticmethod
    async def get_next_sequence(db: AsyncSession, domain_code: str) -> str:
        """
        주어진 도메인 코드에 대한 다음 시퀀스 번호를 생성하여 반환합니다.

        PostgreSQL의 UPDATE ... RETURNING 구문을 사용하여 원자적(Atomic)으로 동작하므로,
        다수의 사용자가 동시에 요청해도 중복된 번호가 발생하지 않습니다. (동시성 제어)
        """
        # 1. 원자적 업데이트 및 증가된 시퀀스 값 반환
        stmt = (
            update(SystemSequence)
            .where(SystemSequence.domain_code == domain_code)
            .values(current_seq=SystemSequence.current_seq + 1)
            .returning(SystemSequence.current_seq, SystemSequence.prefix)
        )
        result = await db.execute(stmt)
        row = result.first()  # Pylance가 자동으로 Row 타입으로 추론하게 둡니다.

        # 2. 해당 도메인 코드가 DB에 없을 경우 예외 처리
        if not row:
            raise NotFoundException(
                error_code=4040,
                message=f"도메인 코드 '{domain_code}'에 대한 시퀀스 설정이 존재하지 않습니다.",
            )

        current_seq, prefix = row

        # 3. 코드 포맷팅 (예: FAC_WORK_ORDER, prefix='WO', seq=12 -> "WO-00000012")
        # 패딩 길이(8자리) 등은 요구사항에 맞게 조절할 수 있습니다.
        formatted_seq = f"{current_seq:08d}"

        if prefix:
            return f"{prefix}-{formatted_seq}"
        return formatted_seq
