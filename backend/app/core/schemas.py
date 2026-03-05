"""시스템 전역에서 사용하는 공통 Pydantic 스키마를 정의합니다."""

from typing import Any, Generic, Optional, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class APIResponse(BaseModel, Generic[T]):
    """표준 API 응답 규격입니다."""

    success: bool
    code: int
    message: str
    data: Optional[T] = None
