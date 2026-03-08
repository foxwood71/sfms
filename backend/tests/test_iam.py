import pytest
from fastapi import status
import uuid
from app.core.exceptions import UnauthorizedException

@pytest.mark.anyio
async def test_role_management(client, auth_token):
    """역할 CRUD 및 보호 로직 검증 (로그아웃 전 수행)"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    role_code = f"ROLE_{uuid.uuid4().hex[:6].upper()}"
    
    # 1. 역할 생성 (관리자)
    res = await client.post("/api/v1/roles", headers=headers, json={
        "name": "테스트 역할",
        "code": role_code,
        "description": "테스트용 역할입니다",
        "permissions": {"USR": ["READ", "WRITE"]},
        "is_system": False
    })
    assert res.status_code == status.HTTP_201_CREATED
    role_id = res.json()["data"]["id"]

    # 2. 역할 목록 조회
    res = await client.get("/api/v1/roles", headers=headers, params={"keyword": role_code})
    assert res.status_code == status.HTTP_200_OK
    assert len(res.json()["data"]) >= 1

    # 3. 역할 수정
    res = await client.patch(f"/api/v1/roles/{role_id}", headers=headers, json={
        "name": "수정된 역할 명칭"
    })
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["data"]["name"] == "수정된 역할 명칭"

    # 4. 역할 삭제
    res = await client.delete(f"/api/v1/roles/{role_id}", headers=headers)
    assert res.status_code == status.HTTP_200_OK

@pytest.mark.anyio
async def test_role_assignment_and_metadata(client, auth_token):
    """사용자 역할 할당 및 권한 메타데이터 조회 검증"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 권한 리소스 메타데이터 조회
    res = await client.get("/api/v1/roles/permissions/resources", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    assert isinstance(res.json()["data"], dict)

    # 2. 사용자 역할 할당 (내 자신에게 다시 할당 시도)
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    my_id = me_res.json()["data"]["id"]
    
    res = await client.put(f"/api/v1/roles/users/{my_id}/roles", headers=headers, json={
        "user_id": my_id,
        "role_ids": [1] 
    })
    assert res.status_code == status.HTTP_200_OK

@pytest.mark.anyio
async def test_auth_logout_and_blacklist(client, auth_token):
    """로그아웃 및 블랙리스트 작동 검증 (마지막에 수행)"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 내 정보 조회 (정상)
    res = await client.get("/api/v1/auth/me", headers=headers)
    assert res.status_code == status.HTTP_200_OK

    # 2. 로그아웃
    res = await client.post("/api/v1/auth/logout", headers=headers)
    assert res.status_code == status.HTTP_200_OK

    # 3. 로그아웃 후 접근 시도 -> UnauthorizedException 발생 확인
    # FastAPI 앱 내부에서 예외가 터지므로 pytest.raises 사용
    with pytest.raises(UnauthorizedException):
        await client.get("/api/v1/auth/me", headers=headers)

@pytest.mark.anyio
async def test_iam_security_boundaries(client):
    """인증 없이 관리자 기능 접근 차단 검증"""
    res = await client.post("/api/v1/roles", json={"name": "Hacker", "code": "HACK"})
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
