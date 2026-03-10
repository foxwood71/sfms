"""사용자(User) 및 조직(Organization) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 조직의 계층 구조와 사용자 계정 정보를 관리하기 위한 SQLAlchemy 모델을 포함합니다.
모든 테이블은 'usr' 스키마에 정의됩니다.
"""

import uuid
from datetime import datetime
from typing import TYPE_CHECKING, Any, Optional

from sqlalchemy import (
    BigInteger,
    Boolean,
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
    """조직(부서) 정보를 저장하는 모델입니다.

    자기 참조(Self-referential) 관계를 통해 본부-팀-파트 등의 계층 구조를 형성하며,
    조직별 코드와 정렬 순서를 관리합니다.
    """

    __tablename__ = "organizations"
    __table_args__ = {"schema": "usr", "comment": "조직(부서) 계층 정보 관리 테이블"}

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="조직 고유 ID"
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="조직 명칭")
    code: Mapped[str] = mapped_column(
        String(50),
        unique=True,
        nullable=False,
        index=True,
        comment="조직 식별 코드 (대문자)",
    )

    parent_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("usr.organizations.id", ondelete="RESTRICT"),
        nullable=True,
        comment="상위 조직 ID (최상위 조직은 NULL)",
    )

    sort_order: Mapped[int] = mapped_column(default=0, comment="정렬 순서")
    description: Mapped[str | None] = mapped_column(
        String(255), nullable=True, comment="조직 상세 설명"
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, comment="사용 여부")

    # [Migration] 레거시 데이터 이관용
    legacy_id: Mapped[int | None] = mapped_column(
        Integer, nullable=True, comment="레거시 시스템 ID"
    )
    legacy_source: Mapped[str | None] = mapped_column(
        String(20), nullable=True, comment="데이터 원천"
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
    children: Mapped[list["Organization"]] = relationship(
        "Organization", back_populates="parent", cascade="all, delete-orphan"
    )
    parent: Mapped[Optional["Organization"]] = relationship(
        "Organization", back_populates="children", remote_side=[id]
    )
    users: Mapped[list["User"]] = relationship("User", back_populates="organization")


class User(Base):
    """시스템 사용자(임직원) 정보를 저장하는 모델입니다.

    로그인 정보, 사번, 연락처 및 프로필 정보를 관리하며,
    IAM 도메인의 역할(Role) 모델과 다대다 관계를 맺습니다.
    """

    __tablename__ = "users"
    __table_args__ = {
        "schema": "usr",
        "comment": "시스템 사용자(임직원) 계정 정보 테이블",
    }

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="사용자 고유 ID"
    )
    login_id: Mapped[str] = mapped_column(
        String(50), unique=True, nullable=False, index=True, comment="로그인 계정 ID"
    )
    password_hash: Mapped[str] = mapped_column(
        String(255), nullable=False, comment="암호화된 비밀번호"
    )
    emp_code: Mapped[str] = mapped_column(
        String(16), unique=True, nullable=False, index=True, comment="사원 번호"
    )
    name: Mapped[str] = mapped_column(String(100), nullable=False, comment="성명")
    email: Mapped[str] = mapped_column(
        String(100), unique=True, nullable=False, index=True, comment="이메일 주소"
    )
    phone: Mapped[str | None] = mapped_column(
        String(50), nullable=True, comment="연락처"
    )

    org_id: Mapped[int | None] = mapped_column(
        BigInteger,
        ForeignKey("usr.organizations.id", ondelete="SET NULL"),
        nullable=True,
        comment="소속 조직 ID",
    )

    profile_image_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True, comment="프로필 이미지 ID (cmm.attachments)"
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, comment="재직 여부 (True: 재직, False: 퇴사)"
    )
    account_status: Mapped[str] = mapped_column(
        String(20), default="ACTIVE", nullable=False, comment="계정 상태 (ACTIVE: 정상, BLOCKED: 차단)"
    )
    login_fail_count: Mapped[int] = mapped_column(
        Integer, default=0, nullable=False, comment="로그인 실패 횟수"
    )
    last_login_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="최근 로그인 일시"
    )

    # [Migration] 레거시 데이터 이관용
    legacy_id: Mapped[int | None] = mapped_column(
        Integer, nullable=True, comment="레거시 시스템 ID"
    )
    legacy_source: Mapped[str | None] = mapped_column(
        String(20), nullable=True, comment="데이터 원천"
    )

    user_metadata: Mapped[dict[str, Any]] = mapped_column(
        "metadata",
        JSONB,
        default=dict,
        server_default="'{}'::jsonb",
        comment="추가 메타데이터",
    )

    # [Audit] 감사 로그
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), comment="계정 생성 일시"
    )
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="생성자 ID"
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        comment="정보 수정 일시",
    )
    updated_by: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, comment="수정자 ID"
    )

    # Relationships
    organization: Mapped[Optional["Organization"]] = relationship(
        "Organization", back_populates="users"
    )
    roles: Mapped[list["Role"]] = relationship(
        "Role", secondary="iam.user_roles", back_populates="users"
    )

    @property
    def is_superuser(self) -> bool:
        """사용자가 관리자 권한을 가졌는지 확인하는 프로퍼티입니다.

        'ADMIN' 또는 'SUPER_ADMIN' 역할 코드를 보유한 경우 True를 반환합니다.

        Returns:
            bool: 관리자 여부

        """
        try:
            if not self.roles:
                return False
            return any(role.code in ["ADMIN", "SUPER_ADMIN"] for role in self.roles)
        except Exception:
            return False
