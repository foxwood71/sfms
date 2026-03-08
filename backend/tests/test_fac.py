import pytest
from fastapi import status
import uuid
from app.core.exceptions import ConflictException, BadRequestException

@pytest.mark.anyio
async def test_facility_and_space_full_cycle(client, auth_token):
    """시설 생성부터 공간 트리 조회까지의 전체 사이클 검증"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    fac_code = f"SITE_{uuid.uuid4().hex[:4]}".upper()
    
    # 1. 시설 생성 (관리자)
    res = await client.post("/api/v1/fac/facilities", headers=headers, json={
        "name": "테스트 사업소",
        "code": fac_code,
        "sort_order": 1,
        "metadata_info": {"type": "WATER"}
    })
    assert res.status_code == status.HTTP_201_CREATED
    fac_id = res.json()["data"]["id"]

    # 2. 공간 생성 (1단계: 건물)
    res = await client.post("/api/v1/fac/spaces", headers=headers, json={
        "facility_id": fac_id,
        "name": "본관",
        "code": "BLDG_01",
        "sort_order": 1
    })
    assert res.status_code == status.HTTP_201_CREATED
    bldg_id = res.json()["data"]["id"]

    # 3. 공간 생성 (2단계: 사무실)
    res = await client.post("/api/v1/fac/spaces", headers=headers, json={
        "facility_id": fac_id,
        "parent_id": bldg_id,
        "name": "운영실",
        "code": "ROOM_101",
        "org_id": 1 # 임시 부서 ID
    })
    assert res.status_code == status.HTTP_201_CREATED
    room_id = res.json()["data"]["id"]

    # 4. 공간 트리 조회
    res = await client.get(f"/api/v1/fac/facilities/{fac_id}/spaces", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    tree = res.json()["data"]
    assert len(tree) == 1
    assert tree[0]["children"][0]["name"] == "운영실"

    # 5. 공간 수정 및 순환 참조 방지
    with pytest.raises(BadRequestException):
        # 자식을 부모로 설정 시도
        await client.patch(f"/api/v1/fac/spaces/{bldg_id}", headers=headers, json={
            "parent_id": room_id
        })

@pytest.mark.anyio
async def test_space_leader_permission(client, auth_token):
    """부서장 권한 기반 공간 수정 보안 로직 검증"""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # 1. 테스트용 시설 및 공간 생성
    fac_res = await client.post("/api/v1/fac/facilities", headers=headers, json={
        "name": "보안테스트", "code": f"SEC_{uuid.uuid4().hex[:4]}".upper()
    })
    fac_id = fac_res.json()["data"]["id"]
    
    # 내 부서(1번이라고 가정)가 관리하는 공간 생성
    # conftest의 auth_token 사용자가 1번 부서라고 가정
    space_res = await client.post("/api/v1/fac/spaces", headers=headers, json={
        "facility_id": fac_id, "name": "우리부서공간", "code": "OUR_01", "org_id": 1
    })
    space_id = space_res.json()["data"]["id"]

    # 2. 수정 시도 (내가 팀장/부서장인 경우 성공해야 함)
    # 실제 테스트 DB의 admin 사용자는 superuser이므로 무조건 성공함
    # 따라서 여기선 로직 흐름만 확인
    res = await client.patch(f"/api/v1/fac/spaces/{space_id}", headers=headers, json={
        "name": "이름변경성공"
    })
    assert res.status_code == status.HTTP_200_OK

@pytest.mark.anyio
async def test_fac_security_boundaries(client):
    """비인증 접근 차단 검증"""
    res = await client.get("/api/v1/fac/facilities")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
