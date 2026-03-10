"""사용자(User) 및 조직(Organization) 도메인의 데이터 검증 및 직렬화를 위한 Pydantic 스키마 정의 모듈입니다.

이 모듈은 사용자 및 조직의 조회 및 생성/수정/조회 시 사용되는 데이터
"""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

# --------------------------------------------------------
# [Organization] 조직(부서) 관련 스키마
# --------------------------------------------------------


class OrgBase(BaseModel):
    """조직의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(..., min_length=2, max_length=100)
    code: str = Field(..., min_length=2, max_length=50)
    parent_id: int | None = None
    sort_order: int = 10
    description: str | None = Field(None, max_length=255, description="조직 상세 설명 (비고)")
    is_active: bool = True


class OrgCreate(OrgBase):
    """조직 생성 시 사용하는 스키마입니다."""

    pass


class OrgUpdate(BaseModel):
    """조직 정보 수정 시 사용하는 스키마입니다."""

    name: str | None = None
    code: str | None = None
    parent_id: int | None = None
    sort_order: int | None = None
    description: str | None = None
    is_active: bool | None = None


class OrgRead(OrgBase):
    """조직 조회 시 반환되는 스키마입니다."""

    id: int
    children: list["OrgRead"] = []

    # 감사 필드 추가
    created_at: datetime
    created_by: int | None = None
    updated_at: datetime
    updated_by: int | None = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [User] 사용자 관련 스키마
# --------------------------------------------------------


class UserBase(BaseModel):
    """사용자의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(..., min_length=2, max_length=100)
    emp_code: str = Field(..., min_length=1, max_length=16, description="사번")
    email: str = Field(..., max_length=100, description="이메일 (소문자 자동 변환)")
    phone: str | None = Field(None, max_length=50)
    org_id: int | None = Field(None, description="소속 조직 ID")
    is_active: bool = True
    account_status: str = Field("ACTIVE", description="계정 상태 (ACTIVE: 정상, BLOCKED: 차단)")
    profile_image_id: uuid.UUID | None = Field(None, description="프로필 이미지 ID")
    user_metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="추가 속성 (직급, 직책 등)",
        alias="metadata",
    )

    @field_validator("email")
    @classmethod
    def to_lower_email(cls, v: str) -> str:
        """입력된 이메일을 모두 소문자로 변환합니다."""
        return v.lower()


class UserCreate(UserBase):
    """사용자 생성 시 사용하는 스키마입니다."""

    login_id: str = Field(..., min_length=4, max_length=50, pattern=r"^[a-z0-9_]+$")
    password: str = Field(..., min_length=8, description="초기 비밀번호")

    @field_validator("login_id")
    @classmethod
    def to_lower_login_id(cls, v: str) -> str:
        """입력된 로그인 ID를 모두 소문자로 변환합니다."""
        return v.lower()


class UserUpdate(BaseModel):
    """사용자 정보 수정 시 사용하는 스키마입니다."""

    name: str | None = None
    email: str | None = None
    phone: str | None = None
    org_id: int | None = None
    is_active: bool | None = None
    user_metadata: dict[str, Any] | None = Field(None, alias="metadata")
    profile_image_id: uuid.UUID | None = None


class UserPasswordUpdate(BaseModel):
    """사용자 비밀번호 변경 시 사용하는 스키마입니다."""

    current_password: str
    new_password: str = Field(..., min_length=8)


class UserRead(UserBase):
    """사용자 조회 시 반환되는 스키마입니다."""

    id: int
    login_id: str
    profile_image_id: uuid.UUID | None = None
    login_fail_count: int = 0
    last_login_at: datetime | None = None
    org_name: str | None = None  # 프론트엔드 표시용 필드

    # 감사 필드 추가
    created_at: datetime
    created_by: int | None = None
    updated_at: datetime
    updated_by: int | None = None

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
    )

    @model_validator(mode="before")
    @classmethod
    def wrap_data(cls, data: Any) -> Any:
        """데이터 변환 및 필드 매핑 처리를 수행합니다."""
        if not isinstance(data, dict):
            # SQLAlchemy 모델 객체인 경우
            # 1. metadata 처리
            meta_val = getattr(data, "metadata", None)
            user_meta = meta_val if isinstance(meta_val, dict) else {}
            
            # 2. org_name 매핑 (중요: relationship인 organization에서 name 추출)
            org_name = None
            org_obj = getattr(data, "organization", None)
            if org_obj:
                org_name = getattr(org_obj, "name", None)

            return {
                k: getattr(data, k, None)
                for k in cls.model_fields.keys()
                if k not in ["user_metadata", "org_name"]
            } | {"user_metadata": user_meta, "org_name": org_name}
        return data


class UserListRead(BaseModel):
    """페이징 처리가 포함된 사용자 목록 응답 스키마입니다."""

    items: list[UserRead]
    total: int


# Pydantic이 'OrgRead' 내부의 자기 참조 타입을 명확히 해석하도록 리빌드합니다.
OrgRead.model_rebuild()
