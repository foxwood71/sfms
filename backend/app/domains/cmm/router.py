"""CMM (Common Module Management) API 엔드포인트.

공통 코드그룹 관리 및 MinIO S3 파일 업로드 API.
PostgreSQL 'cmm' 스키마와 연동.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.domains.cmm.schemas import CodeGroupCreate, CodeGroupResponse
from app.domains.cmm.service import CmmService, S3Service

router = APIRouter(prefix="/cmm", tags=["Common"])
service: CmmService = CmmService()


@router.get("/groups")
def get_groups(db: Annotated[Session, Depends(get_db)]) -> list[CodeGroupResponse]:
    """활성 공통 코드그룹 목록 조회.

    Returns:
        List[CodeGroupResponse]: 모든 활성 코드그룹 목록.

    """
    return service.get_code_groups(db)


# [추가] 그룹 생성 API (POST)
@router.post(
    "/groups",
    status_code=status.HTTP_201_CREATED,
)
def create_group(
    group_data: CodeGroupCreate,
    db: Annotated[Session, Depends(get_db)],
) -> CodeGroupResponse:
    """새로운 공통 코드 그룹을 생성합니다.

    Args:
        group_data: 생성할 코드그룹 데이터 (group_code, group_name 등).
        db: SQLAlchemy 세션.

    Returns:
        CodeGroupResponse: 생성된 코드그룹 정보.

    Raises:
        HTTPException: 중복 group_code 또는 DB 오류 시.

    """
    return service.create_code_group(db, group_data)


@router.post("/upload")
async def upload_attachment(
    domain_code: str,
    ref_id: str,
    file: Annotated[UploadFile, File(...)],
    db: Annotated[Session, Depends(get_db)],
) -> dict[str, str | int]:  # 반환 타입 명시
    """도메인별 파일 첨부 업로드.

    MinIO S3-compatible 스토리지에 저장 후 DB 등록.

    Args:
        domain_code: 도메인 코드 (예: FAC).
        ref_id: 연관 데이터 ID (예: FAC-001).
        file: 업로드 파일 (multipart/form-data).
        db: DB 세션.

    Returns:
        dict: 업로드 결과 {"file_id": uuid, "object_name": path, "status": "success"}.

    Raises:
        HTTPException(500): MinIO 업로드/DB 등록 실패.
        HTTPException(422): 파일 형식 오류.

    """
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
