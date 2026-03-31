"""인증 및 권한(IAM) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 시스템 역할(Role), 권한 매트릭스, 그리고 사용자와 역할 간의 다대다 매핑 정보를 관리합니다.
모든 테이블은 'iam' 스키마에 정의됩니다.
"""

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
    """시스템 역할(Role) 정보를 저장하는 SQLAlchemy 모델입니다.

    역할별로 메뉴 및 기능에 대한 권한 매트릭스를 JSONB 형식으로 관리하며,
    사용자에게 부여되어 접근 제어의 기준이 됩니다.
    """

    __tablename__ = "roles"
    __table_args__ = {
        "schema": "iam",
        "comment": "시스템 내 역할(Role) 및 권한(Permission) 정의 테이블",
    }

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="역할 고유 ID"
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="역할 명칭")
    code: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True, comment="역할 식별 코드"
    )
    description: Mapped[str | None] = mapped_column(Text, nullable=True, comment="역할 상세 설명")

    # 메뉴/기능별 권한 매트릭스 (JSONB)
    permissions: Mapped[dict[str, Any]] = mapped_column(
        JSONB,
        default=dict,
        server_default="'{}'::jsonb",
        comment="리소스별 액션 권한 매트릭스 (예: {'USER': ['READ', 'WRITE']})",
    )
    is_system: Mapped[bool] = mapped_column(
        Boolean, default=False, comment="시스템 필수 역할 여부 (삭제/수정 제한)"
    )

    # 감사 로그
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), comment="생성 일시"
    )
    created_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True, comment="생성자 ID")
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        comment="수정 일시",
    )
    updated_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True, comment="수정자 ID")

    # Relationships
    users: Mapped[list["User"]] = relationship(
        "User", secondary="iam.user_roles", back_populates="roles"
    )


class UserRole(Base):
    """사용자와 역할(Role) 간의 N:M 매핑 테이블 모델입니다.

    특정 사용자에게 하나 이상의 역할을 부여하여 권한을 위임합니다.
    """

    __tablename__ = "user_roles"
    __table_args__ = {"schema": "iam", "comment": "사용자와 역할 간의 N:M 매핑 테이블"}

    user_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("usr.users.id", ondelete="CASCADE"),
        primary_key=True,
        comment="사용자 ID",
    )
    role_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("iam.roles.id", ondelete="CASCADE"),
        primary_key=True,
        comment="역할 ID",
    )

    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), comment="할당 일시"
    )
    assigned_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True, comment="할당자 ID")
