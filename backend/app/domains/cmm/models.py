"""공통 관리(CMM) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 시스템 전반에서 사용되는 공통 코드(기준정보), 통합 첨부파일 관리,
그리고 사용자 알림(Notification)을 위한 SQLAlchemy 모델을 포함합니다.
모든 테이블은 'cmm' 스키마에 정의됩니다.
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


class CodeGroup(Base):
    """공통 코드 그룹(헤더) 정의 모델입니다. (예: USER_TYPE, EQUIP_STATUS)."""

    __tablename__ = "code_groups"
    __table_args__ = {"schema": "cmm", "comment": "공통 코드 그룹 정의 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    group_code: Mapped[str] = mapped_column(String(30), unique=True, nullable=False, index=True)
    domain_code: Mapped[str | None] = mapped_column(String(3), nullable=True)
    group_name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_system: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # Relationships
    details: Mapped[list["CodeDetail"]] = relationship(
        "CodeDetail", back_populates="group", cascade="all, delete-orphan"
    )


class CodeDetail(Base):
    """공통 코드 상세(아이템) 정의 모델입니다. (예: USER_TYPE 그룹 내 '정직원', '계약직')."""

    __tablename__ = "code_details"
    __table_args__ = {"schema": "cmm", "comment": "공통 코드 상세 정의 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    group_code: Mapped[str] = mapped_column(
        String(30), ForeignKey("cmm.code_groups.group_code", ondelete="CASCADE"), nullable=False
    )
    detail_code: Mapped[str] = mapped_column(String(30), nullable=False)
    detail_name: Mapped[str] = mapped_column(String(100), nullable=False)

    props: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="'{}'::jsonb")
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # Relationships
    group: Mapped["CodeGroup"] = relationship("CodeGroup", back_populates="details")


class Attachment(Base):
    """MinIO 객체 스토리지와 연동되는 통합 첨부파일 메타데이터 모델입니다."""

    __tablename__ = "attachments"
    __table_args__ = {"schema": "cmm", "comment": "통합 첨부파일 관리 테이블"}

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    domain_code: Mapped[str] = mapped_column(String(3), nullable=False)
    resource_type: Mapped[str] = mapped_column(String(50), nullable=False)
    ref_id: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)
    category_code: Mapped[str] = mapped_column(String(20), nullable=False)

    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_path: Mapped[str] = mapped_column(String(500), nullable=False, unique=True)
    file_size: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    content_type: Mapped[str | None] = mapped_column(String(100), nullable=True)

    org_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True, index=True, comment="업로드 당시 부서 ID")
    props: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="'{}'::jsonb")
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)


class Notification(Base):
    """사용자 알림 및 메시지 관리 모델입니다."""

    __tablename__ = "notifications"
    __table_args__ = {"schema": "cmm", "comment": "사용자 알림 관리 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    domain_code: Mapped[str | None] = mapped_column(String(3), nullable=True)

    sender_user_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    receiver_user_id: Mapped[int] = mapped_column(BigInteger, nullable=False, index=True)

    category: Mapped[str] = mapped_column(String(20), nullable=False)
    priority: Mapped[str] = mapped_column(String(10), default="NORMAL")

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    content: Mapped[str | None] = mapped_column(Text, nullable=True)
    link_url: Mapped[str | None] = mapped_column(String(500), nullable=True)

    props: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict, server_default="'{}'::jsonb")
    is_read: Mapped[bool] = mapped_column(Boolean, default=False)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_deleted: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
