"""공통 관리(CMM) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다.

이 모듈은 시스템 기준정보(공통 코드) 조회, 통합 파일 업로드/삭제,
그리고 사용자 알림 관리를 위한 RESTful 인터페이스를 제공합니다.
"""

import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import SuccessCode
from app.core.dependencies import check_domain_admin, get_current_user, get_db
from app.core.exceptions import InternalServerErrorException
from app.core.responses import APIResponse
from app.core.storage import upload_file_stream
from app.domains.cmm.schemas import (
    AttachmentCreate,
    AttachmentRead,
    CodeDetailCreate,
    CodeDetailRead,
    CodeDetailUpdate,
    CodeGroupCreate,
    CodeGroupRead,
    CodeGroupUpdate,
    NotificationRead,
)
from app.domains.cmm.services import AttachmentService, CodeService, NotificationService
from app.domains.usr.models import User

from . import DOMAIN

router = APIRouter(prefix="/cmm", tags=["공통 관리 (CMM)"])


# --------------------------------------------------------
# [Common Code] 공통 코드 조회 및 관리 API
# --------------------------------------------------------


@router.get("/codes", response_model=APIResponse[list[CodeGroupRead]])
async def list_codes(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    domain_code: Annotated[str | None, Query(description="특정 도메인의 코드만 필터링")] = None,
):
    """시스템 전체 또는 특정 도메인의 활성화된 공통 코드 목록을 조회합니다.

    Args:
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 로그인한 사용자 정보
        domain_code (str | None, optional): 특정 업무 도메인 필터링 코드. 기본값은 None.

    Returns:
        APIResponse[list[CodeGroupRead]]: 활성화된 코드 그룹 및 상세 코드 리스트
    """
    codes = await CodeService.list_active_codes(db, domain_code=domain_code)
    return APIResponse(domain=DOMAIN, data=codes)


@router.get("/codes/{group_code}", response_model=APIResponse[CodeGroupRead])
async def get_code_group(
    group_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 그룹 코드에 속한 상세 코드 목록을 상세 조회합니다.

    Args:
        group_code (str): 조회할 코드 그룹의 식별자
        db (AsyncSession): 데이터베이스 비동기 세션
        current_user (User): 현재 로그인한 사용자 정보

    Returns:
        APIResponse[CodeGroupRead]: 코드 그룹 상세 정보 및 하위 코드 리스트
    """
    code_group = await CodeService.get_code_group(db, group_code=group_code)
    return APIResponse(domain=DOMAIN, data=code_group)


@router.post(
    "/codes",
    response_model=APIResponse[CodeGroupRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_code_group(
    obj_in: CodeGroupCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """신규 공통 코드 그룹을 생성합니다.

    Args:
        obj_in (CodeGroupCreate): 생성할 코드 그룹 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[CodeGroupRead]: 생성 완료된 코드 그룹 정보
    """
    new_group = await CodeService.create_code_group(db, obj_in=obj_in, actor_id=current_admin.id)
    return APIResponse(domain=DOMAIN, data=new_group, success_code=SuccessCode.SUCCESS_CREATED)


@router.patch("/codes/{group_code}", response_model=APIResponse[CodeGroupRead])
async def update_code_group(
    group_code: str,
    obj_in: CodeGroupUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """기존 공통 코드 그룹 정보를 수정합니다.

    Args:
        group_code (str): 수정할 대상 그룹 코드
        obj_in (CodeGroupUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[CodeGroupRead]: 수정 완료된 코드 그룹 정보
    """
    updated_group = await CodeService.update_code_group(
        db, group_code=group_code, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(domain=DOMAIN, data=updated_group, success_code=SuccessCode.SUCCESS_UPDATED)


@router.delete("/codes/{group_code}", response_model=APIResponse[None])
async def delete_code_group(
    group_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """공통 코드 그룹을 삭제합니다. 시스템 필수 코드는 삭제할 수 없습니다.

    Args:
        group_code (str): 삭제할 대상 그룹 코드
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[None]: 삭제 성공 응답
    """
    await CodeService.delete_code_group(db, group_code=group_code)
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED)


@router.post(
    "/codes/{group_code}/details",
    response_model=APIResponse[CodeDetailRead],
    status_code=status.HTTP_201_CREATED,
)
async def create_code_detail(
    group_code: str,
    obj_in: CodeDetailCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """특정 그룹에 새로운 상세 코드를 추가합니다.

    Args:
        group_code (str): 부모 그룹 코드
        obj_in (CodeDetailCreate): 생성할 상세 코드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[CodeDetailRead]: 생성 완료된 상세 코드 정보
    """
    new_detail = await CodeService.create_code_detail(
        db, group_code=group_code, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(domain=DOMAIN, data=new_detail, success_code=SuccessCode.SUCCESS_CREATED)


@router.patch(
    "/codes/{group_code}/details/{detail_code}",
    response_model=APIResponse[CodeDetailRead],
)
async def update_code_detail(
    group_code: str,
    detail_code: str,
    obj_in: CodeDetailUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """특정 상세 코드 정보를 수정합니다.

    Args:
        group_code (str): 부모 그룹 코드
        detail_code (str): 수정할 상세 코드
        obj_in (CodeDetailUpdate): 업데이트할 필드 정보
        db (AsyncSession): 데이터베이스 비동기 세션
        current_admin (User): 행위 수행 권한을 가진 관리자 정보

    Returns:
        APIResponse[CodeDetailRead]: 수정 완료된 상세 코드 정보
    """
    updated_detail = await CodeService.update_code_detail(
        db,
        group_code=group_code,
        detail_code=detail_code,
        obj_in=obj_in,
        actor_id=current_admin.id,
    )
    return APIResponse(domain=DOMAIN, data=updated_detail, success_code=SuccessCode.SUCCESS_UPDATED)


@router.delete("/codes/{group_code}/details/{detail_code}", response_model=APIResponse[None])
async def delete_code_detail(
    group_code: str,
    detail_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 그룹에 속한 상세 코드를 영구 삭제합니다."""
    from app.domains.cmm.models import CodeDetail
    from sqlalchemy import delete
    from app.core.exceptions import NotFoundException
    from app.core.codes import ErrorCode

    stmt = delete(CodeDetail).where(
        CodeDetail.group_code == group_code, CodeDetail.detail_code == detail_code
    )
    result = await db.execute(stmt)
    if result.rowcount == 0:
        raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
    
    await db.commit()
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED)


# --------------------------------------------------------
# [Attachment] 통합 파일 관리 API
# --------------------------------------------------------


@router.post(
    "/upload",
    response_model=APIResponse[AttachmentRead],
    status_code=status.HTTP_201_CREATED,
)
async def upload_file(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    domain_code: Annotated[str, Query(..., description="업무 도메인 코드 (예: USR, FAC)")],
    resource_type: Annotated[str, Query(..., description="리소스 유형 (예: PROFILE, EQUIPMENT)")],
    ref_id: Annotated[int, Query(..., description="연결될 레코드 PK")],
    file: UploadFile = File(...),
    category_code: Annotated[str, Query(description="파일 분류 코드")] = "GENERAL",
):
    """단일 파일을 업로드하고 메타데이터를 저장합니다."""
    from app.core.storage import upload_file_stream
    from app.domains.cmm.schemas import AttachmentCreate

    file_data = await file.read()
    new_id = uuid.uuid4()

    file_ext = file.filename.split(".")[-1] if file.filename else "bin"
    object_name = f"{domain_code}/{resource_type}/{new_id.hex}.{file_ext}"

    success = await upload_file_stream(
        object_name=object_name,
        file_data=file_data,
        content_type=file.content_type or "application/octet-stream",
    )

    if not success:
        raise InternalServerErrorException(domain=DOMAIN, error_code=ErrorCode.STORAGE_ERROR)

    attachment_in = AttachmentCreate(
        id=new_id,
        domain_code=domain_code,
        resource_type=resource_type,
        ref_id=ref_id,
        category_code=category_code,
        file_name=file.filename or "unknown",
        file_path=object_name,
        file_size=len(file_data),
        content_type=file.content_type,
        org_id=current_user.org_id,
        created_by=current_user.id,
    )

    new_attachment = await AttachmentService.create_attachment_metadata(db, obj_in=attachment_in)
    await db.commit()

    return APIResponse(domain=DOMAIN, data=new_attachment, success_code=SuccessCode.SUCCESS_CREATED)


@router.delete("/attachments/{attachment_id}", response_model=APIResponse[None])
async def delete_attachment(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    attachment_id: uuid.UUID,
    permanent: Annotated[bool, Query(description="즉시 물리 삭제 여부 (관리자 전용)")] = False,
):
    """첨부파일을 삭제 처리합니다."""
    await AttachmentService.delete_attachment(
        db,
        attachment_id=attachment_id,
        actor_id=current_user.id,
        actor_org_id=current_user.org_id,
        is_admin=current_user.is_superuser,
        permanent=permanent,
    )
    await db.commit()
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED)


