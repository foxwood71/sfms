"""인증(Auth) 관련 API 기능을 검증하는 테스트 모듈입니다.

로그인 성공/실패 시나리오, 토큰 발급 및 토큰을 이용한
내 정보 조회(Me API) 기능을 테스트합니다.
"""

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_login_and_token_schema(client):
    """로그인 API 호출을 통해 토큰 스키마와 응답 규격을 검증합니다.

    정상적인 아이디/비밀번호 입력 시 200 OK 응답과 함께
    access_token, refresh_token이 포함된 데이터가 반환되어야 합니다.
    """
    login_data = {"login_id": "admin", "password": "admin1234"}
    response = await client.post("/api/v1/auth/login", json=login_data)

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["success"] is True
    assert "access_token" in data["data"]
    assert "refresh_token" in data["data"]


@pytest.mark.anyio
async def test_get_my_info_with_token(client, auth_token):
    """유효한 토큰을 사용하여 내 정보 조회 API를 검증합니다.

    Authorization 헤더에 Bearer 토큰을 포함하여 요청했을 때
    로그인한 사용자의 상세 정보(ID, 이름 등)를 정확히 반환해야 합니다.
    """
    response = await client.get(
        "/api/v1/auth/me", headers={"Authorization": f"Bearer {auth_token}"}
    )

    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["data"]["login_id"] == "admin"
