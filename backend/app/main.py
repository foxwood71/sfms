"""FastAPI 애플리케이션의 메인 진입점 모듈입니다."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 로컬 개발용 외부 접근 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/api/v1/system/health")
async def health_check():
    """
    시스템의 헬스 체크 상태를 반환합니다.

    Returns:
        dict: 시스템 상태(status)와 서비스명(service)을 포함한 딕셔너리
    """
    return {"status": "ok", "service": settings.PROJECT_NAME}
