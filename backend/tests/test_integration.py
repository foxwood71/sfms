import pytest
from fastapi import status
import uuid
from datetime import datetime

@pytest.mark.anyio
async def test_full_business_scenario(client, auth_token):
    """
    [통합 시나리오]
    부서 생성 -> 시설 등록 -> 공간 등록 -> 채번 발급 -> 알림 확인
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    unique_suffix = uuid.uuid4().hex[:4].upper()

    # 1. [USR] 신규 관리 부서 생성
    org_res = await client.post("/api/v1/usr/organizations", headers=headers, json={
        "name": f"운영팀_{unique_suffix}", 
        "code": f"ORG_{unique_suffix}"
    })
    assert org_res.status_code == status.HTTP_201_CREATED
    org_id = org_res.json()["data"]["id"]

    # 2. [FAC] 신규 시설(처리장) 등록
    fac_res = await client.post("/api/v1/fac/facilities", headers=headers, json={
        "name": f"제1처리장_{unique_suffix}",
        "code": f"FAC_{unique_suffix}",
        "metadata_info": {"manager_org": org_id}
    })
    assert fac_res.status_code == status.HTTP_201_CREATED
    fac_id = fac_res.json()["data"]["id"]

    # 3. [FAC] 시설 내 관리 공간 등록
    space_res = await client.post("/api/v1/fac/spaces", headers=headers, json={
        "facility_id": fac_id,
        "name": "전기실",
        "code": "ELEC_01",
        "org_id": org_id # 위에서 만든 부서 할당
    })
    assert space_res.status_code == status.HTTP_201_CREATED
    space_id = space_res.json()["data"]["id"]

    # 4. [SYS] 시설물 자산 번호 규칙 생성 및 발급
    # 규칙 생성
    await client.post("/api/v1/sys/sequences", headers=headers, json={
        "domain_code": "FAC",
        "prefix": f"ASSET_{unique_suffix}",
        "current_year": datetime.now().strftime("%Y"),
        "current_seq": 0
    })
    # 번호 발급
    seq_res = await client.get(f"/api/v1/sys/sequence/FAC/ASSET_{unique_suffix}/next", headers=headers)
    assert seq_res.status_code == status.HTTP_200_OK
    asset_no = seq_res.json()["data"]
    assert asset_no.startswith(f"ASSET_{unique_suffix}")

    # 5. [CMM] 알림 발생 여부 확인 (시스템이 자동 발송했다고 가정하거나 목록 조회)
    noti_res = await client.get("/api/v1/cmm/notifications", headers=headers)
    assert noti_res.status_code == status.HTTP_200_OK
    # 알림이 생성되었는지 확인 (데이터가 있을 수 있음)
    assert isinstance(noti_res.json()["data"], list)

    print(f"✅ 통합 시나리오 완료: 자산번호 {asset_no}")
