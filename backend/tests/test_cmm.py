import pytest
import uuid
import io
from fastapi import status
from app.core.exceptions import NotFoundException, ConflictException

@pytest.mark.anyio
async def test_cmm_codes_extended(client, auth_token):
    """공통 코드 CRUD 확장 테스트 (수정 및 보호 로직)"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    group_code = f"GRP_{uuid.uuid4().hex[:6].upper()}"
    
    # 1. 코드 그룹 생성
    res = await client.post("/api/v1/cmm/codes", headers=headers, json={
        "group_code": group_code, "group_name": "초기그룹", "is_active": True
    })
    assert res.status_code == status.HTTP_201_CREATED
    
    # 2. 코드 그룹 수정 (PATCH)
    res = await client.patch(f"/api/v1/cmm/codes/{group_code}", headers=headers, json={
        "group_name": "수정그룹", "is_active": False
    })
    assert res.status_code == status.HTTP_200_OK

    # 3. 시스템 코드 보호 테스트
    sys_group = f"SYS_{uuid.uuid4().hex[:6].upper()}"
    await client.post("/api/v1/cmm/codes", headers=headers, json={
        "group_code": sys_group, "group_name": "시스템그룹", "is_system": True
    })
    
    # 삭제 시도 -> ConflictException 발생 확인
    with pytest.raises(ConflictException):
        await client.delete(f"/api/v1/cmm/codes/{sys_group}", headers=headers)
    
    # 정리
    await client.delete(f"/api/v1/cmm/codes/{group_code}", headers=headers)

@pytest.mark.anyio
async def test_attachment_security_and_purge(client, auth_token):
    """첨부파일 보안 및 영구 삭제 테스트"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 파일 업로드
    file_content = b"security test content"
    files = {"file": ("sec.txt", io.BytesIO(file_content), "text/plain")}
    params = {"domain_code": "CMM", "resource_type": "TEST", "ref_id": 999, "category_code": "SEC"}
    
    res = await client.post("/api/v1/cmm/upload", headers=headers, params=params, files=files)
    assert res.status_code == status.HTTP_201_CREATED
    attachment_id = res.json()["data"]["id"]
    
    # 2. 삭제 목록 필터링 테스트
    await client.delete(f"/api/v1/cmm/attachments/{attachment_id}", headers=headers)
    
    # 3. 관리자 영구 삭제 (Purge)
    await client.delete(f"/api/v1/cmm/attachments/{attachment_id}", headers=headers, params={"permanent": True})
    
    # 복구 시도 시 NotFoundException 발생 확인
    with pytest.raises(NotFoundException):
        await client.post(f"/api/v1/cmm/attachments/{attachment_id}/restore", headers=headers)

@pytest.mark.anyio
async def test_notification_security(client, auth_token):
    """알림 보안 테스트"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 내 알림 목록 조회
    res = await client.get("/api/v1/cmm/notifications", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    
    # 존재하지 않는 알림 읽기 시도 -> NotFoundException 발생 확인
    with pytest.raises(NotFoundException):
        await client.patch("/api/v1/cmm/notifications/999999/read", headers=headers)

@pytest.mark.anyio
async def test_list_codes(client, auth_token):
    res = await client.get("/api/v1/cmm/codes", headers={"Authorization": f"Bearer {auth_token}"})
    assert res.status_code == status.HTTP_200_OK
