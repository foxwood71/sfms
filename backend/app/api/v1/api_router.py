"""메인 API 라우터 통합 모듈.

도메인별 APIRouter를 메인 api_router에 마운트.
모노레포 구조에서 도메인 확장 용이.
"""

from fastapi import APIRouter

# TODO: 추후 도메인이 추가되면 아래에 임포트하고 등록합니다.
# from app.domains.fac.router import router as fac_router
from app.domains.cmm.router import router as cmm_router
from app.domains.fac.router import router as fac_router
from app.domains.iam.router import auth_router, iam_router
from app.domains.usr.router import router as usr_router

api_router = APIRouter()

# 각 도메인별 라우터를 통합 라우터에 장착합니다.
# 이미 개별 라우터에 prefix(예: /usr, /iam)가 설정되어 있으므로 여기서는 그대로 포함합니다.
api_router.include_router(auth_router)  # 인증 라우터
api_router.include_router(iam_router)  # 권한 라우터
api_router.include_router(usr_router)  # 사용자 및 조직 라우터
api_router.include_router(cmm_router)  # 공통 관리 라우터
api_router.include_router(fac_router)  # 시설 관리 라우터
