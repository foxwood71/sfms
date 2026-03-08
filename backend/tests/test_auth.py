import pytest
from fastapi import status
from app.core.codes import SuccessCode

@pytest.mark.anyio
async def test_login_and_token_schema(client):
    """로그인 API 호출을 통해 토큰 스키마와 응답 규격을 검증합니다."""
    login_data = {"login_id": "admin", "password": "admin1234"}
    response = await client.post("/api/v1/auth/login", json=login_data)
    
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["domain"] == "IAM"
    assert "access_token" in data["data"]

@pytest.mark.anyio
async def test_get_my_info_with_token(client, auth_token):
    """발급받은 토큰을 사용하여 내 정보 조회 API를 검증합니다."""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {auth_token}"}
    )
    
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["data"]["login_id"] == "admin"
