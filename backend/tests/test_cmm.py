"""공통 관리(CMM) 도메인의 API 기능을 검증하는 테스트 모듈입니다.

공통 코드(그룹/상세)의 CRUD와 알림(Notification) 시스템의
조회 및 읽음 처리 로직을 검증합니다.
"""

import pytest
from fastapi import status


@pytest.mark.anyio
async def test_code_group_crud(client, auth_token):
    """공통 코드 그룹의 생성, 조회, 수정, 삭제 사이클을 검증합니다.

    동일한 코드의 중복 생성 방지 로직과 정상적인 데이터 갱신 여부를 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    group_code = "TEST_GRP"

    # 0. 기존 데이터가 있다면 삭제 (정리)
    await client.delete(f"/api/v1/cmm/codes/{group_code}", headers=headers)

    # 1. 생성
    res = await client.post(
        "/api/v1/cmm/codes",
        headers=headers,
        json={
            "group_name": "테스트그룹",
            "group_code": group_code,
            "description": "설명",
        },
    )
    assert res.status_code == status.HTTP_201_CREATED

    # 2. 중복 생성 시도 -> 409 Conflict 반환 확인
    res = await client.post(
        "/api/v1/cmm/codes",
        headers=headers,
        json={"group_name": "중복", "group_code": group_code},
    )
    assert res.status_code == status.HTTP_409_CONFLICT

    # 3. 조회
    res = await client.get(f"/api/v1/cmm/codes/{group_code}", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    assert res.json()["data"]["group_name"] == "테스트그룹"

    # 4. 수정
    res = await client.patch(
        f"/api/v1/cmm/codes/{group_code}",
        headers=headers,
        json={"group_name": "수정그룹"},
    )
    assert res.status_code == status.HTTP_200_OK

    # 5. 삭제 (최종 정리)
    await client.delete(f"/api/v1/cmm/codes/{group_code}", headers=headers)


@pytest.mark.anyio
async def test_code_item_crud(client, auth_token):
    """특정 그룹에 속한 상세 코드(Item)의 생성 및 조회를 검증합니다.

    그룹 코드와 상세 코드가 올바르게 연결되어 저장되는지 테스트합니다.
    """
    headers = {"Authorization": f"Bearer {auth_token}"}
    group_code = "ITEM_GRP"
    detail_code = "T001"

    # 0. 정리
    await client.delete(f"/api/v1/cmm/codes/{group_code}", headers=headers)
    await client.post(
        "/api/v1/cmm/codes",
        headers=headers,
        json={"group_name": "아이템그룹", "group_code": group_code},
    )

    # 1. 아이템 생성
    res = await client.post(
        f"/api/v1/cmm/codes/{group_code}/details",
        headers=headers,
        json={"detail_name": "테스트코드", "detail_code": detail_code, "sort_order": 1},
    )
    assert res.status_code == status.HTTP_201_CREATED

    # 2. 상세 조회 (그룹 조회 결과 포함 확인)
    res = await client.get(f"/api/v1/cmm/codes/{group_code}", headers=headers)
    assert res.status_code == status.HTTP_200_OK
    details = res.json()["data"]["details"]
    assert any(d["detail_code"] == detail_code for d in details)

    # 3. 존재하지 않는 그룹 조회 -> 404 Not Found 확인
    res = await client.get("/api/v1/cmm/codes/NONE_GRP", headers=headers)
    assert res.status_code == status.HTTP_404_NOT_FOUND

    # 4. 정리
    await client.delete(f"/api/v1/cmm/codes/{group_code}", headers=headers)


@pytest.mark.anyio
async def test_notification_flow(client, auth_token):
    """사용자 알림 목록 조회 및 읽음 처리 흐름을 검증합니다."""
    headers = {"Authorization": f"Bearer {auth_token}"}

    # 1. 알림 목록 조회
    res = await client.get("/api/v1/cmm/notifications", headers=headers)
    assert res.status_code == status.HTTP_200_OK

    # 2. 존재하지 않는 알림 읽음 처리 시도 -> 404 Not Found 확인
    res = await client.patch("/api/v1/cmm/notifications/999999/read", headers=headers)
    assert res.status_code == status.HTTP_404_NOT_FOUND


@pytest.mark.anyio
async def test_cmm_security_boundaries(client):
    """인증되지 않은 사용자의 공통 코드 접근 차단을 검증합니다."""
    res = await client.get("/api/v1/cmm/codes")
    assert res.status_code == status.HTTP_401_UNAUTHORIZED
