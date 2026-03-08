import pytest
import uuid
from fastapi import status
from datetime import datetime

@pytest.mark.anyio
async def test_sys_sequence_full_cycle(client, auth_token):
    """채번 규칙 생성부터 실제 번호 발급까지의 전체 사이클을 검증합니다."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 외래키 제약 조건을 피하기 위해 실제 존재하는 도메인(FAC) 사용
    domain = "FAC"
    # 중복 방지를 위해 랜덤한 접두어 생성
    prefix = f"T{uuid.uuid4().hex[:3].upper()}"
    current_year = datetime.now().strftime("%Y")

    # 1. 채번 규칙 생성 (관리자)
    res = await client.post("/api/v1/sys/sequences", headers=headers, json={
        "domain_code": domain,
        "prefix": prefix,
        "year_format": "YYYY",
        "separator": "-",
        "padding_length": 4,
        "reset_type": "YEARLY",
        "current_year": current_year,
        "current_seq": 0,
        "is_active": True
    })
    assert res.status_code == status.HTTP_201_CREATED
    rule_id = res.json()["data"]["id"]

    # 2. 다음 번호 발급
    res = await client.get(f"/api/v1/sys/sequence/{domain}/{prefix}/next", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["data"] == f"{prefix}-{current_year}-0001"

    # 3. 규칙 수정 (PATCH)
    res = await client.patch(f"/api/v1/sys/sequences/{rule_id}", headers=headers, json={
        "separator": "_",
        "padding_length": 6
    })
    assert res.status_code == status.HTTP_200_OK
    
    # 수정 후 발급 확인 (번호는 이어서 발급됨)
    res = await client.get(f"/api/v1/sys/sequence/{domain}/{prefix}/next", headers=headers)
    assert res.json()["data"] == f"{prefix}_{current_year}_000002"

    # 4. 규칙 삭제 (DELETE)
    res = await client.delete(f"/api/v1/sys/sequences/{rule_id}", headers=headers)
    assert res.status_code == status.HTTP_200_OK

@pytest.mark.anyio
async def test_audit_log_filtering(client, auth_token):
    """감사 로그 조회 및 필터링 기능을 검증합니다."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 전체 조회
    res = await client.get("/api/v1/sys/audit-logs?limit=10", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["domain"] == "SYS"

    # 2. 도메인 필터링 조회
    res = await client.get("/api/v1/sys/audit-logs?target_domain=SYS", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    
@pytest.mark.anyio
async def test_sys_security_boundary(client):
    """인증되지 않은 사용자의 접근 차단을 검증합니다."""
    res = await client.get("/api/v1/sys/sequences")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
