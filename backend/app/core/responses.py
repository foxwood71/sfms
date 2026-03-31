"""SFMS 전역 응답 처리를 정의하는 모듈입니다.

이 모듈은 모든 API 엔드포인트에서 공통적으로 사용할 표준 응답 규격을 정의합니다.
FastAPI의 제네릭(Generic) 타입을 활용하여 데이터 필드(data)의 타입을 유연하게 정의할 수 있습니다.
"""

from typing import Any

from fastapi import status
from pydantic import BaseModel, ConfigDict, model_validator

from app.core.codes import SuccessCode


class APIResponse[T](BaseModel):
    """표준 API 응답 규격입니다.

    모든 API 요청에 대해 일관된 JSON 구조를 보장하며,
    성공 여부, 도메인 정보, 상태 코드, 결과 데이터 및 메시지를 포함합니다.

    Attributes:
        success (bool): 요청 처리 성공 여부. 기본값은 True.
        domain (str): 처리 주체 도메인 코드 (3자리 대문자). 기본값은 "SYS".
        status_code (int): HTTP 상태 코드. 기본값은 200.
        success_code (int): 비즈니스 성공 코드. SuccessCode enum 값을 따릅니다.
        data (T | None): 실제 반환할 데이터 객체 또는 리스트.
        message (str): 클라이언트에 전달할 결과 메시지.
    """

    success: bool = True
    domain: str = "SYS"
    status_code: int = status.HTTP_200_OK
    success_code: int = SuccessCode.SUCCESS.value
    data: T | None = None
    message: str = ""

    model_config = ConfigDict(arbitrary_types_allowed=True, from_attributes=True)

    def __init__(self, domain: str = "SYS", **kwargs):
        """위치 인자로 domain을 받을 수 있도록 생성자를 오버라이딩합니다.

        Args:
            domain (str): 도메인 식별 코드.
            **kwargs: BaseModel 초기화에 필요한 필드 값들.
        """
        # 1. domain이 위치 인자로 들어오면 kwargs에 삽입
        kwargs["domain"] = domain

        # 2. success_code가 명시적으로 들어오지 않았다면 기본값 설정
        if "success_code" not in kwargs:
            kwargs["success_code"] = SuccessCode.SUCCESS.value

        super().__init__(**kwargs)

    @model_validator(mode="before")
    @classmethod
    def validate_and_format(cls, data: Any) -> Any:
        """데이터 입력 시 도메인 보정 및 메시지 매핑을 수행합니다.

        입력된 데이터가 dict인 경우, 도메인 코드를 대문자 3자리로 정규화하고
        성공 코드에 대응하는 기본 메시지가 없는 경우 자동으로 매핑합니다.

        Args:
            data (Any): 입력받은 로우(Raw) 데이터 또는 dict.

        Returns:
            Any: 정규화 및 포맷팅이 완료된 데이터 dict 또는 객체.
        """
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
