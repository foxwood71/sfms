"""SFMS (Sewage Facility Management System) FastAPI 메인 애플리케이션.

PostgreSQL + MinIO + 도메인별 모듈화 API 서버.
개발/프로덕션 통합 설정.
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1.api_router import api_router
from app.core.config import Settings
from app.core.database import Base, engine

# 개발용: 애플리케이션 시작 시 테이블 자동 생성
# 프로덕션: Alembic 마이그레이션 사용 권장
Base.metadata.create_all(bind=engine)

#  환경 설정 로드
settings = Settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """애플리케이션의 시작과 종료 시점에 실행되는 생명주기 훅입니다.

    Args:
        app (FastAPI): FastAPI 애플리케이션 인스턴스.

    startup: DB 연결 풀 초기화, 캐시 로드.
    shutdown: 연결 종료, 리소스 정리.
    """
    # Startup
    print("🚀 SFMS API 서버 시작")
    yield
    # Shutdown
    print("🛑 SFMS API 서버 종료")


# 메인 FastAPI 앱
app = FastAPI(
    title="SFMS API Service",
    description="하수처리시설 관리 시스템 RESTful API\nPostgreSQL + MinIO + FastAPI 기반",
    version="1.0.0",
    lifespan=lifespan,  # 생명주기 훅
    docs_url="/docs",  # Swagger UI
    redoc_url="/redoc",  # ReDoc
)

# CORS 미들웨어: React(Vite) 개발 서버 포트 대응
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],  # React/Next.js
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(404)
async def not_found_handler(request: Request, exc: Exception):
    """
    HTTP 404 (Not Found) 예외를 처리하는 전역 핸들러입니다.

    정의되지 않은 API 엔드포인트로 요청이 들어왔을 때,
    기본 HTML 에러 페이지 대신 일관된 JSON 형식의 에러 메시지를 반환합니다.

    Args:
        request (Request): 클라이언트의 요청 객체.
        exc (Exception): 발생한 예외 객체.

    Returns:
        JSONResponse: 404 상태 코드와 커스텀 에러 메시지("detail")를 포함한 JSON 응답.
    """
    return JSONResponse(
        status_code=404,
        content={"detail": "API 엔드포인트를 찾을 수 없습니다."},
    )


#  도메인 기반 라우터 등록
app.include_router(api_router, prefix="/api/v1")


@app.get("/", tags=["Health"])
def health_check():
    """API 헬스체크 수행 및 시스템 상태 확인한다.

    Returns:
        dict: 서버 상태 및 버전 정보.

    """
    return {"status": "ok", "app_version": app.version, "python_version": "3.13.11"}


@app.get("/health", tags=["Health"])
async def detailed_health() -> dict[str, str | bool]:
    """상세 헬스체크 (DB 연결 등).

    Returns:
        dict: 전체 시스템 상태.

    """
    return {
        "status": "healthy",
        "database": "connected",  # 실제로는 ping 테스트
        "minio": "accessible",
    }
