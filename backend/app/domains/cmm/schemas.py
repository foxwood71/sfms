import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

# --------------------------------------------------------
# [CommonCode] 공통 코드 관련 스키마
# --------------------------------------------------------


class CodeDetailBase(BaseModel):
    """상세 코드의 공통 속성을 정의하는 기본 스키마입니다."""

    detail_code: str = Field(..., min_length=1, max_length=20)
    detail_name: str = Field(..., min_length=1, max_length=100)
    sort_order: int = Field(10, ge=0)
    is_active: bool = Field(True)
    props: dict[str, Any] = Field(default_factory=dict)


class CodeDetailCreate(CodeDetailBase):
    """신규 상세 코드 생성을 위한 스키마입니다."""

    group_code: str


class CodeDetailUpdate(BaseModel):
    """기존 상세 코드 수정을 위한 스키마입니다."""

    detail_name: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None
    props: dict[str, Any] | None = None


class CodeDetailRead(CodeDetailBase):
    """상세 코드 정보 조회 응답을 위한 스키마입니다."""

    group_code: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class CodeGroupBase(BaseModel):
    """코드 그룹의 공통 속성을 정의하는 기본 스키마입니다."""

    group_code: str = Field(..., min_length=2, max_length=50)
    group_name: str = Field(..., min_length=2, max_length=100)
    domain_code: str = Field("SYS", min_length=2, max_length=3)
    description: str | None = Field(None, max_length=255)
    code_length: int = Field(3, ge=0, description="자동 생성 시 코드 길이")
    is_seq_used: bool = Field(True, description="순번 사용 여부")
    is_active: bool = Field(True, description="활성화 여부")
    props: dict[str, Any] = Field(default_factory=dict, description="추가 메타데이터")


class CodeGroupCreate(CodeGroupBase):
    """신규 코드 그룹 생성을 위한 스키마입니다."""

    pass


class CodeGroupUpdate(BaseModel):
    """기존 코드 그룹 수정을 위한 스키마입니다."""

    group_name: str | None = Field(None, min_length=2, max_length=100)
    domain_code: str | None = Field(None, min_length=2, max_length=3)
    description: str | None = None
    code_length: int | None = Field(None, ge=0)
    is_seq_used: bool | None = None
    is_active: bool | None = None
    props: dict[str, Any] | None = None


class CodeGroupRead(CodeGroupBase):
    """코드 그룹 정보 조회 응답을 위한 스키마입니다."""

    id: int
    # 하위 상세 코드 목록
    details: list[CodeDetailRead] = Field(default_factory=list)

    created_at: datetime
    updated_at: datetime
    created_by: int | None = None
    updated_by: int | None = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Excel/Bulk] 대량 등록 관련 스키마
# --------------------------------------------------------


class CodeImportSchema(BaseModel):
    """엑셀 임포트용 단일 행 데이터 스키마입니다."""

    group_code: str
    group_name: str
    domain_code: str = "SYS"
    description: str | None = None
    detail_code: str
    detail_name: str
    sort_order: int = 10
    is_active: bool = True


class CodeBulkImportRequest(BaseModel):
    """공통 코드 엑셀 대량 업로드를 위한 요청 스키마입니다."""

    items: list[CodeImportSchema]


# --------------------------------------------------------
# [Attachment] 첨부파일 관련 스키마
# --------------------------------------------------------


class AttachmentBase(BaseModel):
    """첨부파일 메타데이터 기본 스키마입니다."""

    domain_code: str
    resource_type: str
    # [FIX] ref_id를 선택값으로 보정 (타입 오류 해결)
    ref_id: int | None = None
    category_code: str
    file_name: str
    file_path: str
    file_size: int
    content_type: str | None = None
    org_id: int | None = None
    props: dict[str, Any] = Field(default_factory=dict)


class AttachmentCreate(AttachmentBase):
    """신규 첨부파일 등록을 위한 스키마입니다."""

    id: uuid.UUID | None = None
    created_by: int | None = None


class AttachmentRead(AttachmentBase):
    """첨부파일 정보 조회 응답을 위한 스키마입니다."""

    id: uuid.UUID
    is_deleted: bool
    created_at: datetime
    updated_at: datetime
    created_by: int | None = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Notification] 알림 관련 스키마
# --------------------------------------------------------


class NotificationRead(BaseModel):
    """수신된 알림 정보 조회를 위한 스키마입니다."""

    id: int
    sender_user_id: int | None = None
    receiver_user_id: int
    domain_code: str = "SYS"
    action_type: str
    title: str
    content: str
    is_read: bool = False
    read_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
