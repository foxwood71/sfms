"""공통 관리(CMM) 도메인의 Pydantic 스키마를 정의하는 모듈입니다.

이 모듈은 공통 코드 그룹, 상세 코드, 첨부파일 및 알림 처리를 위한
요청(Request) 및 응답(Response) 데이터 규격을 정의합니다.
"""

import uuid
from datetime import datetime
from typing import Any, Optional, List

from pydantic import BaseModel, ConfigDict, Field


# --------------------------------------------------------
# [CodeDetail] 공통 코드 상세 스키마
# --------------------------------------------------------

class CodeDetailBase(BaseModel):
    """상세 코드의 공통 속성을 정의하는 기본 스키마입니다."""

    group_code: str = Field(..., description="소속 그룹 코드")
    detail_code: str = Field(..., min_length=1, max_length=30, description="상세 식별 코드")
    detail_name: str = Field(..., min_length=1, max_length=100, description="코드 명칭")
    props: dict[str, Any] = Field(default_factory=dict, description="확장 속성")
    sort_order: int = Field(0, description="정렬 순서")
    is_active: bool = Field(True, description="활성화 여부")


class CodeDetailCreate(CodeDetailBase):
    """신규 상세 코드 생성을 위한 스키마입니다."""

    pass


class CodeDetailUpdate(BaseModel):
    """기존 상세 코드 수정을 위한 스키마입니다."""

    detail_name: Optional[str] = Field(None, min_length=1, max_length=100)
    props: Optional[dict[str, Any]] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class CodeDetailRead(CodeDetailBase):
    """상세 코드 정보 조회 응답을 위한 스키마입니다."""

    id: int
    created_at: datetime
    updated_at: datetime
    created_by: Optional[int] = None
    updated_by: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [CodeGroup] 공통 코드 그룹 스키마
# --------------------------------------------------------

class CodeGroupBase(BaseModel):
    """코드 그룹의 공통 속성을 정의하는 기본 스키마입니다."""

    group_code: str = Field(..., min_length=2, max_length=30, description="그룹 식별 코드")
    domain_code: Optional[str] = Field(None, min_length=2, max_length=3, description="도메인 코드")
    group_name: str = Field(..., min_length=2, max_length=100, description="그룹 명칭")
    description: Optional[str] = Field(None, description="상세 설명")
    
    # [SFMS Standard] 코드 규격 관리 필드
    code_length: int = Field(0, ge=0, description="권장 코드 길이 (0: 제한없음)")
    is_seq_used: bool = Field(False, description="순번 생성 엔진 사용 여부")

    is_system: bool = Field(False, description="시스템 필수 여부")
    is_active: bool = Field(True, description="활성화 여부")
    props: dict[str, Any] = Field(default_factory=dict, description="추가 메타데이터")


class CodeGroupCreate(CodeGroupBase):
    """신규 코드 그룹 생성을 위한 스키마입니다."""

    pass


class CodeGroupUpdate(BaseModel):
    """기존 코드 그룹 수정을 위한 스키마입니다."""

    group_name: Optional[str] = Field(None, min_length=2, max_length=100)
    domain_code: Optional[str] = Field(None, min_length=2, max_length=3)
    description: Optional[str] = None
    code_length: Optional[int] = Field(None, ge=0)
    is_seq_used: Optional[bool] = None
    is_active: Optional[bool] = None
    props: Optional[dict[str, Any]] = None


class CodeGroupRead(CodeGroupBase):
    """코드 그룹 정보 조회 응답을 위한 스키마입니다."""

    id: int
    # [Added] 하위 상세 코드 목록 (백엔드에서 joinedload로 채워짐)
    details: List[CodeDetailRead] = Field(default_factory=list)
    
    created_at: datetime
    updated_at: datetime
    created_by: Optional[int] = None
    updated_by: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Excel/Bulk] 대량 등록 관련 스키마
# --------------------------------------------------------

class CodeBulkImportRequest(BaseModel):
    """공통 코드 엑셀 대량 업로드를 위한 요청 스키마입니다."""
    
    groups: List[CodeGroupCreate] = Field(default_factory=list)
    details: List[CodeDetailCreate] = Field(default_factory=list)


# --------------------------------------------------------
# [Attachment] 첨부파일 관련 스키마
# --------------------------------------------------------

class AttachmentBase(BaseModel):
    """첨부파일 메타데이터 기본 스키마입니다."""

    domain_code: str
    resource_type: str
    ref_id: int
    category_code: str
    file_name: str
    file_path: str
    file_size: int
    content_type: Optional[str] = None
    org_id: Optional[int] = None
    props: dict[str, Any] = Field(default_factory=dict)


class AttachmentCreate(AttachmentBase):
    """신규 첨부파일 등록을 위한 스키마입니다."""

    pass


class AttachmentRead(AttachmentBase):
    """첨부파일 정보 조회 응답을 위한 스키마입니다."""

    id: uuid.UUID
    is_deleted: bool
    created_at: datetime
    updated_at: datetime
    created_by: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Notification] 알림 관련 스키마
# --------------------------------------------------------

class NotificationBase(BaseModel):
    """사용자 알림 기본 스키마입니다."""

    domain_code: Optional[str] = None
    receiver_user_id: int
    category: str
    priority: str = "NORMAL"
    title: str
    content: Optional[str] = None
    link_url: Optional[str] = None
    props: dict[str, Any] = Field(default_factory=dict)


class NotificationCreate(NotificationBase):
    """신규 알림 생성을 위한 스키마입니다."""

    pass


class NotificationRead(NotificationBase):
    """알림 정보 조회 응답을 위한 스키마입니다."""

    id: int
    sender_user_id: Optional[int] = None
    is_read: bool
    read_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
