import pytest
from fastapi import status

@pytest.mark.anyio
async def test_health_check(client):
    """시스템 헬스체크 API 응답 규격을 검증합니다."""
    response = await client.get("/api/v1/health")
    
    assert response.status_code in [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE]
    data = response.json()
    
    assert data["success"] is True
    assert data["domain"] == "SYS"
    assert "data" in data
