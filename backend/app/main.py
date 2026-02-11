from fastapi import FastAPI
from app.api.v1.api_router import api_router  # 통합 라우터 임포트
from app.core.database import engine, Base


# DB 테이블 생성 (초기 개발 단계에서 유용)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="SFMS API Service",
    description="하수처리시설 관리 시스템 API (Python 3.13)",
    version="1.0.0"
)

#  도메인 기반 라우터 등록
app.include_router(api_router, prefix="/api/v1")


@app.get("/")
def health_check():
    return {"status": "ok", "version": "3.13.11"}
