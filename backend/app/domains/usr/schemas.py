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
    metadata: dict[str, Any] = Field(default_factory=dict, description="추가 속성 (직급, 직책 등)")

    @field_validator("email")
    @classmethod
    def to_lower_email(cls, v: str) -> str:
        """입력된 이메일을 모두 소문자로 변환합니다."""
        return v.lower()


class UserCreate(UserBase):
    """사용자 생성 시 사용하는 스키마입니다."""

    login_id: str = Field(..., min_length=4, max_length=50, pattern=r"^[a-z0-9_]+$")
    password: str = Field(..., min_length=8, description="초기 비밀번호")
    role_ids: list[int] | None = Field(None, description="할당할 역할 ID 리스트")

    @field_validator("login_id")
    @classmethod
    def to_lower_login_id(cls, v: str) -> str:
        """입력된 로그인 ID를 모두 소문자로 변환합니다."""
        return v.lower()


class UserUpdate(BaseModel):
    """사용자 정보 수정 시 사용하는 스키마입니다."""

    name: str | None = None
    emp_code: str | None = None
    email: str | None = None
    phone: str | None = None
    org_id: int | None = None
    is_active: bool | None = None
    account_status: str | None = None
    metadata: dict[str, Any] | None = None
    profile_image_id: uuid.UUID | None = None


class UserPasswordUpdate(BaseModel):
    """사용자 비밀번호 변경 시 사용하는 스키마입니다."""

    current_password: str
    new_password: str = Field(..., min_length=8)


class UserRead(UserBase):
    """사용자 조회 시 반환되는 스키마입니다."""

    id: int
    login_id: str
    is_superuser: bool = False
    profile_image_id: uuid.UUID | None = None
    login_fail_count: int = 0
    last_login_at: datetime | None = None
    org_name: str | None = None
    roles: list[dict[str, Any]] = []

    model_config = ConfigDict(from_attributes=True)

    @model_validator(mode="before")
    @classmethod
    def wrap_data(cls, data: Any) -> Any:
        """데이터 변환 및 필드 매핑 처리를 수행합니다."""
        if not isinstance(data, dict):
            # 1. metadata 매핑 (SQLAlchemy 'metadata' 컬럼 -> Pydantic 'metadata' 필드)
            # SQLAlchemy 모델의 .metadata는 MetaData 객체이므로 .user_metadata 컬럼을 봐야함
            # 하지만 모델에서 이미 이 부분을 처리하고 있을 수 있으므로 안전하게 접근
            user_meta = getattr(data, "user_metadata", {})
            if not isinstance(user_meta, dict):
                user_meta = {}

            # 2. org_name 매핑
            org_name = None
            if hasattr(data, "organization") and data.organization:
                org_name = data.organization.name

            # 3. roles 매핑
            roles_list = []
            if hasattr(data, "roles") and data.roles:
                roles_list = [{"id": r.id, "name": r.name, "code": r.code} for r in data.roles]

            # 4. 명시적 딕셔너리 생성 (필드 누락 방지)
            return {
                "id": data.id,
                "login_id": data.login_id,
                "name": data.name,
                "emp_code": data.emp_code,
                "email": data.email,
                "phone": data.phone,
                "org_id": data.org_id,
                "org_name": org_name,
                "is_active": data.is_active,
                "is_superuser": bool(getattr(data, "is_superuser", False)),
                "account_status": data.account_status,
                "profile_image_id": data.profile_image_id,
                "login_fail_count": data.login_fail_count,
                "last_login_at": data.last_login_at,
                "metadata": user_meta,
                "roles": roles_list,
            }
        return data


class UserListRead(BaseModel):
    """페이징 처리가 포함된 사용자 목록 응답 스키마입니다."""

    items: list[UserRead]
    total: int


# Pydantic이 'OrgRead' 내부의 자기 참조 타입을 명확히 해석하도록 리빌드합니다.
OrgRead.model_rebuild()
