from pydantic import BaseModel, ConfigDict
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID


# 1. [추가] 그룹 생성 요청 스키마
class CodeGroupCreate(BaseModel):
    group_code: str
    group_name: str
    description: Optional[str] = None
    is_active: bool = True
    is_system: bool = False


# 2. 조회 응답 스키마 (Create와 분리)
class CodeGroupResponse(BaseModel):
    group_code: str
    group_name: str
    description: Optional[str] = None
    is_active: bool
    is_system: bool

    model_config = ConfigDict(from_attributes=True)


class CodeDetailResponse(BaseModel):
    detail_code: str
    detail_name: str
    props: Optional[Dict[str, Any]] = {}  # JSONB 대응
    sort_order: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class SequenceResponse(BaseModel):
    sequence: str


class AttachmentResponse(BaseModel):
    file_id: UUID
    domain_code: str
    ref_id: str
    file_name: str
    file_size: int
    content_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
