"""인증 및 권한(IAM) 도메인의 데이터베이스 모델을 정의하는 모듈입니다."""

from datetime import datetime
from typing import TYPE_CHECKING, Any

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.usr.models import User


class Role(Base):
    """시스템 역할(Role) 정보를 저장하는 SQLAlchemy 모델입니다."""

    __tablename__ = "roles"
    __table_args__ = {
        "schema": "iam",
        "comment": "시스템 내 역할(Role) 및 권한(Permission) 정의 테이블",
    }

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # 메뉴/기능별 권한 매트릭스 (JSONB)
    permissions: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict, server_default="'{}'::jsonb"
    )
    is_system: Mapped[bool] = mapped_column(Boolean, default=False)

    # 감사 로그
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    # Relationships
    users: Mapped[list["User"]] = relationship(
        "User", secondary="iam.user_roles", back_populates="roles"
    )


class UserRole(Base):
    """사용자와 역할(Role) 간의 N:M 매핑 테이블 모델입니다."""

    __tablename__ = "user_roles"
    __table_args__ = {"schema": "iam", "comment": "사용자와 역할 간의 N:M 매핑 테이블"}

    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("usr.users.id", ondelete="CASCADE"), primary_key=True
    )
    role_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("iam.roles.id", ondelete="CASCADE"), primary_key=True
    )

    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    assigned_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
