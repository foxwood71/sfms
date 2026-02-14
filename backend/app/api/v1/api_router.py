"""메인 API 라우터 통합 모듈.

도메인별 APIRouter를 메인 api_router에 마운트.
모노레포 구조에서 도메인 확장 용이.
"""

from fastapi import APIRouter

from app.domains.cmm.router import router as cmm_router

#  [Roadmap] 추후 구현 시 주석 해제하여 연결
# from app.domains.iam.router import router as iam_router
# from app.domains.fac.router import router as fac_router
# from app.domains.eqp.router import router as eqp_router


api_router = APIRouter()

#  각 도메인의 라우터를 통합 관리
api_router.include_router(cmm_router)

# --- 2. 인증/권한 도메인 (Identity) ---
#  로그인, 토큰 갱신, 메뉴 권한 관리
# api_router.include_router(iam_router, prefix="/iam", tags=["Identity"])

# --- 3. 시설 관리 도메인 (Facility) ---
#  시설물 및 공간 정보 관리
# api_router.include_router(fac_router, prefix="/fac", tags=["Facility"])

# --- 4. 설비 관리 도메인 (Equipment) ---
#  기계, 전기, 계측제어 설비 마스터 관리
# api_router.include_router(eqp_router, prefix="/eqp", tags=["Equipment"]))
