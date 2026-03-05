"""공통 관리(CMM) 도메인의 Pydantic 스키마를 정의하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, ConfigDict, Field


# --------------------------------------------------------
# [AuditLog] 시스템 감사 로그 스키마
# --------------------------------------------------------
class AuditLogBase(BaseModel):
    """감사 로그의 공통 속성을 정의하는 기본 스키마입니다."""

    trace_id: uuid.UUID = Field(..., description="요청 추적을 위한 고유 ID")
    actor_id: Optional[int] = Field(None, description="행위를 수행한 사용자 ID")
    ip_address: Optional[str] = Field(None, description="요청자 IP 주소")
    user_agent: Optional[str] = Field(None, description="요청 브라우저/기기 정보")
    target_domain: str = Field(
        ..., min_length=1, max_length=50, description="대상 도메인 (예: FAC, USR)"
    )
    target_id: str = Field(
        ..., min_length=1, max_length=100, description="대상 레코드 식별자"
    )
    action: str = Field(
        ...,
        min_length=1,
        max_length=20,
        description="수행 액션 (CREATE, UPDATE, DELETE 등)",
    )
    snapshot: Optional[Dict[str, Any]] = Field(
        None, description="변경 전/후 데이터 스냅샷 (JSON)"
    )


class AuditLogCreate(AuditLogBase):
    """감사 로그 생성 시 사용하는 스키마입니다."""

    pass


class AuditLogRead(AuditLogBase):
    """감사 로그 조회 시 반환되는 스키마입니다."""

    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)  # ORM 모델 변환 허용


# --------------------------------------------------------
# [Attachment] 첨부 파일 메타데이터 스키마
# --------------------------------------------------------
class AttachmentBase(BaseModel):
    """첨부 파일 메타데이터의 공통 속성을 정의하는 기본 스키마입니다."""

    original_name: str = Field(
        ..., min_length=1, max_length=255, description="원본 파일명"
    )
    file_size: int = Field(..., ge=0, description="파일 크기 (Byte)")
    mime_type: str = Field(
        ..., min_length=1, max_length=100, description="파일 MIME 타입"
    )
    bucket_name: str = Field(
        ..., min_length=1, max_length=50, description="MinIO 버킷명"
    )
    ref_domain: Optional[str] = Field(
        None, description="연결된 도메인명 (예: FAC_EQUIP)"
    )
    ref_id: Optional[int] = Field(None, description="연결된 도메인 레코드 ID")


class AttachmentCreate(AttachmentBase):
    """첨부 파일 메타데이터 생성 시 사용하는 스키마입니다."""

    id: Optional[uuid.UUID] = Field(
        default_factory=uuid.uuid4, description="MinIO Object Name으로 사용할 UUID"
    )
    created_by: Optional[int] = Field(None, description="업로드한 사용자 ID")


class AttachmentRead(AttachmentBase):
    """첨부 파일 메타데이터 조회 시 반환되는 스키마입니다."""

    id: uuid.UUID
    created_at: datetime
    created_by: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [SystemSequence] 시스템 채번 스키마
# --------------------------------------------------------
class SystemSequenceBase(BaseModel):
    """시스템 채번 상태의 공통 속성을 정의하는 기본 스키마입니다."""

    domain_code: str = Field(
        ..., min_length=1, max_length=50, description="도메인 코드 (예: FAC_WORK_ORDER)"
    )
    current_seq: int = Field(..., ge=0, description="현재 시퀀스 번호")
    prefix: Optional[str] = Field(None, max_length=20, description="채번 접두사")


class SystemSequenceRead(SystemSequenceBase):
    """시스템 채번 상태 조회 시 반환되는 스키마입니다."""

    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
