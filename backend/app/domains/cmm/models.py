"""공통 관리(CMM) 도메인의 데이터베이스 모델을 정의하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from sqlalchemy import BigInteger, DateTime, Index, String, Text
from sqlalchemy.dialects.postgresql import INET, JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class AuditLog(Base):
    """
    시스템 감사 로그(Audit Log)를 저장하는 모델입니다.

    PGroonga 확장을 사용하여 JSONB 타입인 snapshot 필드에 대한 고속 전문 검색을 지원합니다.
    (실제 운영 환경에서는 PostgreSQL 단에서 월 단위 파티셔닝 구성을 권장합니다.)
    """

    __tablename__ = "cmm_audit_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    trace_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), nullable=False, index=True
    )
    actor_id: Mapped[Optional[int]] = mapped_column(
        BigInteger, nullable=True, index=True
    )  # 수행자 ID
    ip_address: Mapped[Optional[str]] = mapped_column(
        INET, nullable=True
    )  # 요청자 IP (보안 감사 필수)
    user_agent: Mapped[Optional[str]] = mapped_column(
        Text, nullable=True
    )  # 요청 브라우저 및 기기 정보
    target_domain: Mapped[str] = mapped_column(
        String(50), nullable=False, index=True
    )  # 예: FAC, USR
    target_id: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True
    )  # 대상 레코드 PK
    action: Mapped[str] = mapped_column(
        String(20), nullable=False
    )  # CREATE, UPDATE, DELETE, LOGIN 등

    # 변경 전/후 데이터 (PGroonga Index 적용 대상)
    snapshot: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    # PGroonga 인덱스 설정
    __table_args__ = (
        Index(
            "ix_cmm_audit_logs_snapshot_pgroonga",
            "snapshot",
            postgresql_using="pgroonga",
        ),
    )


class Attachment(Base):
    """
    MinIO(S3) 객체 스토리지와 동기화되는 파일 메타데이터 모델입니다.
    """

    __tablename__ = "cmm_attachments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )  # MinIO Object Name으로 동일하게 사용 권장
    original_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_size: Mapped[int] = mapped_column(BigInteger, nullable=False)  # Byte 단위
    mime_type: Mapped[str] = mapped_column(String(100), nullable=False)
    bucket_name: Mapped[str] = mapped_column(String(50), nullable=False)

    # 파일이 연결된 도메인 및 레코드 식별자 (다형성 연결)
    ref_domain: Mapped[Optional[str]] = mapped_column(
        String(50), nullable=True, index=True
    )  # 예: FAC_EQUIP
    ref_id: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_by: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)


class SystemSequence(Base):
    """
    시스템 도메인별 자동 채번(Sequence) 상태를 관리하는 모델입니다.

    도메인이나 시설의 고유 코드를 생성할 때 중복을 방지하기 위해 사용됩니다.
    """

    __tablename__ = "cmm_system_sequences"

    domain_code: Mapped[str] = mapped_column(
        String(50), primary_key=True
    )  # 예: FAC_WORK_ORDER
    current_seq: Mapped[int] = mapped_column(BigInteger, default=0, nullable=False)
    prefix: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
