"""FastAPI 애플리케이션의 메인 진입점 모듈입니다."""

from typing import Any, Generic, Optional, TypeVar

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from app.core.config import settings
from app.core.exceptions import SFMSException
from app.domains.usr.router import router as usr_router

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
)

T = TypeVar("T")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 로컬 개발용 외부 접근 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class APIResponse(BaseModel, Generic[T]):
    """API 응답을 위한 공통 제네릭 포맷 클래스입니다."""

    success: bool
    code: int
    message: str
    data: Optional[T] = None
    meta: Optional[dict[str, Any]] = None  # 페이지네이션 등 메타 정보


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """예기치 못한 서버 에러를 500 커스텀 응답으로 감싸서 반환합니다."""
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "code": 5000,
            "message": "서버 내부 오류가 발생했습니다.",
            "data": None,
        },
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Pydantic 데이터 검증 실패(422) 예외를 공통 포맷으로 변환합니다."""
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "code": 4220,
            "message": "입력 데이터 검증에 실패했습니다.",
            "data": exc.errors(),  # 어떤 필드가 틀렸는지 상세 내역 전달
        },
    )


@app.exception_handler(SFMSException)
async def sfms_exception_handler(request: Request, exc: SFMSException):
    """SFMS 커스텀 예외를 잡아 공통 응답 포맷으로 변환합니다."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "success": False,
            "code": exc.error_code,
            "message": exc.message,
            "data": exc.data,
        },
    )


@app.get("/api/v1/system/health", response_model=APIResponse[dict])
async def health_check():
    """
    시스템의 헬스 체크 상태를 반환합니다.

    인증을 거치지 않는 시스템 헬스 체크 API입니다.

    Returns:
        dict: 시스템 상태(status)와 서비스명(service)을 포함한 딕셔너리
    """
    # TODO: DB 및 Redis 실제 연결 확인 로직 추가 필요
    health_data = {
        "status": "ok",
        "db_connection": True,
        "redis_connection": True,
        "version": app.version,
    }

    return APIResponse(
        success=True,
        code=200,
        message="Ok",
        data=health_data,
    )


# 도메인의 라우터를 메인 애플리케이션에 병합(Mount)
# prefix에 설정된 값(예: "/api/v1")이 라우터의 모든 엔드포인트 앞에 자동으로 붙습니다.
# USR(사용자 및 조직)
app.include_router(usr_router, prefix=settings.API_V1_STR)
