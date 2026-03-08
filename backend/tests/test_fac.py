"""시설 및 공간(FAC) 도메인의 API 기능을 검증하는 테스트 모듈입니다.

사업소(시설) 등록부터 건물 및 실단위 공간의 계층 구조 트리 조회,
그리고 순환 참조 방지 보안 로직을 검증합니다.
"""

import uuid

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_facility_and_space_full_cycle(client, auth_token):
    """시설 생성부터 공간 트리 조회까지의 전체 사이클을 검증합니다.

    부서 생성, 시설 등록, 계층적 공간(건물->사무실) 등록 및
    최종 트리 구조 조립이 올바르게 이루어지는지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    fac_code = f"SITE_{uuid.uuid4().hex[:4]}".upper()

    # 0. 부서 생성 (공간에서 참조하기 위함)
    org_res = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": "관리부서", "code": f"ORG_{uuid.uuid4().hex[:4]}".upper()},
    )
    org_id = org_res.json()["data"]["id"]

    # 1. 시설 생성 (관리자)
    res = await client.post(
        "/api/v1/fac/facilities",
        headers=headers,
        json={
            "name": "테스트 사업소",
            "code": fac_code,
            "sort_order": 1,
            "metadata_info": {"type": "WATER"},
        },
    )
    assert res.status_code == status.HTTP_201_CREATED
    fac_id = res.json()["data"]["id"]

    # 2. 공간 생성 (1단계: 건물)
    res = await client.post(
        "/api/v1/fac/spaces",
        headers=headers,
        json={
            "facility_id": fac_id,
            "name": "본관",
            "code": "BLDG_01",
            "sort_order": 1,
        },
    )
    assert res.status_code == status.HTTP_201_CREATED
    bldg_id = res.json()["data"]["id"]

    # 3. 공간 생성 (2단계: 사무실)
    res = await client.post(
        "/api/v1/fac/spaces",
        headers=headers,
        json={
            "facility_id": fac_id,
            "parent_id": bldg_id,
            "name": "운영실",
            "code": "ROOM_101",
            "org_id": org_id,
        },
    )
    assert res.status_code == status.HTTP_201_CREATED
    room_id = res.json()["data"]["id"]

    # 4. 공간 트리 조회
    res = await client.get(f"/api/v1/fac/facilities/{fac_id}/spaces", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    tree = res.json()["data"]
    assert len(tree) == 1
    assert tree[0]["children"][0]["name"] == "운영실"

    # 5. 공간 수정 및 순환 참조 방지 테스트
    # 자식을 부모로 설정하려 할 때 400 에러가 발생해야 함
    res = await client.patch(
        f"/api/v1/fac/spaces/{bldg_id}", headers=headers, json={"parent_id": room_id}
    )
    assert res.status_code == status.HTTP_400_BAD_REQUEST


@pytest.mark.anyio
async def test_space_leader_permission(client, auth_token):
    """부서장 권한 기반의 공간 정보 수정 권한을 검증합니다.

    자신이 관리 책임자로 있는 공간에 대해 수정 권한이 있는지 확인합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 0. 부서 생성
    org_res = await client.post(
        "/api/v1/usr/organizations",
        headers=headers,
        json={"name": "보안부서", "code": f"ORG_{uuid.uuid4().hex[:4]}".upper()},
    )
    org_id = org_res.json()["data"]["id"]

    # 1. 테스트용 시설 및 공간 생성
    fac_res = await client.post(
        "/api/v1/fac/facilities",
        headers=headers,
        json={"name": "보안테스트", "code": f"SEC_{uuid.uuid4().hex[:4]}".upper()},
    )
    fac_id = fac_res.json()["data"]["id"]

    space_res = await client.post(
        "/api/v1/fac/spaces",
        headers=headers,
        json={
            "facility_id": fac_id,
            "name": "우리부서공간",
            "code": "OUR_01",
            "org_id": org_id,
        },
    )
    space_id = space_res.json()["data"]["id"]

    # 2. 수정 시도
    res = await client.patch(
        f"/api/v1/fac/spaces/{space_id}", headers=headers, json={"name": "이름변경성공"}
    )
    assert res.status_code == status.HTTP_200_OK


@pytest.mark.anyio
async def test_fac_security_boundaries(client):
    """인증되지 않은 사용자의 시설 정보 접근 차단을 검증합니다."""
    res = await client.get("/api/v1/fac/facilities")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
