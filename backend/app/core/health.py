"""서비스 헬스체크 모듈.

FastAPI 헬스체크 엔드포인트(/health)를 제공하여 서버 및 데이터베이스 연결 상태를 모니터링합니다.

주요 기능:
    - 서버 상태 확인 (항상 "ok" 반환)
    - PostgreSQL 데이터베이스 연결 테스트 (SELECT 1 쿼리)
    - Redis 연결 체크 추가
    - MinIO/S3 스토리지 연결 체크 추가
    - FastAPI 앱 버전 정보 제공
    - 서버 현재 시간 반환

모듈 구조:
    - health_check(): 단일 헬스체크 함수 (app과 router 겸용)
    - @app.get + @router.get 중복 데코레이터로 main.py include_router 불필요

사용법:
    1. main.py에서 import 후 app.include_router(health.router) (선택적)
    2. 또는 @app.get으로 직접 main 모듈에 바인딩되어 즉시 사용 가능

응답 형식:
    {
        "status": "ok",
        "db_connection": boolean,
        "version": "0.1.0",
        "server_time": "2026-03-07T11:59:00"
    }

확장 가능 항목:

    - 캐시/메시지큐 상태 확인
    - 배포 환경 변수 확인

Dependencies:
    - app.core.dependencies.get_db: SQLAlchemy DB 세션 제공
    - app.core.responses.APIResponse: 응답 wrapper
    - app.main.app: FastAPI 앱 인스턴스 (version 정보)
"""

from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

import app.core.storage as minio
from app.core.cache import redis_client
from app.core.config import settings
from app.core.dependencies import get_db
from app.core.logger import logger
from app.core.responses import APIResponse

router = APIRouter(tags=["Health"])


@router.get(
    "/health",
    response_model=APIResponse[dict],
    summary="서비스 및 DB 연결 상태 확인",
)
async def health_check(
    response: Response,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """서비스 헬스체크 엔드포인트.

    서버 상태, 데이터베이스, Redis, MinIO 연결 상태를 확인하여 전체 서비스의 정상 여부를 반환합니다.
    """
    db_status = False  # 기본 DB 상태 초기화
    redis_status = False  # 기본 Redis 상태 초기화
    minio_status = False  # 기본 MinIO 상태 초기화

    # 1. PostgreSQL DB 연결 체크
    try:
        await db.execute(text("SELECT 1"))
        db_status = True  # 연결 성공
    except Exception as e:
        logger.error(f"Health check failed - DB connection error: {e}")
        db_status = False  # 연결 실패 처리

    # 2. Redis 연결 체크
    try:
        await redis_client.execute_command("PING")  # 비동기 ping 테스트
        # await redis_client.ping()  # Pylance 호환성 버그로 execute_command로 변경
        redis_status = True  # 연결 성공
    except Exception as e:
        logger.error(f"Health check failed - Redis connection error: {e}")
        redis_status = False  # 연결 실패 처리

    # 3. MinIO 연결 체크
    minio_status = await minio.check_storage_connection()

    # 4. 전체 헬스 상태 판별
    is_healthy = db_status and redis_status and minio_status

    if not is_healthy:
        response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE  # 실패 시 503 반환

    result_data = {
        "status": "ok" if is_healthy else "error",
        "db_connection": db_status,
        "redis_connection": redis_status,
        "minio_connection": minio_status,
        "version": getattr(settings, "VERSION", "0.1.0"),
        "server_time": datetime.now(UTC).isoformat(),
    }

    return APIResponse(domain="SYS", data=result_data)
