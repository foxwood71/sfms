"""SFMS 전역 커스텀 예외 처리를 정의하는 모듈입니다."""

from typing import Any, Dict, Optional


class SFMSException(Exception):
    """
    SFMS 시스템의 최상위 커스텀 예외 클래스입니다.

    모든 비즈니스 로직 에러는 이 클래스를 상속받아 발생시켜야 합니다.
    """

    def __init__(
        self,
        status_code: int,
        error_code: int,
        message: str,
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        SFMSException 인스턴스를 초기화합니다.

        Args:
            status_code (int): 반환할 HTTP 상태 코드 (예: 400, 404, 500)
            error_code (int): 프론트엔드에서 처리할 내부 커스텀 에러 코드 (예: 4096)
            message (str): 클라이언트에게 전달할 에러 메시지
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        self.status_code = status_code
        self.error_code = error_code
        self.message = message
        self.data = data
        super().__init__(message)


class BadRequestException(SFMSException):
    """잘못된 요청(400) 관련 예외 클래스입니다."""

    def __init__(
        self,
        error_code: int = 4000,
        message: str = "잘못된 요청입니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        BadRequestException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=400,
            error_code=error_code,
            message=message,
            data=data,
        )


class UnauthorizedException(SFMSException):
    """인증 실패(401) 관련 예외 클래스입니다."""

    def __init__(
        self,
        error_code: int = 4010,
        message: str = "인증에 실패했습니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        UnauthorizedException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=401,
            error_code=error_code,
            message=message,
            data=data,
        )


class ForbiddenException(SFMSException):
    """권한 부족(403) 관련 예외 클래스입니다."""

    def __init__(
        self,
        error_code: int = 4030,
        message: str = "해당 리소스에 대한 접근 권한이 없습니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        ForbiddenException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=403,
            error_code=error_code,
            message=message,
            data=data,
        )


class NotFoundException(SFMSException):
    """리소스를 찾을 수 없음(404) 관련 예외 클래스입니다."""

    def __init__(
        self,
        error_code: int = 4040,
        message: str = "요청한 리소스를 찾을 수 없습니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        NotFoundException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=404,
            error_code=error_code,
            message=message,
            data=data,
        )


class ConflictException(SFMSException):
    """데이터 충돌(409) 관련 예외 클래스입니다. (중복 로직 등에 사용)"""

    def __init__(
        self,
        error_code: int = 4090,
        message: str = "데이터 충돌이 발생했습니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        ConflictException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=409,
            error_code=error_code,
            message=message,
            data=data,
        )


class ServiceUnavailableException(SFMSException):
    """서비스 사용 불가(503) 관련 예외 클래스입니다. (DB/Redis 연결 실패 등)"""

    def __init__(
        self,
        error_code: int = 5030,
        message: str = "현재 서비스를 이용할 수 없습니다.",
        data: Optional[Dict[str, Any]] = None,
    ):
        """
        ServiceUnavailableException 인스턴스를 초기화합니다.

        Args:
            data (Optional[Dict[str, Any]], optional): 에러와 관련된 추가 메타 데이터. 기본값은 None입니다.
        """
        super().__init__(
            status_code=503,
            error_code=error_code,
            message=message,
            data=data,
        )


class CustomException(Exception):
    """
    시스템 전역에서 사용하는 기본 예외 클래스입니다.

    명세서 6.0의 에러 코드 체계를 따르며, 모든 비즈니스 로직 예외의 부모 클래스 역할을 합니다.
    FastAPI의 Exception Handler와 연동되어 일관된 API 응답 형식을 보장합니다.
    """

    def __init__(self, error_code: int, message: str):
        """
        커스텀 예외 객체를 초기화합니다.

        Args:
            error_code (int): 명세서 6.0에 정의된 고유 에러 코드
            message (str): 사용자 또는 개발자에게 전달할 에러 메시지
            data (Optional[Any]): 에러와 관련된 추가 참조 데이터 (예: 유효성 검사 실패 필드)
        """
        self.error_code = error_code
        self.message = message
        super().__init__(self.message)


# 명세서 6번에 맞춰 특화된 예외들
class AuthFailedException(CustomException):
    """
    인증 실패 시 발생하는 예외입니다. (명세서 6.0 - 에러 코드: 4010)

    로그인 시 아이디가 존재하지 않거나 비밀번호가 일치하지 않을 때 발생시키며,
    보안상 구체적인 실패 원인을 외부에 노출하지 않도록 모호한 메시지를 기본값으로 사용합니다.
    """

    def __init__(self, message: str = "아이디 또는 비밀번호가 일치하지 않습니다."):
        """4010 AUTH_FAILED 예외를 초기화합니다."""
        super().__init__(error_code=4010, message=message)


class AccountLockedException(CustomException):
    """
    계정 잠금 시 발생하는 예외입니다. (명세서 6.0 - 에러 코드: 4031)

    명세서 2.1 보안 정책에 따라 비밀번호 5회 이상 연속 오류 시 발생하며,
    사용자에게 관리자 문의가 필요함을 안내합니다.
    """

    def __init__(self, message: str = "비밀번호 5회 오류로 계정이 잠겼습니다."):
        """4031 ACCOUNT_LOCKED 예외를 초기화합니다."""
        super().__init__(error_code=4031, message=message)
