"""SFMS 전역 응답을 처리를 정의하는 모듈입니다."""

from typing import Any

from fastapi import status
from pydantic import BaseModel, ConfigDict, model_validator

from app.core.codes import SuccessCode


class APIResponse[T](BaseModel):
    """표준 API 응답 규격입니다."""

    success: bool = True
    domain: str = "SYS"
    status_code: int = status.HTTP_200_OK
    success_code: int = SuccessCode.SUCCESS.value  # 기본값 복구 (생성 오류 방지)
    data: T | None = None
    message: str = ""

    model_config = ConfigDict(arbitrary_types_allowed=True, from_attributes=True)

    def __init__(self, domain: str = "SYS", **kwargs):
        """위치 인자로 domain을 받을 수 있도록 생성자를 오버라이딩합니다."""
        # 1. domain이 위치 인자로 들어오면 kwargs에 삽입
        kwargs["domain"] = domain

        # 2. success_code가 명시적으로 들어오지 않았다면 기본값 설정
        if "success_code" not in kwargs:
            kwargs["success_code"] = SuccessCode.SUCCESS.value

        super().__init__(**kwargs)

    @model_validator(mode="before")
    @classmethod
    def validate_and_format(cls, data: Any) -> Any:
        """데이터 입력 시 도메인 보정 및 메시지 매핑을 수행합니다."""
        if isinstance(data, cls):
            return data.model_dump()

        if isinstance(data, dict):
            # 1. 도메인 보정
            domain = data.get("domain", "SYS")
            data["domain"] = str(domain).strip().upper()[:3]

            # 2. 성공 코드 처리
            raw_code = data.get("success_code")
            if raw_code is not None:
                if isinstance(raw_code, SuccessCode):
                    data["success_code"] = raw_code.value
                    if not data.get("message"):
                        data["message"] = raw_code.message
                else:
                    try:
                        data["success_code"] = int(raw_code)
                    except (ValueError, TypeError):
                        data["success_code"] = SuccessCode.SUCCESS.value

            # 3. 기본 메시지 설정
            if not data.get("message"):
                try:
                    matched_enum = SuccessCode(data.get("success_code", 2000))
                    data["message"] = matched_enum.message
                except ValueError:
                    data["message"] = "SUCCESS"

        return data
