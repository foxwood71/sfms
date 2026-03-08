"""시스템 관리(SYS) 도메인의 데이터베이스 모델을 정의하는 모듈입니다.

이 모듈은 시스템 전반에서 사용되는 보안 감사 로그 및 문서 번호 자동 채번
규칙을 관리하기 위한 모델을 포함합니다. 모든 테이블은 'sys' 스키마에 정의됩니다.
"""

from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    Boolean,
    DateTime,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql import func

from app.core.database import Base


class AuditLog(Base):
    """시스템 전반의 CRUD 행위 및 주요 보안 이벤트를 기록하는 감사 로그 모델입니다.

    PGroonga 인덱스를 사용하여 대량의 로그 내 snapshot(JSONB) 및 description(TEXT) 필드에 대한
    고속 전문 검색을 지원합니다.
    """

    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("idx_sys_audit_target_lookup", "target_table", "target_id"),
        Index("idx_sys_audit_desc_pg", "description", postgresql_using="pgroonga"),
        Index("idx_sys_audit_snap_pg", "snapshot", postgresql_using="pgroonga"),
        {"schema": "sys", "comment": "시스템 감사 로그 및 주요 행위 추적 테이블"},
    )

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="로그 ID"
    )
    actor_user_id: Mapped[int | None] = mapped_column(
        BigInteger, nullable=True, index=True, comment="수행 사용자 ID"
    )
    action_type: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="행위 유형 (CREATE, LOGIN 등)"
    )

    target_domain: Mapped[str] = mapped_column(
        String(3), nullable=False, comment="대상 도메인 코드"
    )
    target_table: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="대상 테이블명"
    )
    target_id: Mapped[str] = mapped_column(
        String(50), nullable=False, comment="대상 레코드 식별자"
    )

    snapshot: Mapped[dict[str, Any]] = mapped_column(
        JSONB, default=dict, server_default="'{}'::jsonb", comment="변경 데이터 스냅샷"
    )
    client_ip: Mapped[str | None] = mapped_column(
        String(50), nullable=True, comment="클라이언트 IP"
    )
    user_agent: Mapped[str | None] = mapped_column(
        Text, nullable=True, comment="브라우저/기기 정보"
    )
    description: Mapped[str | None] = mapped_column(
        Text, nullable=True, comment="상세 설명 (전문검색 대상)"
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        index=True,
        comment="발생 일시",
    )


class SequenceRule(Base):
    """문서 번호나 코드 자동 생성(채번)을 위한 규칙 정의 모델입니다.

    연도별 초기화(YEARLY) 기능과 접두어 조합 로직을 지원합니다.
    """

    __tablename__ = "sequence_rules"
    __table_args__ = {
        "schema": "sys",
        "comment": "문서 번호 자동 채번 규칙 정의 테이블",
    }

    id: Mapped[int] = mapped_column(
        BigInteger, primary_key=True, autoincrement=True, comment="규칙 ID"
    )
    domain_code: Mapped[str] = mapped_column(
        String(3), nullable=False, comment="적용 도메인"
    )
    prefix: Mapped[str] = mapped_column(
        String(10), nullable=False, comment="문서 접두어"
    )
    year_format: Mapped[str] = mapped_column(
        String(4), default="YYYY", comment="연도 표기 (YYYY/YY)"
    )
    separator: Mapped[str] = mapped_column(String(1), default="-", comment="구분자")
    padding_length: Mapped[int] = mapped_column(
        Integer, default=4, comment="순번 자릿수"
    )

    current_year: Mapped[str] = mapped_column(
        String(4), nullable=False, comment="현재 채번 진행 중인 연도"
    )
    current_seq: Mapped[int] = mapped_column(
        BigInteger, default=0, comment="마지막 발급 순번"
    )
    reset_type: Mapped[str] = mapped_column(
        String(10), default="YEARLY", comment="초기화 방식 (YEARLY/NONE)"
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True, comment="사용 여부")

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
