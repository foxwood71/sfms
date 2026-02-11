from pydantic import BaseModel, ConfigDict
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID


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
