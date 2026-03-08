"""인증 및 권한(IAM) 도메인의 데이터 검증 및 직렬화를 위한 Pydantic 스키마 정의 모듈입니다.

이 모듈은 JWT 토큰, 로그인 요청, 역할(Role) 관리 및 사용자 권한 할당을 위한
데이터 구조를 정의합니다.
"""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator

# --------------------------------------------------------
# [Auth] 인증 관련 스키마
# --------------------------------------------------------


class LoginRequest(BaseModel):
    """로그인 요청을 위한 스키마입니다."""

    login_id: str = Field(..., description="사용자 로그인 ID")
    password: str = Field(..., description="비밀번호")


class Token(BaseModel):
    """인증 성공 후 발급되는 토큰 정보를 담는 스키마입니다."""

    access_token: str = Field(..., description="액세스 토큰 (JWT)")
    refresh_token: str = Field(..., description="리프레시 토큰 (JWT)")
    expires_in: int = Field(..., description="액세스 토큰 만료 시간 (초)")
    token_type: str = "bearer"


# --------------------------------------------------------
# [Role] 역할 관리 관련 스키마
# --------------------------------------------------------


class RoleBase(BaseModel):
    """역할의 공통 속성을 정의하는 기본 스키마입니다."""

    name: str = Field(
        ..., min_length=2, max_length=100, description="역할 명칭 (예: 슈퍼 관리자)"
    )
    code: str = Field(
        ..., min_length=2, max_length=50, description="역할 식별 코드 (예: ADMIN)"
    )
    description: str | None = Field(None, description="역할 상세 설명")
    permissions: dict[str, Any] = Field(
        default_factory=dict, description="메뉴/기능별 권한 매트릭스 (JSON)"
    )
    is_system: bool = Field(False, description="시스템 필수 역할 여부 (수정/삭제 제한)")


class RoleCreate(RoleBase):
    """신규 역할 생성을 위한 스키마입니다."""

    pass


class RoleUpdate(BaseModel):
    """기존 역할 정보 수정을 위한 스키마입니다."""

    name: str | None = Field(None, min_length=2, max_length=100)
    description: str | None = None
    permissions: dict[str, Any] | None = None
    is_active: bool | None = None


class RoleRead(RoleBase):
    """역할 정보 조회 응답을 위한 스키마입니다."""

    id: int = Field(..., description="고유 ID")
    created_at: datetime = Field(..., description="생성 일시")
    updated_at: datetime = Field(..., description="수정 일시")
    created_by: int | None = Field(None, description="생성자 ID")
    updated_by: int | None = Field(None, description="수정자 ID")

    model_config = ConfigDict(from_attributes=True)


# --------------------------------------------------------
# [UserRole] 사용자 역할 할당 관련 스키마
# --------------------------------------------------------


class UserRoleUpdate(BaseModel):
    """사용자에게 역할 목록을 할당(전체 교체)하기 위한 스키마입니다."""

    user_id: int = Field(..., description="대상 사용자 ID")
    role_ids: list[int] = Field(
        ..., description="할당할 역할 ID 목록 (기존 권한은 삭제됨)"
    )


from app.domains.usr.schemas import UserRead

class UserWithPermissions(UserRead):
    """사용자 정보와 함께 할당된 역할 및 통합 권한 목록을 담는 스키마입니다."""

    roles: list[str] = Field(default_factory=list, description="할당된 역할 코드 목록")
    permissions: dict[str, list[str]] = Field(
        default_factory=dict, description="리소스별 통합 권한 매트릭스"
    )

    @model_validator(mode="before")
    @classmethod
    def fix_sqlalchemy_metadata(cls, data: Any) -> Any:
        """SQLAlchemy 모델에서 데이터를 읽을 때 metadata 충돌을 방지합니다."""
        if not isinstance(data, dict):
            # SQLAlchemy 모델 객체인 경우 (지연 로딩 및 프레임워크 객체 충돌 방지)
            result = {}
            # 부모(UserRead)의 필드들을 수동으로 복사
            for field in cls.model_fields.keys():
                if field == "user_metadata":
                    # DB의 'metadata' 컬럼 값(dict)을 'user_metadata' 필드에 매핑
                    meta_val = getattr(data, "metadata", {})
                    result[field] = meta_val if isinstance(meta_val, dict) else {}
                elif hasattr(data, field):
                    result[field] = getattr(data, field)
            
            # 추가 필드들 명시적 주입
            result["roles"] = getattr(data, "roles", [])
            result["permissions"] = getattr(data, "permissions", {})
            return result
        return data
