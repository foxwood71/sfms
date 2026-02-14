"""CMM (Common Module Management) Pydantic 스키마 정의.

FastAPI 요청/응답 데이터 검증 및 직렬화.
SQLAlchemy ORM 모델 ↔ JSON 변환 지원 (from_attributes=True).
"""

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class CodeGroupCreate(BaseModel):
    """코드그룹 생성 요청 스키마.

    POST /cmm/groups 엔드포인트 입력 데이터.

    Attributes:
        group_code: 고유 그룹코드 (PK, 최대 30자).
        group_name: 그룹명 (필수, 최대 100자).
        description: 그룹 설명 (선택).
        is_active: 활성화 여부 (기본: True).
        is_system: 시스템 기본코드 여부 (기본: False).

    """

    group_code: str
    group_name: str
    description: str | None = None
    is_active: bool = True
    is_system: bool = False


class CodeDetailCreate(BaseModel):
    """코드 상세 생성 요청 스키마

    POST /cmm/groups/details 엔드포인트 입력 데이터.

    Attributes:
        group_code: 고유 그룹코드 (PK, 최대 30자).
        detail_code: 고유 상세코드 (PK, 최대 30자).
        detail_name: 코드명 (필수, 최대 100자).
        props: 확장 속성 (색상, 아이콘 등).
        sort_order: 정렬 순서 (기본: 0).
        is_active: 활성화 여부 (기본: True).
    """

    group_code: str
    detail_code: str
    detail_name: str
    props: dict[str, Any] | None = {}
    sort_order: int = 0
    is_active: bool = True


class CodeGroupUpdate(BaseModel):
    """코드 그룹 수정 요청 스키마"""

    group_name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class CodeDetailUpdate(BaseModel):
    """코드 상세 수정 요청 스키마"""

    detail_name: Optional[str] = None
    props: Optional[dict[str, Any]] = None
    sort_order: Optional[int] = None
    is_active: Optional[bool] = None


class CodeGroupResponse(BaseModel):
    """코드그룹 조회 응답 스키마.

    GET /cmm/groups 반환 데이터.
    SQLAlchemy ORM → JSON 직렬화 지원.

    Attributes:
        group_code: 그룹코드 (PK).
        group_name: 그룹명.
        description: 설명.
        is_active: 활성화 상태.
        is_system: 시스템 코드 여부.

    """

    group_code: str
    group_name: str
    description: str | None = None
    is_active: bool
    is_system: bool

    model_config = ConfigDict(from_attributes=True)


class CodeDetailResponse(BaseModel):
    """코드상세 조회 응답 스키마.

    코드그룹 내 개별 코드 정보.
    JSONB props 필드 직렬화 지원.

    Attributes:
        detail_code: 상세코드 (PK).
        detail_name: 코드명.
        props: 확장 속성 (JSONB → dict).
        sort_order: 정렬 순서.
        is_active: 활성화 상태.

    """

    detail_code: str
    detail_name: str
    props: dict[str, Any] | None = {}  # JSONB 대응
    sort_order: int
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class SequenceResponse(BaseModel):
    """시퀀스 번호 응답 스키마.

    자동 ID 생성 시 사용 (예: ref_id).

    Attributes:
        sequence: 생성된 시퀀스 문자열 (예: "FAC-001").

    """

    sequence: str


class AttachmentCreate(BaseModel):
    """파일 정보 등록용 내부 스키마."""

    domain_code: str
    ref_id: str
    file_name: str
    file_path: str
    file_size: int
    content_type: str


class AttachmentUpdate(BaseModel):
    """첨부파일 메타데이터 수정 요청 스키마

    PATCH /cmm/attachments/{file_id} 엔드포인트에서 사용.

    Attributes:
        ref_id: 연관 업무 데이터 ID 수정 (예: 잘못 연결된 시설 ID 변경)[cite: 9].
        file_name: 사용자에게 노출되는 원본 파일명 수정[cite: 9].
    """

    ref_id: str | None = None
    file_name: str | None = None


class AttachmentResponse(BaseModel):
    """파일 첨부 조회 응답 스키마.

    MinIO 업로드 후 cmm.attachments 반환 데이터.

    Attributes:
        file_id: UUID 고유 파일 ID.
        domain_code: 도메인 코드.
        ref_id: 연관 데이터 ID.
        file_name: 원본 파일명.
        file_size: 파일 크기 (bytes).
        content_type: MIME 타입.
        created_at: 업로드 일시.

    """

    file_id: UUID
    domain_code: str
    ref_id: str
    file_name: str
    file_size: int
    content_type: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
