"""시설 및 공간 관리(FAC) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 공통 코드 체계와 통합된 시설 및 공간 관리 구조를 정의합니다.
참조 표준: ID 기반 참조에서 3자리 영문 코드(String) 기반 참조로 전환.
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

# --------------------------------------------------------
# [Base Views] 공통 코드 통합 조회용 뷰 모델
# --------------------------------------------------------

class FacilityCategory(Base):
    """시설물 유형 분류 뷰 (공통 코드 통합)."""
    __tablename__ = "v_facility_categories"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


class SpaceType(Base):
    """공간 물리적 유형 뷰 (공통 코드 통합)."""
    __tablename__ = "v_space_types"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


class SpaceFunction(Base):
    """공간 기능적 용도 뷰 (공통 코드 통합)."""
    __tablename__ = "v_space_functions"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


# --------------------------------------------------------
# [Main Entities] 시설 및 공간 마스터
# --------------------------------------------------------

class Facility(Base):
    """최상위 시설물(사업소/처리장) 정보 모델입니다."""

    __tablename__ = "facilities"
    __table_args__ = {"schema": "fac", "comment": "최상위 시설물 정보 테이블"}

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    
    # [SFMS Code Standard] 코드 기반 참조
    category_group_code: Mapped[str] = mapped_column(String(30), server_default="FAC_CATEGORY")
    category_code: Mapped[str] = mapped_column(String(3), nullable=False)

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
    """시설물 내부의 공간 계층(Tree) 관리 모델입니다."""

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
    
    # [SFMS Code Standard] 코드 기반 참조
    space_type_group_code: Mapped[str] = mapped_column(String(30), server_default="SPACE_TYPE")
    space_type_code: Mapped[str] = mapped_column(String(3), nullable=False)
    
    space_func_group_code: Mapped[str] = mapped_column(String(30), server_default="SPACE_FUNC")
    space_func_code: Mapped[str] = mapped_column(String(3), nullable=False)

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
    legacy_source_tbl: Mapped[str | None] = mapped_column(String(50), nullable=True)

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
        "Space", back_populates="parent", cascade="all, delete-orphan", remote_side=[parent_id]
    )
    parent: Mapped[Optional["Space"]] = relationship(
        "Space", back_populates="children", remote_side=[id]
    )
