"""공통 관리(CMM) 도메인의 API 엔드포인트를 정의하는 라우터 모듈입니다."""

import uuid

from fastapi import APIRouter, Depends, File, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.exceptions import (
    ConflictException,  # 업로드 실패 시 에러 처리를 위해 추가
)
from app.core.schemas import APIResponse
from app.core.storage import delete_file, upload_file_stream
from app.domains.cmm.schemas import AttachmentCreate, AttachmentRead
from app.domains.cmm.services import AttachmentService, SystemSequenceService

router = APIRouter(prefix="/cmm", tags=["공통 관리 (CMM)"])


# --------------------------------------------------------
# [Attachment] 파일 업로드 API
# --------------------------------------------------------
@router.post(
    "/upload",
    response_model=APIResponse[AttachmentRead],
    status_code=status.HTTP_201_CREATED,
)
async def upload_file(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    """
    단일 파일을 업로드하고 메타데이터를 DB에 저장합니다.

    FastAPI의 UploadFile 객체에서 바이너리 데이터를 읽어 MinIO 서버로 전송합니다.
    """
    # 1. 파일 데이터를 메모리로 읽어옵니다.
    file_data = await file.read()

    # 2. 메타데이터 객체를 미리 생성합니다. (이때 id 값으로 UUID가 자동 발급됩니다!)
    attachment_in = AttachmentCreate(
        original_name=file.filename or "unknown",
        file_size=len(file_data),  # 실제 읽어들인 바이트 크기 사용
        mime_type=file.content_type or "application/octet-stream",
        bucket_name="sfms-bucket",
        ref_domain=None,  # Pylance 타입 체킹 에러 방지를 위해 명시적 None 할당
        ref_id=None,  # Pylance 타입 체킹 에러 방지를 위해 명시적 None 할당
        created_by=None,  # Pylance 타입 체킹 에러 방지를 위해 명시적 None 할당
    )

    # 3. 발급된 UUID를 Object Name으로 사용하여 실제 MinIO 서버에 업로드!
    object_name = str(attachment_in.id)
    upload_success = upload_file_stream(
        object_name=object_name,
        file_data=file_data,
        content_type=attachment_in.mime_type,
        bucket_name=attachment_in.bucket_name,
    )

    # 업로드 실패 시 예외 처리 (DB에 메타데이터를 남기지 않음)
    if not upload_success:
        raise ConflictException(message="파일 스토리지 업로드에 실패했습니다.")

    # 4. 스토리지 업로드 성공 시 DB에 메타데이터 기록
    new_attachment = await AttachmentService.create_attachment_metadata(
        db, obj_in=attachment_in
    )

    return APIResponse(
        success=True,
        code=201,
        message="파일이 성공적으로 업로드되었습니다.",
        data=new_attachment,
    )


@router.delete("/attachments/{attachment_id}", response_model=APIResponse[None])
async def delete_attachment(
    attachment_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """
    첨부 파일 메타데이터 및 스토리지의 실제 파일을 삭제합니다.
    """
    # 1. MinIO 스토리지에서 실제 파일(Object) 삭제 호출
    # (삭제 실패 시 False를 반환하더라도 메타데이터 정리를 위해 진행하거나, 에러를 던질 수 있습니다)
    delete_file(object_name=str(attachment_id), bucket_name="sfms-bucket")

    # 2. 메타데이터 DB에서 삭제
    await AttachmentService.delete_attachment(db, attachment_id=attachment_id)

    return APIResponse(
        success=True,
        code=200,
        message="파일이 성공적으로 삭제되었습니다.",
        data=None,
    )


# --------------------------------------------------------
# [SystemSequence] 시스템 채번 API
# --------------------------------------------------------
@router.get("/sequence/{domain_code}", response_model=APIResponse[str])
async def get_next_sequence(
    domain_code: str,
    db: AsyncSession = Depends(get_db),
):
    """
    특정 도메인 코드(예: FAC_WORK_ORDER)에 대한 다음 시퀀스 번호를 발급받습니다.

    주로 백엔드 내부 비즈니스 로직에서 직접 호출되지만,
    프론트엔드에서 작성 화면 진입 시 코드를 미리 보여줘야 할 때 유용하게 사용할 수 있습니다.
    """
    next_seq = await SystemSequenceService.get_next_sequence(
        db, domain_code=domain_code
    )

    return APIResponse(
        success=True,
        code=200,
        message="시퀀스가 성공적으로 발급되었습니다.",
        data=next_seq,
    )
