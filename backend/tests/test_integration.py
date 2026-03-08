"""전체 시스템 도메인을 가로지르는 통합 비즈니스 시나리오 테스트 모듈입니다.

부서 생성부터 시설/공간 등록, 그리고 이를 연동한 자산번호 채번과
알림 발생까지의 실제 업무 흐름을 엔드투엔드(End-to-End)로 검증합니다.
"""

import uuid
from datetime import datetime

import pytest
from fastapi import status
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.mark.anyio
async def test_full_business_scenario(client):
    """실제 업무 프로세스를 모사한 통합 시나리오를 테스트합니다.

    1. 관리 부서 생성 (USR)
    2. 해당 부서가 관리할 시설 및 공간 등록 (FAC)
    3. 시설물 관리를 위한 자산번호 규칙 생성 및 발급 (SYS)
    4. 일련의 과정에 대한 시스템 알림 확인 (CMM)
    """
    # 0. 직접 로그인하여 독립적인 토큰 획득
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        login_res = await ac.post(
            "/api/v1/auth/login", json={"login_id": "admin", "password": "admin1234"}
        )
        token = login_res.json()["data"]["access_token"]

    headers = {"Authorization": f"Bearer {token}"}
    unique_suffix = uuid.uuid4().hex[:4].upper()

    # 1. [USR] 신규 관리 부서 생성
    org_res = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": f"운영팀_{unique_suffix}", "code": f"ORG_{unique_suffix}"},
    )
    assert org_res.status_code == status.HTTP_201_CREATED
    org_id = org_res.json()["data"]["id"]

    # 2. [FAC] 시설 등록
    fac_res = await client.post(
        "/api/v1/fac/facilities",
        headers=headers,
        json={
            "name": f"통합테스트사업소_{unique_suffix}",
            "code": f"SITE_{unique_suffix}",
            "sort_order": 99,
        },
    )
    assert fac_res.status_code == status.HTTP_201_CREATED
    fac_id = fac_res.json()["data"]["id"]

    # 3. [FAC] 공간 등록 (부서 연결)
    space_res = await client.post(
        "/api/v1/fac/spaces",
        headers=headers,
        json={
            "facility_id": fac_id,
            "name": "제어실",
            "code": f"ROOM_{unique_suffix}",
            "org_id": org_id,
        },
    )
    assert space_res.status_code == status.HTTP_201_CREATED
    space_id = space_res.json()["data"]["id"]

    # 4. [SYS] 자산번호 채번 규칙 생성 및 발급 테스트
    prefix = f"A{unique_suffix}"
    domain = "FAC"
    seq_res = await client.post(
        "/api/v1/sys/sequences",
        headers=headers,
        json={
            "domain_code": domain,
            "prefix": prefix,
            "year_format": "YYYY",
            "separator": "-",
            "padding_length": 4,
            "reset_type": "YEARLY",
            "current_year": datetime.now().strftime("%Y"),
            "current_seq": 0,
        },
    )
    assert seq_res.status_code == status.HTTP_201_CREATED

    # 채번 실행
    issue_res = await client.get(
        f"/api/v1/sys/sequence/{domain}/{prefix}/next", headers=headers
    )
    assert issue_res.status_code == status.HTTP_200_OK
    asset_no = issue_res.json()["data"]
    assert asset_no.startswith(prefix)

    # 5. [CMM] 알림 발생 확인
    noti_res = await client.get("/api/v1/cmm/notifications", headers=headers)
    assert noti_res.status_code == status.HTTP_200_OK
    assert isinstance(noti_res.json()["data"], list)

    print(f"✅ 통합 시나리오 완료: 자산번호 {asset_no}")
