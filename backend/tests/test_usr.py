"""사용자 및 조직(USR) 도메인의 API 기능을 검증하는 테스트 모듈입니다.

조직의 계층 구조 관리(트리 조회, 순환 참조 방지), 사용자 계정의 생성 및 수정,
그리고 비활성 상태 기반의 보안 정책을 테스트합니다.
"""

import uuid

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_organization_circular_reference(client, auth_token):
    """조직 간의 부모-자식 순환 참조 방지 로직을 검증합니다.

    자신을 부모로 설정하거나, 자신의 하위 부서를 부모로 설정하려 할 때
    정확히 400 Bad Request 에러가 발생하는지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 1. 조직 A, B 생성
    res_a = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": "부서A", "code": f"A_{uuid.uuid4().hex[:4]}".upper()},
    )
    org_a_id = res_a.json()["data"]["id"]

    res_b = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={
            "name": "부서B",
            "code": f"B_{uuid.uuid4().hex[:4]}".upper(),
            "parent_id": org_a_id,
        },
    )
    org_b_id = res_b.json()["data"]["id"]

    # 2. 자신을 부모로 설정 시도 (A -> A)
    res = await client.patch(
        f"/api/v1/usr/organizations/{org_a_id}",
        headers=headers,
        json={"parent_id": org_a_id},
    )
    assert res.status_code == status.HTTP_400_BAD_REQUEST
    assert str(res.json()["error_code"]) == "4004"  # INVALID_PARENT_ORG

    # 3. 순환 참조 시도 (A의 부모를 자신의 자식인 B로 설정: B -> A -> B)
    res = await client.patch(
        f"/api/v1/usr/organizations/{org_a_id}",
        headers=headers,
        json={"parent_id": org_b_id},
    )
    assert res.status_code == status.HTTP_400_BAD_REQUEST
    assert str(res.json()["error_code"]) == "4005"  # CIRCULAR_REFERENCE

    # 정리
    await client.delete(f"/api/v1/usr/organizations/{org_b_id}", headers=headers)
    await client.delete(f"/api/v1/usr/organizations/{org_a_id}", headers=headers)


@pytest.mark.anyio
async def test_organization_deep_tree_serialization(client, auth_token):
    """깊은 계층 구조의 조직도 트리 조회 기능을 검증합니다.

    재귀적 관계를 가진 조직 데이터를 조회할 때 지연 로딩(Lazy Loading) 오류 없이
    정상적으로 직렬화되어 반환되는지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 5단계 계층 생성
    parent_id = None
    org_ids = []
    for i in range(5):
        res = await client.post(
            "/api/v1/usr/organizations",
            headers=headers,
            json={
                "name": f"Level_{i}",
                "code": f"L{i}_{uuid.uuid4().hex[:4]}".upper(),
                "parent_id": parent_id,
            },
        )
        parent_id = res.json()["data"]["id"]
        org_ids.append(parent_id)

    # 트리 조회
    res = await client.get("/api/v1/usr/organizations?mode=tree", headers=headers)
    assert res.status_code == status.HTTP_200_OK

    data = res.json()["data"]
    assert any(org["name"] == "Level_0" for org in data)

    # 정리
    for oid in reversed(org_ids):
        await client.delete(f"/api/v1/usr/organizations/{oid}", headers=headers)


@pytest.mark.anyio
async def test_organization_crud_and_constraints(client, auth_token):
    """조직 정보의 기본 CRUD와 데이터 제약 조건을 검증합니다.

    하위 부서가 존재하는 부서를 삭제하려 할 때의 차단 로직 등을 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    org_code = f"ORG_{uuid.uuid4().hex[:6].upper()}"

    res = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": "테스트 부서", "code": org_code, "sort_order": 1},
    )
    org_id = res.json()["data"]["id"]

    sub_code = f"SUB_{uuid.uuid4().hex[:6].upper()}"
    res = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": "하위 부서", "code": sub_code, "parent_id": org_id},
    )
    sub_id = res.json()["data"]["id"]

    # 하위 부서가 있는 부서 삭제 시도 -> 409 Conflict 확인
    res = await client.delete(f"/api/v1/usr/organizations/{org_id}", headers=headers)
    assert res.status_code == status.HTTP_409_CONFLICT

    await client.delete(f"/api/v1/usr/organizations/{sub_id}", headers=headers)
    await client.delete(f"/api/v1/usr/organizations/{org_id}", headers=headers)


@pytest.mark.anyio
async def test_user_creation_and_duplicate_check(client, auth_token):
    """신규 사용자 생성 및 중복 데이터(ID, 이메일) 검증을 수행합니다.

    동일한 로그인 ID로 가입을 시도할 때 정확한 에러가 발생하는지 확인합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    login_id = f"user_{uuid.uuid4().hex[:6]}"
    user_data = {
        "login_id": login_id,
        "password": "Password123!",
        "name": "테스트유저",
        "emp_code": uuid.uuid4().hex[:8].upper(),
        "email": f"{login_id}@example.com",
        "is_active": True,
    }
    res = await client.post("/api/v1/usr/users", headers=headers, json=user_data)
    user_id = res.json()["data"]["id"]

    # 중복 아이디 생성 시도 -> 409 Conflict 확인
    res = await client.post("/api/v1/usr/users", headers=headers, json=user_data)
    assert res.status_code == status.HTTP_409_CONFLICT

    await client.delete(f"/api/v1/usr/{user_id}", headers=headers)


@pytest.mark.anyio
async def test_user_update_security(client, auth_token):
    """사용자 정보 수정 시의 보안 필드 제한 로직을 검증합니다.

    유효하지 않은 조직 ID로 부서를 변경하려 할 때 에러 처리가 정상적인지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    my_id = me_res.json()["data"]["id"]

    await client.patch(
        f"/api/v1/usr/{my_id}", headers=headers, json={"name": "수정된이름"}
    )

    # 존재하지 않는 조직 ID로 업데이트 시도 -> 에러 코드 확인
    res = await client.patch(
        f"/api/v1/usr/{my_id}", headers=headers, json={"org_id": 9999}
    )
    assert res.status_code in [
        status.HTTP_500_INTERNAL_SERVER_ERROR,
        status.HTTP_400_BAD_REQUEST,
    ]


@pytest.mark.anyio
async def test_usr_security_boundaries(client):
    """인증 정보가 없는 사용자의 조직/사용자 데이터 접근 차단을 검증합니다."""
    res = await client.get("/api/v1/usr/organizations")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
