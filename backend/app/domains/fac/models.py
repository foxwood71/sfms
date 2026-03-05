"""시설 및 공간 관리(FAC) 도메인의 데이터베이스 모델을 정의하는 모듈입니다."""

from datetime import datetime
from typing import Any, Dict, List, Optional

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base


class Space(Base):
    """
    공간(사이트, 동, 층, 실) 정보를 저장하는 계층형 트리 모델입니다.
    """

    __tablename__ = "fac_spaces"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )
    space_type: Mapped[str] = mapped_column(
        String(20), nullable=False
    )  # SITE, BLDG, FLOOR, ROOM 등

    parent_id: Mapped[Optional[int]] = mapped_column(
        BigInteger, ForeignKey("fac_spaces.id", ondelete="RESTRICT"), nullable=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    children: Mapped[List["Space"]] = relationship(
        "Space", back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped[Optional["Space"]] = relationship(
        "Space", back_populates="children", remote_side=[id]
    )
    facilities: Mapped[List["Facility"]] = relationship(
        "Facility", back_populates="space"
    )


class Facility(Base):
    """
    공간에 배치되는 개별 설비 및 장비 정보를 저장하는 모델입니다.
    """

    __tablename__ = "fac_facilities"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )

    space_id: Mapped[Optional[int]] = mapped_column(
        BigInteger, ForeignKey("fac_spaces.id", ondelete="SET NULL"), nullable=True
    )

    status: Mapped[str] = mapped_column(
        String(20), default="ACTIVE"
    )  # ACTIVE, MAINTENANCE, BROKEN 등

    # SQLAlchemy metadata 속성 충돌 방지를 위해 파이썬 변수명 변경
    metadata_info: Mapped[Dict[str, Any]] = mapped_column(
        "metadata", JSONB, default=dict, server_default="{}"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    space: Mapped[Optional["Space"]] = relationship(
        "Space", back_populates="facilities"
    )
