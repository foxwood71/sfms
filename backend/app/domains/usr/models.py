"""사용자(User) 및 조직(Organization) 데이터베이스 모델을 정의하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Union

from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.iam.models import Role


class Organization(Base):
    """
    조직(부서) 정보를 저장하는 SQLAlchemy 모델입니다.

    자기 참조(Self-referential) 외래 키를 사용하여 트리 구조를 형성합니다.
    """

    __tablename__ = "usr_organizations"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )

    # 상위 조직 ID (최상위 조직은 None)
    parent_id: Mapped[Optional[int]] = mapped_column(
        BigInteger,
        ForeignKey("usr_organizations.id", ondelete="RESTRICT"),
        nullable=True,
    )

    sort_order: Mapped[int] = mapped_column(default=0)
    description: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    children: Mapped[List["Organization"]] = relationship(
        "Organization", back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped[Optional["Organization"]] = relationship(
        "Organization", back_populates="children", remote_side=[id]
    )
    users: Mapped[List["User"]] = relationship("User", back_populates="organization")


class User(Base):
    """
    시스템 사용자(사원) 정보를 저장하는 SQLAlchemy 모델입니다.
    """

    __tablename__ = "usr_users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    login_id: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    emp_code: Mapped[str] = mapped_column(
        String(20), unique=True, nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(
        String(255), unique=True, nullable=False, index=True
    )
    phone: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)

    # 소속 조직 ID
    org_id: Mapped[Optional[int]] = mapped_column(
        BigInteger,
        ForeignKey("usr_organizations.id", ondelete="SET NULL"),
        nullable=True,
    )

    profile_image_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    login_fail_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # SQLAlchemy의 내장 metadata 속성과 이름이 충돌하는 것을 방지하기 위해 DB 컬럼명만 "metadata"로 매핑
    user_metadata: Mapped[Dict[str, Any]] = mapped_column(
        "metadata", JSONB, default=dict, server_default="{}"
    )  # 직급, 직책 등 추가 속성 저장용

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    organization: Mapped[Optional["Organization"]] = relationship(
        "Organization", back_populates="users"
    )

    # app/domains/usr/models.py 파일의 User 클래스 하단에 추가
    roles: Mapped[List["Role"]] = relationship(
        "Role", secondary="iam_user_roles", back_populates="users"
    )
