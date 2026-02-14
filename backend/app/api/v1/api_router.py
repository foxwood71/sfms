"""메인 API 라우터 통합 모듈.

도메인별 APIRouter를 메인 api_router에 마운트.
모노레포 구조에서 도메인 확장 용이.
"""

from fastapi import APIRouter

from app.domains.cmm.router import router as cmm_router

# from app.domains.fac.router import router as fac_router  # 비활성 도메인
# from app.domains.wwt.router import router as wwt_router  # 추후 추가
#  추후 eqp, wqt 등 도메인 추가 시 여기서 통합


api_router = APIRouter()

#  각 도메인의 라우터를 통합 관리
api_router.include_router(cmm_router)

# api_router.include_router(fac_router, tags=["FAC"])
# api_router.include_router(wwt_router, tags=["WWT"])

# 메인 api_router를 app/main.py에서 사용:
# app.include_router(api_router, prefix="/api/v1")
