"""SFMS 전역 커스텀 예외 처리를 정의하는 모듈입니다."""

from fastapi import Request, status
from fastapi.responses import JSONResponse

from app.core.codes import ErrorCode


class SFMSException[T](Exception):
    """SFMS 시스템의 최상위 커스텀 예외 클래스입니다.

    모든 비즈니스 로직 에러는 이 클래스를 상속받아 발생시켜야 합니다.
    """

    domain: str
    status_code: int
    error_code: int
    data: T | None = None
    message: str  # 프론트엔드에서 번역 키(i18n key)로 활용

    def __init__(
        self,
        domain: str,
        status_code: int = status.HTTP_400_BAD_REQUEST,
        error_code: ErrorCode = ErrorCode.BAD_REQUEST,
        data: T | None = None,
        message: str | None = None,
    ):
        """SFMSException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러가 발생된 영역 (예: "IAM", "USR", "CMM", "SYS")
            status_code (int): 반환할 HTTP 상태 코드 (예: 400, 404, 500)
            error_code (ErrorCode): 프론트엔드에서 처리할 내부 커스텀 에러 코드
            data (T | None): 에러와 관련된 추가 메타 데이터
            message (str | None): 클라이언트에게 전달할 에러 메시지 (없으면 자동 매핑)

        """
        # 1. 도메인 보정 로직 (APIResponse의 validator와 동일하게 작동 n.n)
        self.domain = d if len(d := (domain or "").strip().upper()) == 3 else "SYS"

        # 2. 에러 코드 및 데이터 설정
        self.status_code = status_code
        self.error_code = error_code.code
        self.data = data

        # 3. 메시지 자동 매핑 (메시지가 없으면 ErrorCode에서 가져옴)
        self.message = message or error_code.message

        super().__init__(self.message)


class BadRequestException[T](SFMSException[T]):
    """잘못된 요청(400) 관련 예외 클래스입니다."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.BAD_REQUEST,
        message: str | None = None,
        data: T | None = None,
    ):
        """BadRequestException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code=error_code,
            data=data,
            message=message,
        )


class UnauthorizedException[T](SFMSException[T]):
    """인증 실패(401) 관련 예외 클래스입니다."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.AUTH_FAILED,
        message: str | None = None,
        data: T | None = None,
    ):
        """UnauthorizedException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_401_UNAUTHORIZED,
            error_code=error_code,
            data=data,
            message=message,
        )


class ForbiddenException[T](SFMSException[T]):
    """권한 부족(403) 관련 예외 클래스입니다."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.FORBIDDEN,
        message: str | None = None,
        data: T | None = None,
    ):
        """ForbiddenException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_403_FORBIDDEN,
            error_code=error_code,
            data=data,
            message=message,
        )


class NotFoundException[T](SFMSException[T]):
    """리소스를 찾을 수 없음(404) 관련 예외 클래스입니다."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.NOT_FOUND,
        message: str | None = None,
        data: T | None = None,
    ):
        """NotFoundException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_404_NOT_FOUND,
            error_code=error_code,
            data=data,
            message=message,
        )


class ConflictException[T](SFMSException[T]):
    """데이터 충돌(409) 관련 예외 클래스입니다. (중복 로직 등에 사용)."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.DUPLICATE_CODE,
        message: str | None = None,
        data: T | None = None,
    ):
        """ConflictException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_409_CONFLICT,
            error_code=error_code,
            data=data,
            message=message,
        )


class RateLimitException[T](SFMSException[T]):
    """요청 횟수 초과(429) 관련 예외 클래스입니다."""

    def __init__(
        self,
        domain: str,
        error_code: ErrorCode = ErrorCode.TOO_MANY_REQUESTS,
        message: str | None = None,
        data: T | None = None,
    ):
        """RateLimitException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            error_code=error_code,
            data=data,
            message=message,
        )


class InternalServerErrorException[T](SFMSException[T]):
    """서버 내부 오류(500) 관련 예외 클래스입니다. (예외적인 시스템 결함 등)."""

    def __init__(
        self,
        domain: str = "SYS",
        error_code: ErrorCode = ErrorCode.INTERNAL_SERVER_ERROR,
        message: str | None = None,
        data: T | None = None,
    ):
        """InternalServerErrorException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            error_code=error_code,
            data=data,
            message=message,
        )


class ServiceUnavailableException[T](SFMSException[T]):
    """서비스 사용 불가(503) 관련 예외 클래스입니다. (DB/Redis 연결 실패 등)."""

    def __init__(
        self,
        domain: str = "SYS",  # 인프라 에러는 주로 시스템(SYS) 영역이 기본!
        error_code: ErrorCode = ErrorCode.SERVICE_UNAVAILABLE,  # 5030으로 변경!
        message: str | None = None,
        data: T | None = None,
    ):
        """ServiceUnavailableException 인스턴스를 초기화합니다.

        Args:
            domain (str): 에러 발생 도메인
            error_code (ErrorCode): 비즈니스 에러 코드
            message (str | None): 커스텀 에러 메시지
            data (T | None): 추가 상세 데이터

        """
        super().__init__(
            domain=domain,
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            error_code=error_code,
            data=data,
            message=message,
        )


def register_exception_handlers(app):
    """시스템 전역 커스텀 예외 핸들러를 등록합니다.

    SFMSException 및 그 하위 예외들이 발생했을 때, 500 에러 대신
    정의된 HTTP 상태 코드와 비즈니스 에러 코드를 포함한 JSON 응답을 반환합니다.
    """

    @app.exception_handler(SFMSException)
    async def sfms_exception_handler(request: Request, exc: SFMSException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "success": False,
                "domain": exc.domain,
                "status_code": exc.status_code,
                "error_code": exc.error_code,
                "message": exc.message,
                "data": exc.data,
            },
        )
