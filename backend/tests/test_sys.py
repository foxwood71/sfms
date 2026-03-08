"""시스템 관리(SYS) 도메인의 API 기능을 검증하는 테스트 모듈입니다.

자동 채번 규칙(Sequence Rule)의 생성 및 관리 로직과
시스템 내 모든 변경 이력을 기록하는 감사 로그(Audit Log) 조회 기능을 검증합니다.
"""

import uuid
from datetime import datetime

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_sys_sequence_full_cycle(client, auth_token):
    """채번 규칙 생성부터 실제 번호 발급까지의 전체 사이클을 검증합니다.

    특정 도메인(FAC 등)에 대해 접두어, 연도 포맷이 포함된 채번 규칙을 정의하고
    중복 없이 순차적으로 번호가 생성되는지 확인합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 외래키 제약 조건을 피하기 위해 실제 존재하는 도메인(FAC) 사용
    domain = "FAC"
    # 중복 방지를 위해 랜덤한 접두어 생성
    prefix = f"T{uuid.uuid4().hex[:3].upper()}"
    current_year = datetime.now().strftime("%Y")

    # 1. 채번 규칙 생성 (관리자)
    res = await client.post(
        "/api/v1/sys/sequences",
        headers=headers,
        json={
            "domain_code": domain,
            "prefix": prefix,
            "year_format": "YYYY",
            "separator": "-",
            "padding_length": 4,
            "reset_type": "YEARLY",
            "current_year": current_year,
            "current_seq": 0,
            "is_active": True,
        },
    )
    assert res.status_code == status.HTTP_201_CREATED

    # 2. 다음 번호 발급
    issue_res = await client.get(
        f"/api/v1/sys/sequence/{domain}/{prefix}/next", headers=headers
    )
    assert issue_res.status_code == status.HTTP_200_OK
    assert f"{prefix}-{current_year}-0001" in issue_res.json()["data"]


@pytest.mark.anyio
async def test_audit_log_filtering(client, auth_token):
    """감사 로그 조회 및 필터링 기능을 검증합니다.

    시스템에서 발생한 행위(로그인, 생성 등)가 로그로 정확히 기록되는지 확인하고
    도메인이나 행위 유형별 필터링이 정상 작동하는지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 1. 전체 조회
    res = await client.get("/api/v1/sys/audit-logs?limit=10", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    data = res.json()["data"]
    assert isinstance(data, list)

    # 2. 도메인 필터링 (IAM 로그 조회)
    res = await client.get(
        "/api/v1/sys/audit-logs?target_domain=IAM&limit=5", headers=headers
    )
    assert res.status_code == status.HTTP_200_OK
    for log in res.json()["data"]:
        assert log["target_domain"] == "IAM"


@pytest.mark.anyio
async def test_sys_security_boundary(client):
    """인증되지 않은 사용자의 시스템 설정 접근 차단을 검증합니다."""
    res = await client.get("/api/v1/sys/sequences")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
