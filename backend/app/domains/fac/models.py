"""시설 및 공간 관리(FAC) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 공통 코드 체계와 통합된 시설 및 공간 관리 구조를 정의합니다.
참조 표준: ID 기반 참조에서 3자리 영문 코드(String) 기반 참조로 전환.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

# --------------------------------------------------------
# [Base Views] 공통 코드 통합 조회용 뷰 모델
# --------------------------------------------------------


class FacilityCategory(Base):
    """시설물 유형 분류 뷰 (공통 코드 통합).

    이 모델은 데이터베이스 뷰(fac.v_facility_categories)를 참조하며,
    공통 코드(cmm.code_details) 중 'FAC_CAT' 그룹을 필터링하여 제공합니다.
    """

    __tablename__ = "v_facility_categories"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


class SpaceType(Base):
    """공간 물리적 유형 뷰 (공통 코드 통합).

    이 모델은 데이터베이스 뷰(fac.v_space_types)를 참조하며,
    공통 코드(cmm.code_details) 중 'SPC_TYP' 그룹을 필터링하여 제공합니다.
    """

    __tablename__ = "v_space_types"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


class SpaceFunction(Base):
    """공간 용도/기능 분류 뷰 (공통 코드 통합).

    이 모델은 데이터베이스 뷰(fac.v_space_functions)를 참조하며,
    공통 코드(cmm.code_details) 중 'SPC_FNC' 그룹을 필터링하여 제공합니다.
    """

    __tablename__ = "v_space_functions"
    __table_args__ = {"schema": "fac", "info": {"view": True}}

    code: Mapped[str] = mapped_column(String(3), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    sort_order: Mapped[int] = mapped_column(Integer)


# --------------------------------------------------------
# [Main Models] 시설 및 공간 관리 메인 테이블
# --------------------------------------------------------


class Facility(Base):
    """최상위 시설(사업소, 처리장 등) 정보를 저장하는 모델입니다.

    모든 자산 및 공간의 최상위 루트가 되며, 시설별 메타데이터를 관리합니다.
    """

    __tablename__ = "facilities"
    __table_args__ = {"schema": "fac", "comment": "최상위 시설(사업소/처리장) 정보 관리 테이블"}

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="시설 고유 ID"
    )
    category_code: Mapped[str] = mapped_column(
        String(3), nullable=False, comment="시설 분류 코드 (FAC_CAT)"
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="시설 명칭")
    code: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        nullable=False,
        index=True,
        comment="시설 식별 코드 (예: HEADQUARTER)",
    )

    representative_image_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, comment="대표 이미지 ID (cmm.attachments)"
    )
    metadata_info: Mapped[dict[str, Any]] = mapped_column(
        "metadata",
        JSONB,
        default=dict,
        server_default="'{}'::jsonb",
        comment="추가 메타데이터 (JSON)",
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, comment="사용 여부")
    sort_order: Mapped[int] = mapped_column(Integer, default=10, comment="정렬 순서")

    # [Audit] 감사 로그
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), comment="생성 일시"
    )
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="생성자 ID"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        comment="수정 일시",
    )
    updated_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="수정자 ID"
    )

    # Relationships
    spaces: Mapped[list[Space]] = relationship("Space", back_populates="facility")


class Space(Base):
    """시설 내 공간(건물, 층, 호실 등) 정보를 저장하는 모델입니다.

    자기 참조(Self-referential) 관계를 통해 계층적 구조를 형성하며,
    부서(USR 도메인)와 연계되어 관리 책임을 정의합니다.
    """

    __tablename__ = "spaces"
    __table_args__ = {"schema": "fac", "comment": "시설 하위 공간(건축물/층/실) 계층 정보 테이블"}

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="공간 고유 ID"
    )
    facility_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("fac.facilities.id", ondelete="CASCADE"),
        nullable=False,
        comment="소속 시설 ID",
    )
    parent_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("fac.spaces.id", ondelete="RESTRICT"),
        nullable=True,
        comment="상위 공간 ID (최상위 공간은 NULL)",
    )

    org_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("usr.organizations.id", ondelete="SET NULL"),
        nullable=True,
        comment="관리 책임 부서 ID",
    )

    space_type_code: Mapped[str] = mapped_column(
        String(3), nullable=False, comment="공간 물리적 유형 (SPC_TYP)"
    )
    space_func_code: Mapped[str | None] = mapped_column(
        String(3), nullable=True, comment="공간 용도/기능 분류 (SPC_FNC)"
    )

    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="공간 명칭")
    area_size: Mapped[float | None] = mapped_column(
        Numeric(precision=10, scale=2), nullable=True, comment="바닥 면적 (sqm)"
    )

    representative_image_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, comment="공간 사진 ID"
    )
    metadata_info: Mapped[dict[str, Any]] = mapped_column(
        "metadata",
        JSONB,
        default=dict,
        server_default="'{}'::jsonb",
        comment="추가 정보 (JSON)",
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=10)
    is_restricted: Mapped[bool] = mapped_column(
        Boolean, default=False, comment="출입 제한 구역 여부"
    )

    # [Audit] 감사 로그
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), comment="생성 일시"
    )
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="생성자 ID"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        comment="수정 일시",
    )
    updated_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="수정자 ID"
    )

    # Relationships
    facility: Mapped[Facility] = relationship("Facility", back_populates="spaces")
    children: Mapped[list[Space]] = relationship(
        "Space",
        back_populates="parent",
        cascade="all, delete-orphan",
        remote_side=[parent_id],
    )
    parent: Mapped[Space | None] = relationship(
        "Space", back_populates="children", remote_side=[id]
    )
