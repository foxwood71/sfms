from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from .service import CmmService, S3Service


router = APIRouter(prefix="/cmm", tags=["Common"])


@router.post("/upload")
async def upload_attachment(
    domain_code: str,
    ref_id: str,
    file: UploadFile = File(...),  # python-multipart가 필요한 부분
    db: Session = Depends(get_db)
):
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
        "content_type": file.content_type
    }
    return CmmService.register_attachment(db, attachment_data)
