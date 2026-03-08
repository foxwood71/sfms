"""시스템 관리(SYS) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다.

이 모듈은 채번 규칙 설정 및 문서 번호 발급, 그리고 시스템 감사 로그 조회를 위한
RESTful 인터페이스를 제공합니다.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import (
    get_current_active_superuser,
    get_current_user,
    get_db,
)
from app.core.responses import APIResponse
from app.domains.sys.schemas import (
    AuditLogRead,
    SequenceRuleCreate,
    SequenceRuleRead,
    SequenceRuleUpdate,
)
from app.domains.sys.services import AuditLogService, SequenceRuleService
from app.domains.usr.models import User

from . import DOMAIN

router = APIRouter(prefix="/sys", tags=["시스템 (SYS)"])


# --------------------------------------------------------
# [SequenceRule] 시스템 채번(Sequence) 관리 API
# --------------------------------------------------------


@router.get("/sequences", response_model=APIResponse[list[SequenceRuleRead]])
async def list_sequence_rules(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """시스템에 등록된 모든 자동 채번 규칙 목록을 조회합니다.

    이 API는 시스템 관리자(Superuser)만 호출 가능합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 현재 요청을 수행하는 관리자 정보

    Returns:
        APIResponse[list[SequenceRuleRead]]: 전체 채번 규칙 리스트
    """
    rules = await SequenceRuleService.list_rules(db)
    return APIResponse(domain=DOMAIN, data=rules)


@router.post(
    "/sequences",
    response_model=APIResponse[SequenceRuleRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_sequence_rule(
    obj_in: SequenceRuleCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """신규 자동 채번 규칙을 생성합니다.

    도메인 코드, 접두어, 연도 포맷 및 자릿수 등을 설정할 수 있습니다. 
    이 API는 시스템 관리자만 호출 가능합니다.

    Args:
        obj_in (SequenceRuleCreate): 신규 채번 규칙 정의 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[SequenceRuleRead]: 생성 완료된 채번 규칙 정보
    """
    new_rule = await SequenceRuleService.create_rule(
        db, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(domain=DOMAIN, data=new_rule)


@router.patch("/sequences/{rule_id}", response_model=APIResponse[SequenceRuleRead])
async def update_sequence_rule(
    rule_id: int,
    obj_in: SequenceRuleUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """기존 자동 채번 규칙의 속성을 수정합니다.

    Args:
        rule_id (int): 수정할 대상 규칙의 ID
        obj_in (SequenceRuleUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[SequenceRuleRead]: 수정 완료된 채번 규칙 정보
    """
    updated_rule = await SequenceRuleService.update_rule(
        db, rule_id=rule_id, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(domain=DOMAIN, data=updated_rule)


@router.delete("/sequences/{rule_id}", response_model=APIResponse[None])
async def delete_sequence_rule(
    rule_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
):
    """특정 자동 채번 규칙을 영구 삭제합니다.

    Args:
        rule_id (int): 삭제할 대상 규칙의 ID
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 삭제 성공 응답
    """
    await SequenceRuleService.delete_rule(db, rule_id=rule_id)
    return APIResponse(domain=DOMAIN, data=None)


@router.get("/sequence/{domain_code}/{prefix}/next", response_model=APIResponse[str])
async def get_next_sequence(
    domain_code: str,
    prefix: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 도메인 및 접두어에 대해 규칙에 맞는 다음 문서 번호를 발급받습니다.

    이 API는 모든 인증된 사용자가 자신의 업무 처리를 위해 호출할 수 있습니다. 
    동시성 제어를 통해 번호 중복이 방지됩니다.

    Args:
        domain_code (str): 도메인 식별 코드 (예: 'FAC')
        prefix (str): 문서 접두어 (예: 'WO')
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 요청을 수행하는 사용자 정보

    Returns:
        APIResponse[str]: 규칙에 따라 포맷팅된 최종 번호 (예: 'WO-2026-0001')
    """
    next_seq = await SequenceRuleService.get_next_sequence(
        db, domain_code=domain_code, prefix=prefix
    )
    return APIResponse(domain=DOMAIN, data=next_seq)


# --------------------------------------------------------
# [AuditLog] 감사 로그 조회 API
# --------------------------------------------------------


@router.get("/audit-logs", response_model=APIResponse[list[AuditLogRead]])
async def list_audit_logs(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(get_current_active_superuser)],
    target_domain: Annotated[str | None, Query(description="대상 도메인 (USR, FAC 등)")] = None,
    action_type: Annotated[str | None, Query(description="행위 유형 (CREATE, LOGIN 등)")] = None,
    skip: Annotated[int, Query(ge=0, description="건너뛸 레코드 수")] = 0,
    limit: Annotated[int, Query(ge=1, le=1000, description="최대 조회 수")] = 100,
):
    """시스템 감사 로그 목록을 통합 조회합니다.

    데이터 변경 이력 및 사용자 로그인 정보를 포함한 상세 로그를 확인할 수 있습니다. 
    이 API는 시스템 관리자만 호출 가능합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보
        target_domain (str | None, optional): 특정 도메인 필터. 기본값은 None.
        action_type (str | None, optional): 특정 행위 유형 필터. 기본값은 None.
        skip (int, optional): 페이징 오프셋. 기본값은 0.
        limit (int, optional): 조회 제한 수. 기본값은 100.

    Returns:
        APIResponse[list[AuditLogRead]]: 감사 로그 목록
    """
    logs = await AuditLogService.list_audit_logs(
        db, skip=skip, limit=limit, target_domain=target_domain, action_type=action_type
    )
    return APIResponse(domain=DOMAIN, data=logs)
