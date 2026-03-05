"""인증 및 권한(IAM) 도메인의 데이터베이스 모델을 정의하는 모듈입니다."""

from datetime import datetime
from typing import TYPE_CHECKING, Any, Dict, List, Optional, Union

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.database import Base

if TYPE_CHECKING:
    from app.domains.usr.models import User


class Role(Base):
    """
    시스템 역할(Role) 정보를 저장하는 SQLAlchemy 모델입니다.

    메뉴별/기능별 세부 권한을 permissions 컬럼(JSONB)에 저장하여 유연성을 확보합니다.
    """

    __tablename__ = "iam_roles"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(50), nullable=False)
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True
    )  # 역할 코드 (대문자)
    description: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # 메뉴/기능별 권한 매트릭스를 JSONB로 저장 (예: {"fac": ["read", "write"]})
    permissions: Mapped[Dict[str, Any]] = mapped_column(
        JSONB, default=dict, server_default="{}"
    )
    is_system: Mapped[bool] = mapped_column(
        Boolean, default=False
    )  # 시스템 기본 역할 여부 (수정/삭제 제한)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
    created_by: Mapped[Optional[int]] = mapped_column(BigInteger, nullable=True)

    # Relationships (다대다 관계 매핑)
    # User 모델은 app.domains.usr.models 모듈에 정의되어 있습니다.
    users: Mapped[List["User"]] = relationship(
        "User", secondary="iam_user_roles", back_populates="roles"
    )


class UserRole(Base):
    """
    사용자와 역할(Role) 간의 다대다(N:M) 관계를 연결하는 매핑(Association) 테이블 모델입니다.
    """

    __tablename__ = "iam_user_roles"

    # 외래 키 설정 시 연결된 사용자나 역할이 삭제되면 매핑 데이터도 자동 삭제되도록 CASCADE 적용
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("usr_users.id", ondelete="CASCADE"), primary_key=True
    )
    role_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("iam_roles.id", ondelete="CASCADE"), primary_key=True
    )
