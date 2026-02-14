"""CMM (Common Module Management) API 엔드포인트.

공통 코드그룹 관리 및 MinIO S3 파일 업로드 API.
PostgreSQL 'cmm' 스키마와 연동.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.domains.cmm.schemas import (
    AttachmentResponse,
    AttachmentUpdate,
    CodeDetailCreate,
    CodeDetailResponse,
    CodeDetailUpdate,
    CodeGroupCreate,
    CodeGroupResponse,
    CodeGroupUpdate,
    SequenceResponse,
)
from app.domains.cmm.service import CmmService, S3Service

router = APIRouter(prefix="/cmm", tags=["Common"])
service: CmmService = CmmService()


# --- 1. 공통 코드 그룹 관리 ---
@router.post(
    "/groups",
    status_code=status.HTTP_201_CREATED,
)
def create_group(
    group_data: CodeGroupCreate,
    db: Annotated[Session, Depends(get_db)],
) -> CodeGroupResponse:
    """새로운 공통 코드 그룹 생성."""
    return CmmService.create_code_group(db, group_data)


@router.patch("/groups/{group_code}", response_model=CodeGroupResponse)
def update_group(
    group_code: str, data: CodeGroupUpdate, db: Annotated[Session, Depends(get_db)]
):
    """공통 코드 그룹 정보를 부분 수정합니다."""
    return service.update_code_group(db, group_code, data)


@router.get("/groups")
def get_groups(db: Annotated[Session, Depends(get_db)]) -> list[CodeGroupResponse]:
    """활성 공통 코드그룹 목록 조회."""
    return CmmService.get_code_groups(db)


@router.delete("/groups/{group_code}", status_code=status.HTTP_204_NO_CONTENT)
def delete_group(group_code: str, db: Annotated[Session, Depends(get_db)]):
    """코드 그룹 삭제 (Cascade 옵션에 의해 하위 코드도 삭제됨)."""
    success = CmmService.delete_code_group(db, group_code)
    if not success:
        raise HTTPException(status_code=404, detail="삭제할 그룹을 찾을 수 없습니다.")
    return None


# --- 2. 상세 코드 관리 (Code Details) ---
@router.post("/groups/details", status_code=status.HTTP_201_CREATED)
def create_detail(
    data: CodeDetailCreate, db: Annotated[Session, Depends(get_db)]
) -> CodeDetailResponse:
    """새로운 상세 코드를 생성합니다."""
    return service.create_code_detail(db, data)


@router.patch(
    "/groups/{group_code}/details/{detail_code}", response_model=CodeDetailResponse
)
def update_detail(
    group_code: str,
    detail_code: str,
    data: CodeDetailUpdate,
    db: Annotated[Session, Depends(get_db)],
):
    """특정 그룹 내의 상세 코드 정보를 수정합니다."""
    return service.update_code_detail(db, group_code, detail_code, data)


@router.get("/groups/{group_code}/codes", response_model=list[CodeDetailResponse])
def get_codes(
    group_code: str, db: Annotated[Session, Depends(get_db)]
) -> list[CodeDetailResponse]:
    """특정 그룹의 상세 코드 목록을 조회합니다."""
    return CmmService.get_codes_by_group(db, group_code)


@router.delete(
    "/groups/{group_code}/details/{detail_code}", status_code=status.HTTP_204_NO_CONTENT
)
def delete_detail(
    group_code: str, detail_code: str, db: Annotated[Session, Depends(get_db)]
):
    """특정 상세 코드 삭제."""
    success = CmmService.delete_code_detail(db, group_code, detail_code)
    if not success:
        raise HTTPException(status_code=404, detail="삭제할 코드를 찾을 수 없습니다.")
    return None


# --- 3. 첨부파일 관리 (MinIO 연동) ---
@router.post("/upload")
async def upload_attachment(
    domain_code: str,
    ref_id: str,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[Session, Depends(get_db)],
) -> dict[str, str | int]:  # 반환 타입 명시
    """도메인별 파일 업로드 및 DB 메타데이터 등록."""
    #  1. 파일명 생성 및 경로 결정
    # file_content = await file.read()
    object_name = f"{domain_code}/{ref_id}/{file.filename}"

    #  2. MinIO에 파일 업로드 (boto3 활용)
    success = S3Service.upload_file(file.file, object_name)

    if not success:
        raise HTTPException(status_code=500, detail="파일 업로드 실패")

    #  3. DB에 파일 메타데이터 기록 (cmm.attachments 테이블)
    attachment_data = {
        "domain_code": domain_code,
        "ref_id": ref_id,
        "file_name": file.filename,
        "file_path": object_name,
        "file_size": file.size,
        "content_type": file.content_type,
    }
    return CmmService.register_attachment(db, attachment_data)


@router.patch("/attachments/{file_id}", response_model=AttachmentResponse)
def update_attachment_metadata(
    file_id: str, data: AttachmentUpdate, db: Annotated[Session, Depends(get_db)]
):
    """첨부파일의 파일명이나 참조 ID(ref_id)를 수정합니다."""
    return CmmService.update_attachment_metadata(db, file_id, data)


@router.get("/attachments/{file_id}", response_model=AttachmentResponse)
def get_attachment_info(file_id: str, db: Annotated[Session, Depends(get_db)]):
    """첨부파일의 상세 메타데이터(파일명, 크기, 타입 등)를 조회합니다."""
    file_info = CmmService.get_attachment(db, file_id)
    if not file_info:
        raise HTTPException(status_code=404, detail="파일 정보를 찾을 수 없습니다.")
    return file_info


@router.delete("/attachments/{file_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_attachment(file_id: str, db: Annotated[Session, Depends(get_db)]):
    """첨부파일을 삭제 처리(Soft Delete)합니다."""
    success = service.delete_attachment(db, file_id)
    if not success:
        raise HTTPException(status_code=404, detail="삭제할 파일을 찾을 수 없습니다.")
    return None


@router.get("/download/{file_id}")
async def download_attachment(file_id: str, db: Annotated[Session, Depends(get_db)]):
    """첨부파일을 다운로드합니다."""
    # 1. DB에서 파일 정보 조회
    file_info = service.get_attachment(db, file_id)
    if not file_info:
        raise HTTPException(status_code=404, detail="파일을 찾을 수 없습니다.")

    # 2. S3에서 파일 스트림 획득
    file_stream = S3Service.download_file(file_info.file_path)
    if not file_stream:
        raise HTTPException(
            status_code=500, detail="스토리지에서 파일을 가져오지 못했습니다."
        )

    # 3. 파일 이름 인코딩 처리 후 반환
    return StreamingResponse(
        file_stream,
        media_type=file_info.content_type,
        headers={"Content-Disposition": f"attachment; filename={file_info.file_name}"},
    )


# --- 4. 기타 공통 기능 ---
@router.get("/sequence/{domain_code}", response_model=SequenceResponse)
def get_sequence(domain_code: str, db: Annotated[Session, Depends(get_db)]):
    """도메인별 새 시퀀스 번호(예: FAC-2026-001)를 생성합니다."""
    seq = service.generate_next_sequence(db, domain_code)
    return {"sequence": seq}
