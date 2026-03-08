"""메인 API 라우터 통합 모듈.

도메인별 APIRouter를 메인 api_router에 마운트.
모노레포 구조에서 도메인 확장 용이.
"""

from fastapi import APIRouter

# TODO: 추후 도메인이 추가되면 아래에 임포트하고 등록합니다.
# from app.domains.sys.router import router as sys_router
# from app.domains.fac.router import router as fac_router
from app.core.health import router as health_router
from app.domains.cmm.router import router as cmm_router
from app.domains.fac.router import router as fac_router
from app.domains.iam.router import auth_router, role_router
from app.domains.sys.router import router as sys_router
from app.domains.usr.router import router as usr_router

api_router = APIRouter()

# 1. 시스템 인프라 라우터 (최상단 배치 권장)
# 명세서상 /api/v1/health로 접근하기 위해 별도 prefix 없이 포함합니다.
api_router.include_router(health_router)  # 서비스 상태 확인
api_router.include_router(sys_router)  # AuditLog, SystemSequence

# 2. 인증 및 권한 관리 (IAM)
api_router.include_router(auth_router)  # 로그인/로그아웃/토큰
api_router.include_router(role_router)  # 역할 및 권한 설정

# 3. 비즈니스 도메인 라우터
api_router.include_router(usr_router)  # 사용자 및 조직 관리
api_router.include_router(cmm_router)  # 공통 관리 (코드, 파일, 알림)
api_router.include_router(fac_router)  # 시설 관리
