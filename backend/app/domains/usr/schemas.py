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
    # 'metadata'라는 이름은 SQLAlchemy 모델의 MetaData 객체와 충돌하므로 별도 처리 필요
    user_metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="추가 속성 (직급, 직책 등)",
        alias="metadata",  # JSON 출력 시에는 'metadata'로 나감
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
        """입된 로그인 ID를 모두 소문자로 변환합니다."""
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
    organization_name: str | None = None  # UI 표시용으로 Join된 부서명

    # 감사 필드 추가
    created_at: datetime
    created_by: int | None = None
    updated_at: datetime
    updated_by: int | None = None

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,  # alias와 원래 필드명 모두 허용
    )

    @model_validator(mode="before")
    @classmethod
    def fix_sqlalchemy_metadata(cls, data: Any) -> Any:
        """SQLAlchemy 모델에서 데이터를 읽을 때 metadata 충돌을 방지합니다."""
        if not isinstance(data, dict):
            # SQLAlchemy 모델 객체인 경우
            # 'metadata' 속성이 딕셔너리가 아니라면(즉, MetaData 객체라면) 무시
            meta_val = getattr(data, "metadata", None)
            if not isinstance(meta_val, dict):
                # 실제 DB 컬럼 값이 아닌 프레임워크 객체임.
                # 딕셔너리 형태로 변환하여 반환 데이터에 명시적으로 주입
                # Pydantic이 'user_metadata' 필드를 채울 수 있도록 함
                return {
                    k: getattr(data, k, None)
                    for k in cls.model_fields.keys()
                    if k != "user_metadata"
                } | {"user_metadata": {}}
        return data


# Pydantic이 'OrgRead' 내부의 자기 참조 타입을 명확히 해석하도록 리빌드합니다.
OrgRead.model_rebuild()
