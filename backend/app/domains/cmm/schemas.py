"""공통 관리(CMM) 도메인의 Pydantic 스키마를 정의하는 모듈입니다.

이 모듈은 공통 코드, 첨부파일 메타데이터 및 사용자 알림 정보
교환을 위한 데이터 구조를 정의합니다.
"""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [Common Code] 공통 코드 관련 스키마
# --------------------------------------------------------


class CodeDetailBase(BaseModel):
    """공통 코드 상세의 기본 필드를 정의합니다."""

    detail_code: str = Field(..., max_length=30, description="상세 코드 값")
    detail_name: str = Field(..., max_length=100, description="상세 코드 명칭")
    props: dict[str, Any] = Field(default_factory=dict, description="추가 속성")
    sort_order: int = Field(0, description="정렬 순서")
    is_active: bool = Field(True, description="활성화 여부")


class CodeDetailCreate(CodeDetailBase):
    """공통 코드 상세 생성을 위한 스키마입니다."""

    pass


class CodeDetailUpdate(BaseModel):
    """공통 코드 상세 수정을 위한 스키마입니다."""

    detail_name: str | None = Field(None, max_length=100)
    props: dict[str, Any] | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class CodeDetailRead(CodeDetailBase):
    """공통 코드 상세 조회 응답을 위한 스키마입니다."""

    id: int
    group_code: str

    model_config = ConfigDict(from_attributes=True)


class CodeGroupBase(BaseModel):
    """공통 코드 그룹의 기본 필드를 정의합니다."""

    group_code: str = Field(
        ..., max_length=30, pattern=r"^[A-Z0-9_]+$", description="그룹 식별 코드"
    )
    group_name: str = Field(..., max_length=100, description="그룹 명칭")
    domain_code: str | None = Field(None, max_length=3, description="도메인 구분")
    description: str | None = Field(None, description="상세 설명")
    is_active: bool = Field(True, description="활성화 여부")


class CodeGroupCreate(CodeGroupBase):
    """공통 코드 그룹 생성을 위한 스키마입니다."""

    is_system: bool = Field(False, description="시스템 필수 코드 여부")


class CodeGroupUpdate(BaseModel):
    """공통 코드 그룹 수정을 위한 스키마입니다."""

    group_name: str | None = Field(None, max_length=100)
    description: str | None = None
    is_active: bool | None = None


class CodeGroupRead(CodeGroupBase):
    """공통 코드 그룹 조회 응답을 위한 스키마입니다."""

    id: int
    is_system: bool
    details: list[CodeDetailRead] = Field(default_factory=list)

    model_config = ConfigDict(
        from_attributes=True,
        # 지연 로딩 필드가 로드되지 않았을 경우 무시하거나 에러 방지
        arbitrary_types_allowed=True 
    )


# --------------------------------------------------------
# [Attachment] 첨부 파일 메타데이터 스키마
# --------------------------------------------------------


class AttachmentBase(BaseModel):
    """첨부 파일 메타데이터의 기본 필드를 정의합니다."""

    domain_code: str = Field(..., max_length=3, description="업무 도메인")
    resource_type: str = Field(..., max_length=50, description="리소스 유형")
    ref_id: int = Field(..., description="연결 레코드 PK")
    category_code: str = Field(..., max_length=20, description="분류 코드")
    file_name: str = Field(..., max_length=255, description="원본파일명")
    file_path: str = Field(..., max_length=500, description="저장 경로(Key)")
    file_size: int = Field(0, description="파일 크기(Byte)")
    content_type: str | None = Field(None, description="MIME 타입")
    org_id: int | None = Field(None, description="소유 부서 ID")
    props: dict[str, Any] = Field(default_factory=dict, description="추가 메타데이터")


class AttachmentCreate(AttachmentBase):
    """첨부 파일 메타데이터 생성을 위한 스키마입니다."""

    id: uuid.UUID | None = Field(default_factory=uuid.uuid4)
    created_by: int | None = None


class AttachmentRead(AttachmentBase):
    """첨부 파일 메타데이터 조회 응답을 위한 스키마입니다."""

    id: uuid.UUID
    created_at: datetime
    created_by: int | None = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Notification] 알림 관련 스키마
# --------------------------------------------------------


class NotificationBase(BaseModel):
    """사용자 알림의 기본 필드를 정의합니다."""

    category: str = Field(..., description="알림 카테고리")
    priority: str = Field("NORMAL", description="중요도")
    title: str = Field(..., description="제목")
    content: str | None = Field(None, description="본문")
    link_url: str | None = Field(None, description="이동 링크")
    props: dict[str, Any] = Field(default_factory=dict, description="추가 속성")


class NotificationCreate(NotificationBase):
    """알림 생성을 위한 스키마입니다."""

    receiver_user_id: int
    sender_user_id: int | None = None
    domain_code: str | None = None


class NotificationRead(NotificationBase):
    """알림 조회 응답을 위한 스키마입니다."""

    id: int
    sender_user_id: int | None = None
    is_read: bool
    read_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
