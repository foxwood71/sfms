"""시스템 관리(SYS) 도메인의 데이터 검증 및 직렬화를 위한 Pydantic 스키마 정의 모듈입니다.

이 모듈은 감사 로그 조회 및 채번 규칙 생성/수정/조회 시 사용되는
데이터 구조를 정의합니다.
"""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


# --------------------------------------------------------
# [AuditLog] 시스템 감사 로그 스키마
# --------------------------------------------------------
class AuditLogBase(BaseModel):
    """감사 로그의 공용 필드를 정의하는 기본 스키마입니다."""

    actor_user_id: int | None = Field(
        None, description="행위를 수행한 사용자 ID (시스템 작업인 경우 None)"
    )
    action_type: str = Field(
        ...,
        max_length=20,
        description="행위 유형 (C:생성, U:수정, D:삭제, L:로그인 등)",
    )
    target_domain: str = Field(..., max_length=3, description="대상 업무 도메인 코드")
    target_table: str = Field(..., max_length=50, description="대상 데이터 테이블명")
    target_id: str = Field(..., max_length=50, description="대상 데이터의 식별자(PK)")
    snapshot: dict[str, Any] = Field(
        default_factory=dict, description="변경 데이터의 스냅샷 (JSON)"
    )
    client_ip: str | None = Field(
        None, max_length=50, description="요청 클라이언트 IP 주소"
    )
    user_agent: str | None = Field(
        None, description="요청 클라이언트의 User-Agent 정보"
    )
    description: str | None = Field(None, description="행위에 대한 상세 텍스트 설명")


class AuditLogCreate(AuditLogBase):
    """감사 로그 생성을 위한 스키마입니다."""

    pass


class AuditLogRead(AuditLogBase):
    """감사 로그 조회 응답을 위한 스키마입니다."""

    id: int = Field(..., description="로그 고유 ID")
    created_at: datetime = Field(..., description="로그 발생 일시")

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [SequenceRule] 채번 규칙 스키마
# --------------------------------------------------------
class SequenceRuleBase(BaseModel):
    """문서 번호 자동 채번 규칙의 공통 속성을 정의하는 기본 스키마입니다."""

    domain_code: str = Field(
        ..., min_length=3, max_length=3, description="적용할 도메인 코드"
    )
    prefix: str = Field(
        ..., max_length=10, description="문서 번호 접두어 (예: WO, INV)"
    )
    year_format: str = Field(
        "YYYY", max_length=4, description="연도 표시 형식 (YYYY 또는 YY)"
    )
    separator: str = Field("-", max_length=1, description="구성 요소 간 구분자")
    padding_length: int = Field(4, ge=1, le=10, description="일련번호 자릿수 (LPAD)")
    reset_type: str = Field(
        "YEARLY",
        max_length=10,
        description="번호 초기화 방식 (YEARLY: 매년 1로 초기화)",
    )
    is_active: bool = Field(True, description="규칙 활성화 여부")


class SequenceRuleCreate(SequenceRuleBase):
    """신규 채번 규칙 생성을 위한 스키마입니다."""

    current_year: str = Field(
        ..., max_length=4, description="채번을 시작할 기준 연도 (YYYY)"
    )
    current_seq: int = Field(0, description="시작 일련번호")


class SequenceRuleUpdate(BaseModel):
    """기존 채번 규칙 수정을 위한 스키마입니다."""

    prefix: str | None = Field(None, max_length=10)
    year_format: str | None = Field(None, max_length=4)
    separator: str | None = Field(None, max_length=1)
    padding_length: int | None = Field(None, ge=1, le=10)
    is_active: bool | None = None


class SequenceRuleRead(SequenceRuleBase):
    """채번 규칙 조회 응답을 위한 스키마입니다."""

    id: int = Field(..., description="규칙 고유 ID")
    current_year: str = Field(..., description="현재 진행 중인 연도")
    current_seq: int = Field(..., description="마지막 발급된 번호")
    created_at: datetime = Field(..., description="등록 일시")
    updated_at: datetime = Field(..., description="최종 수정 일시")

    model_config = ConfigDict(from_attributes=True)
