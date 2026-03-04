"""사용자(User) 및 조직(Organization) 도메인의 Pydantic 스키마를 정의하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator


# --------------------------------------------------------
# [Organization] 조직(부서) 관련 스키마
# --------------------------------------------------------
class OrgBase(BaseModel):
    """조직의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(..., min_length=2, max_length=100, description="조직 명칭")
    code: str = Field(..., pattern=r"^[A-Z0-9_]+$", description="조직 코드 (대문자)")
    parent_id: Optional[int] = Field(None, description="상위 조직 ID (Root는 None)")
    sort_order: int = Field(0, description="정렬 순서")
    description: Optional[str] = None
    is_active: bool = True


class OrgCreate(OrgBase):
    """조직 생성 시 사용하는 스키마입니다."""

    pass


class OrgUpdate(BaseModel):
    """조직 정보 수정 시 사용하는 스키마입니다."""

    name: Optional[str] = None
    # code는 식별자이므로 수정 불가하도록 제외
    parent_id: Optional[int] = None
    sort_order: Optional[int] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None


class OrgRead(OrgBase):
    """조직 조회 시 반환되는 스키마입니다."""

    id: int
    children: Optional[List["OrgRead"]] = None  # Tree 구조 표현을 위한 재귀적 타입 힌팅
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True
    )  # ORM 모델을 Pydantic 객체로 변환 허용


# --------------------------------------------------------
# [User] 사용자 관련 스키마
# --------------------------------------------------------
class UserBase(BaseModel):
    """사용자의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(..., min_length=2, max_length=100)
    emp_code: str = Field(..., min_length=1, max_length=20, description="사번")
    email: EmailStr = Field(..., description="이메일 (소문자 자동 변환)")
    phone: Optional[str] = Field(None, pattern=r"^\d{2,3}-\d{3,4}-\d{4}$")
    org_id: Optional[int] = Field(None, description="소속 조직 ID")
    is_active: bool = True
    metadata: Dict[str, Any] = Field(
        default_factory=dict, description="추가 속성 (직급, 직책 등)"
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

    name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    org_id: Optional[int] = None
    is_active: Optional[bool] = None
    metadata: Optional[Dict[str, Any]] = None
    profile_image_id: Optional[uuid.UUID] = None


class UserPasswordUpdate(BaseModel):
    """사용자 비밀번호 변경 시 사용하는 스키마입니다."""

    current_password: str
    new_password: str = Field(..., min_length=8)


class UserRead(UserBase):
    """사용자 조회 시 반환되는 스키마입니다."""

    id: int
    login_id: str
    profile_image_id: Optional[uuid.UUID] = None
    last_login_at: Optional[datetime] = None
    organization_name: Optional[str] = None  # UI 표시용으로 Join된 부서명
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
