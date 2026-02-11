from fastapi import APIRouter
from app.domains.cmm.router import router as cmm_router
# from app.domains.fac.router import router as fac_router
#  추후 eqp, wqt 등 도메인 추가 시 여기서 통합


api_router = APIRouter()

#  각 도메인의 라우터를 통합 관리
api_router.include_router(cmm_router)
# api_router.include_router(fac_router)
