"""시설 및 공간 관리(FAC) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 시설 카테고리, 공간 유형 등 기초 코드 정보와
최상위 시설(사업소/처리장), 세부 공간(건물/층/실) 계층 구조를 관리합니다.
모든 테이블은 'fac' 스키마에 정의됩니다.
"""

import uuid
from datetime import datetime
from typing import Any, Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


class FacilityCategory(Base):
    """시설물 유형 분류 모델 (예: 하수처리장, 펌프장)."""

    __tablename__ = "facility_categories"
    __table_args__ = {"schema": "fac", "comment": "시설물 유형 분류 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)


class SpaceType(Base):
    """공간의 물리적 유형 정의 모델 (예: 건물, 층, 호실)."""

    __tablename__ = "space_types"
    __table_args__ = {"schema": "fac", "comment": "공간 물리적 유형 정의 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class SpaceFunction(Base):
    """공간의 기능적 용도 정의 모델 (예: 전기실, 사무실)."""

    __tablename__ = "space_functions"
    __table_args__ = {"schema": "fac", "comment": "공간 기능적 용도 정의 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )


class Facility(Base):
    """최상위 시설물(사업소/처리장) 정보 모델입니다."""

    __tablename__ = "facilities"
    __table_args__ = {"schema": "fac", "comment": "최상위 시설물 정보 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    category_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("fac.facility_categories.id")
    )
    representative_image_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )

    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    address: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)

    metadata_info: Mapped[dict[str, Any]] = mapped_column(
        "metadata", JSONB, default=dict, server_default="'{}'::jsonb"
    )
    legacy_id: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # Relationships
    spaces: Mapped[list["Space"]] = relationship("Space", back_populates="facility")


class Space(Base):
    """시설물 내부의 공간 계층(Tree) 관리 모델입니다. (건물 -> 층 -> 구역)."""

    __tablename__ = "spaces"
    __table_args__ = {"schema": "fac", "comment": "시설물 내부 공간 계층 관리 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    facility_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("fac.facilities.id", ondelete="CASCADE"), nullable=False
    )
    parent_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("fac.spaces.id", ondelete="CASCADE"), nullable=True
    )

    representative_image_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    space_type_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("fac.space_types.id")
    )
    space_function_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("fac.space_functions.id")
    )

    code: Mapped[str] = mapped_column(String(50), nullable=False)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    area_size: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
    is_restricted: Mapped[bool] = mapped_column(Boolean, default=False)

    org_id: Mapped[int | None] = mapped_column(
        BigInteger, index=True, comment="관리 책임 부서 ID"
    )
    metadata_info: Mapped[dict[str, Any]] = mapped_column(
        "metadata", JSONB, default=dict, server_default="'{}'::jsonb"
    )
    legacy_id: Mapped[int | None] = mapped_column(Integer, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # Relationships
    facility: Mapped["Facility"] = relationship("Facility", back_populates="spaces")
    children: Mapped[list["Space"]] = relationship(
        "Space", back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped[Optional["Space"]] = relationship(
        "Space", back_populates="children", remote_side=[id]
    )
