"""FastAPI 애플리케이션의 메인 진입점 모듈입니다."""

from typing import TypeVar

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1.api_router import api_router
from app.core.config import settings
from app.core.exceptions import register_exception_handlers

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
)

T = TypeVar("T")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 로컬 개발용 외부 접근 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 전역 예외 핸들러 등록
register_exception_handlers(app)

# 통합 라우터를 메인 애플리케이션에 병합(Mount)합니다.
# 이 한 줄로 api_router 안에 있는 모든 도메인 API가 /api/v1 하위로 맵핑됩니다.
app.include_router(api_router, prefix=settings.API_V1_STR)
