"""인증 및 권한 관리(IAM) 도메인의 API 기능을 검증하는 테스트 모듈입니다.

사용자 역할(Role)의 CRUD 로직과 시스템 필수 역할 보호 정책,
그리고 로그아웃 시 토큰 블랙리스트 작동 여부를 검증합니다.
"""

import uuid

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.anyio
async def test_role_management(client, auth_token):
    """역할(Role) 정보의 생성, 조회, 수정, 삭제 사이클을 검증합니다.

    관리자 권한을 가진 사용자가 신규 역할을 정의하고
    권한 매트릭스를 수정하는 과정을 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    role_code = f"ROLE_{uuid.uuid4().hex[:6].upper()}"

    # 1. 역할 생성 (관리자)
    res = await client.post(
        "/api/v1/roles",
        headers=headers,
        json={
            "name": "테스트 역할",
            "code": role_code,
            "description": "테스트용 역할입니다",
            "permissions": {"USR": ["READ", "WRITE"]},
            "is_system": False,
        },
    )
    assert res.status_code == status.HTTP_201_CREATED
    role_id = res.json()["data"]["id"]

    # 2. 역할 목록 조회
    res = await client.get(
        "/api/v1/roles", headers=headers, params={"keyword": role_code}
    )
    assert res.status_code == status.HTTP_200_OK
    assert len(res.json()["data"]) >= 1

    # 3. 역할 수정
    res = await client.patch(
        f"/api/v1/roles/{role_id}", headers=headers, json={"name": "수정된 역할 명칭"}
    )
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["data"]["name"] == "수정된 역할 명칭"

    # 4. 역할 삭제
    res = await client.delete(f"/api/v1/roles/{role_id}", headers=headers)
    assert res.status_code == status.HTTP_200_OK


@pytest.mark.anyio
async def test_role_assignment_and_metadata(client, auth_token):
    """사용자에게 역할을 할당하고 권한 리소스 메타데이터를 조회하는 기능을 검증합니다.

    특정 사용자에게 역할 ID 목록을 부여하고 정상 처리되는지 확인합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 1. 권한 리소스 메타데이터 조회
    res = await client.get("/api/v1/roles/permissions/resources", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    assert isinstance(res.json()["data"], dict)

    # 2. 사용자 역할 할당 (내 자신에게 다시 할당 시도)
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    my_id = me_res.json()["data"]["id"]

    res = await client.put(
        f"/api/v1/roles/users/{my_id}/roles",
        headers=headers,
        json={"user_id": my_id, "role_ids": [1]},
    )
    assert res.status_code == status.HTTP_200_OK


@pytest.mark.anyio
async def test_auth_logout_and_blacklist(client):
    """로그아웃 처리 및 블랙리스트 기반 접근 차단 로직을 검증합니다.

    로그아웃된 토큰으로 다시 API를 호출했을 때 401 Unauthorized 응답과
    함께 TOKEN_BLACKLISTED(4013) 에러 코드가 반환되는지 테스트합니다.
    """
    unique_id = uuid.uuid4().hex[:6]

    # 1. 임시 사용자 생성
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        admin_login = await ac.post(
            "/api/v1/auth/login", json={"login_id": "admin", "password": "admin1234"}
        )
        admin_token = admin_login.json()["data"]["access_token"]
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        await ac.post(
            "/api/v1/usr/users",
            headers=admin_headers,
            json={
                "login_id": f"tmp_{unique_id}",
                "password": "Password123!",
                "name": "임시사용자",
                "emp_code": f"EMP_{unique_id.upper()}",
                "email": f"tmp_{unique_id}@example.com",
                "is_active": True,
            },
        )

        # 2. 임시 사용자 로그인
        login_res = await ac.post(
            "/api/v1/auth/login",
            json={"login_id": f"tmp_{unique_id}", "password": "Password123!"},
        )
        tmp_token = login_res.json()["data"]["access_token"]
        tmp_headers = {"Authorization": f"Bearer {tmp_token}"}

        # 3. 로그아웃
        res = await ac.post("/api/v1/auth/logout", headers=tmp_headers)
        assert res.status_code == status.HTTP_200_OK

        # 4. 로그아웃 후 접근 시도 -> 401 Unauthorized 확인
        res = await ac.get("/api/v1/auth/me", headers=tmp_headers)
        assert res.status_code == status.HTTP_401_UNAUTHORIZED
        assert res.json()["error_code"] == 4013  # TOKEN_BLACKLISTED


@pytest.mark.anyio
async def test_iam_security_boundaries(client):
    """인증 정보 없이 관리자 전용 기능에 접근할 때의 차단 여부를 검증합니다."""
    res = await client.post("/api/v1/roles", json={"name": "Hacker", "code": "HACK"})
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
