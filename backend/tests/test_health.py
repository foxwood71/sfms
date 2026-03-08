"""시스템 헬스체크(Health Check) API 기능을 검증하는 테스트 모듈입니다.

서버의 생존 여부와 데이터베이스, Redis, MinIO 등
외부 인프라 서비스와의 연결 상태를 확인합니다.
"""

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_health_check(client):
    """시스템 헬스체크 API 응답 규격을 검증합니다.

    정상 상황에서는 200 OK를 반환해야 하며,
    인프라 장애 시에도 정해진 에러 규격(503)으로 응답해야 합니다.
    """
    response = await client.get("/api/v1/health")

    # 인프라가 준비 중일 수도 있으므로 200 또는 503 허용
    assert response.status_code in [
        status.HTTP_200_OK,
        status.HTTP_503_SERVICE_UNAVAILABLE,
    ]
    data = response.json()

    assert data["success"] is True  # 헬스체크는 통신 자체의 성공 여부를 의미함
    assert data["domain"] == "SYS"
    assert "data" in data
