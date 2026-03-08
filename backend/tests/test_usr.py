import pytest
from fastapi import status
import uuid
from app.core.exceptions import ConflictException, BadRequestException
from sqlalchemy.exc import IntegrityError

@pytest.mark.anyio
async def test_organization_circular_reference(client, auth_token):
    """조직 순환 참조 방지 로직 검증"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 조직 A, B 생성
    res_a = await client.post("/api/v1/usr/organizations", headers=headers, json={
        "name": "부서A", "code": f"A_{uuid.uuid4().hex[:4]}".upper()
    })
    org_a_id = res_a.json()["data"]["id"]
    
    res_b = await client.post("/api/v1/usr/organizations", headers=headers, json={
        "name": "부서B", "code": f"B_{uuid.uuid4().hex[:4]}".upper(), "parent_id": org_a_id
    })
    org_b_id = res_b.json()["data"]["id"]

    # 2. 자신을 부모로 설정 시도 (A -> A)
    with pytest.raises(BadRequestException) as exc:
        await client.patch(f"/api/v1/usr/organizations/{org_a_id}", headers=headers, json={
            "parent_id": org_a_id
        })
    # 4004: INVALID_PARENT_ORG
    assert str(exc.value.error_code) == "4004"

    # 3. 순환 참조 시도 (A의 부모를 자신의 자식인 B로 설정: B -> A -> B)
    with pytest.raises(BadRequestException) as exc:
        await client.patch(f"/api/v1/usr/organizations/{org_a_id}", headers=headers, json={
            "parent_id": org_b_id
        })
    # 4005: CIRCULAR_REFERENCE
    assert str(exc.value.error_code) == "4005"

    # 정리
    await client.delete(f"/api/v1/usr/organizations/{org_b_id}", headers=headers)
    await client.delete(f"/api/v1/usr/organizations/{org_a_id}", headers=headers)

@pytest.mark.anyio
async def test_organization_deep_tree_serialization(client, auth_token):
    """깊은 계층 구조 트리 직렬화 및 지연 로딩 방지 검증"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 5단계 계층 생성
    parent_id = None
    org_ids = []
    for i in range(5):
        res = await client.post("/api/v1/usr/organizations", headers=headers, json={
            "name": f"Level_{i}", 
            "code": f"L{i}_{uuid.uuid4().hex[:4]}".upper(), 
            "parent_id": parent_id
        })
        parent_id = res.json()["data"]["id"]
        org_ids.append(parent_id)

    # 트리 조회 (수정된 서비스 로직으로 지연 로딩 에러 없이 직렬화되어야 함)
    res = await client.get("/api/v1/usr/organizations?mode=tree", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    
    # 데이터 구조 검증 (최상위 레벨 확인)
    data = res.json()["data"]
    assert any(org["name"] == "Level_0" for org in data)

    # 정리
    for oid in reversed(org_ids):
        await client.delete(f"/api/v1/usr/organizations/{oid}", headers=headers)

@pytest.mark.anyio
async def test_organization_crud_and_constraints(client, auth_token):
    headers = {"Authorization": f"Bearer {auth_token}"}
    org_code = f"ORG_{uuid.uuid4().hex[:6].upper()}"
    
    res = await client.post("/api/v1/usr/organizations", headers=headers, json={
        "name": "테스트 부서", "code": org_code, "sort_order": 1
    })
    org_id = res.json()["data"]["id"]

    sub_code = f"SUB_{uuid.uuid4().hex[:6].upper()}"
    res = await client.post("/api/v1/usr/organizations", headers=headers, json={
        "name": "하위 부서", "code": sub_code, "parent_id": org_id
    })
    sub_id = res.json()["data"]["id"]

    with pytest.raises(ConflictException):
        await client.delete(f"/api/v1/usr/organizations/{org_id}", headers=headers)

    await client.delete(f"/api/v1/usr/organizations/{sub_id}", headers=headers)
    await client.delete(f"/api/v1/usr/organizations/{org_id}", headers=headers)

@pytest.mark.anyio
async def test_user_creation_and_duplicate_check(client, auth_token):
    headers = {"Authorization": f"Bearer {auth_token}"}
    login_id = f"user_{uuid.uuid4().hex[:6]}"
    user_data = {
        "login_id": login_id, "password": "Password123!", "name": "테스트유저",
        "emp_code": uuid.uuid4().hex[:8].upper(), "email": f"{login_id}@example.com", "is_active": True
    }
    res = await client.post("/api/v1/usr/users", headers=headers, json=user_data)
    user_id = res.json()["data"]["id"]

    with pytest.raises(ConflictException):
        await client.post("/api/v1/usr/users", headers=headers, json=user_data)

    await client.delete(f"/api/v1/usr/{user_id}", headers=headers)

@pytest.mark.anyio
async def test_user_update_security(client, auth_token):
    headers = {"Authorization": f"Bearer {auth_token}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    my_id = me_res.json()["data"]["id"]
    
    await client.patch(f"/api/v1/usr/{my_id}", headers=headers, json={"name": "수정된이름"})

    with pytest.raises(IntegrityError):
        await client.patch(f"/api/v1/usr/{my_id}", headers=headers, json={"org_id": 9999})

@pytest.mark.anyio
async def test_usr_security_boundaries(client):
    res = await client.get("/api/v1/usr/organizations")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
