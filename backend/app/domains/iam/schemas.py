"""인증 및 권한(IAM) 도메인의 Pydantic 스키마를 정의하는 모듈입니다."""

from datetime import datetime
from enum import Enum
from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.domains.usr.schemas import UserRead


# --------------------------------------------------------
# [Enum] 공통 열거형
# --------------------------------------------------------
class TokenType(str, Enum):
    """발급되는 토큰의 타입을 정의합니다."""

    BEARER = "bearer"


# --------------------------------------------------------
# [Auth] 인증 관련 스키마
# --------------------------------------------------------
class Token(BaseModel):
    """발급된 JWT 토큰 정보를 담는 스키마입니다."""

    access_token: str
    refresh_token: str
    token_type: TokenType = TokenType.BEARER
    expires_in: int  # Access Token 만료 시간 (초 단위)


class LoginRequest(BaseModel):
    """사용자 로그인 요청 시 사용하는 스키마입니다."""

    login_id: str = Field(..., min_length=4, description="사용자 ID (소문자 자동 변환)")
    password: str = Field(..., min_length=6, description="비밀번호")

    @field_validator("login_id")
    @classmethod
    def to_lower_login_id(cls, v: str) -> str:
        """입력된 로그인 ID를 모두 소문자로 변환하여 대소문자 혼동을 방지합니다."""
        return v.lower()


class CurrentUser(BaseModel):
    """현재 로그인한 사용자의 컨텍스트(프로필 및 권한)를 담는 스키마입니다."""

    id: int
    login_id: str
    name: str
    email: EmailStr
    org_id: Optional[int]
    org_name: Optional[str] = None  # UI 표시용 부서명 (Join 결과)
    roles: List[str]  # 부여된 역할 코드 목록 (예: ["ADMIN", "MANAGER"])
    permissions: Dict[str, List[str]]  # 병합된 최종 권한 매트릭스

    model_config = ConfigDict(from_attributes=True)


class MeResponse(BaseModel):
    """내 정보 조회 응답 스키마입니다."""

    user: UserRead

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [IAM] 역할(Role) 관련 스키마
# --------------------------------------------------------
class RoleBase(BaseModel):
    """역할(Role)의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(..., min_length=2, max_length=50)
    code: str = Field(
        ..., pattern=r"^[A-Z0-9_]+$", description="역할 코드 (대문자 및 언더바만 허용)"
    )
    description: Optional[str] = None
    permissions: Dict[str, List[str]] = Field(
        default_factory=dict, description="메뉴/기능별 권한 매트릭스"
    )
    is_system: bool = False  # 시스템 기본 역할 여부 (True일 경우 삭제 불가)


class RoleCreate(RoleBase):
    """역할 생성 시 사용하는 스키마입니다."""

    pass


class RoleUpdate(BaseModel):
    """역할 정보 수정 시 사용하는 스키마입니다."""

    name: Optional[str] = None
    description: Optional[str] = None
    permissions: Optional[Dict[str, List[str]]] = None
    # code(식별자)와 is_system 플래그는 수정 불가하도록 제외


class RoleRead(RoleBase):
    """역할 조회 시 반환되는 스키마입니다."""

    id: int
    created_at: datetime
    updated_at: datetime
    created_by: Optional[int] = None

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [Assignment] 권한 부여 스키마
# --------------------------------------------------------
class UserRoleUpdate(BaseModel):
    """사용자에게 역할을 부여(Full Replace 방식)할 때 사용하는 스키마입니다."""

    user_id: int
    role_ids: List[int] = Field(
        ..., description="부여할 역할 ID 목록 (기존 권한은 모두 덮어씌움)"
    )