@router.get("/attachments/deleted", response_model=APIResponse[list[AttachmentRead]])
async def list_deleted_attachments(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    domain_code: Annotated[str | None, Query(description="도메인 코드 (예: FAC)")] = None,
    resource_type: Annotated[str | None, Query(description="리소스 유형 (예: EQUIPMENT)")] = None,
    ref_id: Annotated[int | None, Query(description="연결 레코드 ID")] = None,
    skip: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
):
    """소프트 삭제된 첨부파일(휴지통) 목록을 조회합니다."""
    files = await AttachmentService.list_deleted_attachments(
        db,
        actor_id=current_user.id,
        actor_org_id=current_user.org_id,
        is_admin=current_user.is_superuser,
        domain_code=domain_code,
        resource_type=resource_type,
        ref_id=ref_id,
        skip=skip,
        limit=limit,
    )
    return APIResponse(domain=DOMAIN, data=files)


@router.post("/attachments/{attachment_id}/restore", response_model=APIResponse[None])
async def restore_attachment(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    attachment_id: uuid.UUID,
):
    """소프트 삭제된 첨부파일을 다시 복구합니다."""
    await AttachmentService.restore_attachment(
        db,
        attachment_id=attachment_id,
        actor_id=current_user.id,
        actor_org_id=current_user.org_id,
        is_admin=current_user.is_superuser,
    )
    await db.commit()
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_UPDATED)


# --------------------------------------------------------
# [Notification] 알림 관리 API
# --------------------------------------------------------


@router.get("/notifications", response_model=APIResponse[list[NotificationRead]])
async def list_notifications(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    unread_only: Annotated[bool, Query()] = False,
):
    """로그인한 사용자의 알림 목록을 최신순으로 조회합니다."""
    notifications = await NotificationService.list_my_notifications(
        db, user_id=current_user.id, unread_only=unread_only
    )
    return APIResponse(domain=DOMAIN, data=notifications)


@router.patch("/notifications/{notification_id}/read", response_model=APIResponse[None])
async def mark_notification_as_read(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    notification_id: int,
):
    """특정 알림을 읽음 처리합니다."""
    await NotificationService.mark_as_read(db, notification_id=notification_id, user_id=current_user.id)
    return APIResponse(domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_UPDATED)
