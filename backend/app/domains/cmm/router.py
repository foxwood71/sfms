"""공통 관리(CMM) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다.

이 모듈은 시스템 기준정보(공통 코드) 조회, 통합 파일 업로드/삭제,
그리고 사용자 알림 관리를 위한 RESTful 인터페이스를 제공합니다.
"""

import uuid
from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode, SuccessCode
from app.core.dependencies import check_domain_admin, get_current_user, get_db
from app.core.exceptions import (
    InternalServerErrorException,
    NotFoundException,
)
from app.core.responses import APIResponse
from app.core.storage import get_presigned_url, upload_file_stream
from app.domains.cmm.schemas import (
    AttachmentCreate,
    AttachmentRead,
    CodeBulkImportRequest,
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
    domain_code: Annotated[
        str | None, Query(description="특정 도메인의 코드만 필터링")
    ] = None,
):
    """시스템 전체 또는 특정 도메인의 활성화된 공통 코드 목록을 조회합니다."""
    codes = await CodeService.list_active_codes(db, domain_code=domain_code)
    return APIResponse(domain=DOMAIN, data=codes)


@router.get("/export/codes/{target}", response_model=APIResponse[Any])
async def export_codes(
    target: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """공통 코드 데이터를 내보냅니다."""
    if target == "all":
        groups = await CodeService.list_active_codes(db)
        details = await CodeService.list_all_details(db)
        return APIResponse(domain=DOMAIN, data={"groups": groups, "details": details})
    elif target == "groups":
        data = await CodeService.list_active_codes(db)
        return APIResponse(domain=DOMAIN, data=data)
    elif target == "details":
        data = await CodeService.list_all_details(db)
        return APIResponse(domain=DOMAIN, data=data)
    else:
        raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)


@router.post("/import/codes/all", response_model=APIResponse[dict[str, int]])
async def import_codes(
    request: CodeBulkImportRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """엑셀 데이터를 기반으로 공통 코드(그룹/상세)를 일괄 임포트합니다."""
    summary = await CodeService.bulk_import_codes(
        db, items=request.items, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=summary, success_code=SuccessCode.SUCCESS_CREATED
    )


@router.get("/codes/{group_code}", response_model=APIResponse[CodeGroupRead])
async def get_code_group(
    group_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 그룹 코드에 속한 상세 코드 목록을 상세 조회합니다."""
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
    """신규 공통 코드 그룹을 생성합니다."""
    new_group = await CodeService.create_code_group(
        db, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=new_group, success_code=SuccessCode.SUCCESS_CREATED
    )


@router.patch("/codes/{group_code}", response_model=APIResponse[CodeGroupRead])
async def update_code_group(
    group_code: str,
    obj_in: CodeGroupUpdate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """기존 공통 코드 그룹 정보를 수정합니다."""
    updated_group = await CodeService.update_code_group(
        db, group_code=group_code, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=updated_group, success_code=SuccessCode.SUCCESS_UPDATED
    )


@router.delete("/codes/{group_code}", response_model=APIResponse[None])
async def delete_code_group(
    group_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_admin: Annotated[User, Depends(check_domain_admin("CMM"))],
):
    """공통 코드 그룹을 삭제합니다."""
    await CodeService.delete_code_group(db, group_code=group_code)
    return APIResponse(
        domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED
    )


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
    """특정 그룹에 새로운 상세 코드를 추가합니다."""
    new_detail = await CodeService.create_code_detail(
        db, group_code=group_code, obj_in=obj_in, actor_id=current_admin.id
    )
    return APIResponse(
        domain=DOMAIN, data=new_detail, success_code=SuccessCode.SUCCESS_CREATED
    )


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
    """특정 상세 코드 정보를 수정합니다."""
    updated_detail = await CodeService.update_code_detail(
        db,
        group_code=group_code,
        detail_code=detail_code,
        obj_in=obj_in,
        actor_id=current_admin.id,
    )
    return APIResponse(
        domain=DOMAIN, data=updated_detail, success_code=SuccessCode.SUCCESS_UPDATED
    )


@router.delete(
    "/codes/{group_code}/details/{detail_code}", response_model=APIResponse[None]
)
async def delete_code_detail(
    group_code: str,
    detail_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """특정 그룹에 속한 상세 코드를 영구 삭제합니다."""
    from sqlalchemy import delete

    from app.domains.cmm.models import CodeDetail

    stmt = delete(CodeDetail).where(
        CodeDetail.group_code == group_code, CodeDetail.detail_code == detail_code
    )
    result = await db.execute(stmt)
    if result.rowcount == 0:
        raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

    await db.commit()
    return APIResponse(
        domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED
    )


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
    domain_code: Annotated[
        str, Query(..., description="업무 도메인 코드 (예: USR, FAC)")
    ],
    resource_type: Annotated[
        str, Query(..., description="리소스 유형 (예: PROFILE, EQUIPMENT)")
    ],
    # [FIX] Python 문법 준수: 기본값이 없는 'file' 인자를 기본값이 있는 'ref_id' 앞으로 이동하거나
    # 모든 선택적 인자를 뒤로 밀어야 합니다. 여기선 'file'을 먼저 받도록 조정합니다.
    file: Annotated[UploadFile, File(...)],
    ref_id: Annotated[
        int | None, Query(description="연결될 레코드 PK (나중에 연결 가능)")
    ] = None,
    category_code: Annotated[str, Query(description="파일 분류 코드")] = "GENERAL",
):
    """단일 파일을 업로드하고 메타데이터를 저장합니다."""
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
        raise InternalServerErrorException(
            domain=DOMAIN, error_code=ErrorCode.STORAGE_ERROR
        )

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

    new_attachment = await AttachmentService.create_attachment_metadata(
        db, obj_in=attachment_in
    )
    await db.commit()

    return APIResponse(
        domain=DOMAIN, data=new_attachment, success_code=SuccessCode.SUCCESS_CREATED
    )


@router.delete("/attachments/{attachment_id}", response_model=APIResponse[None])
async def delete_attachment(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    attachment_id: uuid.UUID,
    permanent: Annotated[
        bool, Query(description="즉시 물리 삭제 여부 (관리자 전용)")
    ] = False,
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
    return APIResponse(
        domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_DELETED
    )


@router.get("/attachments/deleted", response_model=APIResponse[list[AttachmentRead]])
async def list_deleted_attachments(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    domain_code: Annotated[
        str | None, Query(description="도메인 코드 (예: FAC)")
    ] = None,
    resource_type: Annotated[
        str | None, Query(description="리소스 유형 (예: EQUIPMENT)")
    ] = None,
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
    return APIResponse(
        domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_UPDATED
    )


@router.get("/attachments/{attachment_id}/download")
async def download_attachment(
    attachment_id: uuid.UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    token: Annotated[
        str | None, Query(description="인증 토큰 (img 태그 호출용)")
    ] = None,
):
    """첨부파일 다운로드 엔드포인트."""
    attachment = await AttachmentService.get_attachment(db, attachment_id)
    url = await get_presigned_url(attachment.file_path)
    if not url:
        raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
    return RedirectResponse(url)


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
    await NotificationService.mark_as_read(
        db, notification_id=notification_id, user_id=current_user.id
    )
    return APIResponse(
        domain=DOMAIN, data=None, success_code=SuccessCode.SUCCESS_UPDATED
    )
