"""시설 및 공간 관리(FAC) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 시설 카테고리 관리, 최상위 시설(Site) 관리,
그리고 시설 내부의 계층적 공간(Space) 관리를 담당합니다.
"""

from __future__ import annotations

from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.domains.fac.models import Facility, Space
from app.domains.fac.schemas import (
    FacilityCreate,
    FacilityRead,
    FacilityUpdate,
    SpaceCreate,
    SpaceRead,
    SpaceUpdate,
)
from app.domains.usr.models import User

from . import DOMAIN


class FacilityService:
    """최상위 시설(사업소/처리장 등) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.
    
    시설의 기본 정보 관리 및 시스템 전반의 물리적 거점을 정의합니다.
    """

    @staticmethod
    async def list_facilities(db: AsyncSession) -> list[FacilityRead]:
        """시스템에 등록된 모든 최상위 시설 목록을 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션

        Returns:
            list[FacilityRead]: 정렬 순서 및 명칭순으로 정렬된 시설 정보 리스트
        """
        stmt = select(Facility).order_by(Facility.sort_order.asc(), Facility.name.asc())
        result = await db.execute(stmt)
        facilities = result.scalars().all()
        return [FacilityRead.model_validate(f) for f in facilities]

    @staticmethod
    async def get_facility(db: AsyncSession, facility_id: int) -> Facility:
        """특정 시설 정보를 ID로 조회합니다. (내부 로직용 모델 반환)

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            facility_id (int): 조회할 시설의 고유 ID

        Returns:
            Facility: SQLAlchemy 모델 객체

        Raises:
            NotFoundException: 해당 ID의 시설이 존재하지 않을 때 발생
        """
        facility = await db.get(Facility, facility_id)
        if not facility:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return facility

    @staticmethod
    async def get_facility_read(db: AsyncSession, facility_id: int) -> FacilityRead:
        """특정 시설 정보를 상세 조회하여 스키마 형태로 반환합니다. (API 응답용)

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            facility_id (int): 조회할 시설의 고유 ID

        Returns:
            FacilityRead: 조회된 시설 정보 스키마
        """
        facility = await FacilityService.get_facility(db, facility_id)
        return FacilityRead.model_validate(facility)

    @staticmethod
    async def create_facility(db: AsyncSession, obj_in: FacilityCreate, actor_id: int) -> FacilityRead:
        """새로운 최상위 시설을 등록합니다. 시설 코드는 자동으로 대문자로 변환됩니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (FacilityCreate): 신규 시설 등록 정보
            actor_id (int): 등록 행위를 수행한 사용자 ID

        Returns:
            FacilityRead: 생성 완료된 시설 정보 스키마

        Raises:
            ConflictException: 이미 동일한 시설 코드가 존재할 때 발생
        """
        existing = await db.execute(select(Facility).where(Facility.code == obj_in.code.upper()))
        if existing.scalar_one_or_none():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.DUPLICATE_CODE)

        create_data = obj_in.model_dump()
        create_data["code"] = create_data["code"].upper()
        db_obj = Facility(**create_data, created_by=actor_id, updated_by=actor_id)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return FacilityRead.model_validate(db_obj)

    @staticmethod
    async def update_facility(db: AsyncSession, facility_id: int, obj_in: FacilityUpdate, actor_id: int) -> FacilityRead:
        """기존 시설 정보를 수정합니다. (주로 관리자 권한으로 수행)

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            facility_id (int): 수정할 대상 시설 ID
            obj_in (FacilityUpdate): 업데이트할 필드 정보
            actor_id (int): 수정 행위를 수행한 사용자 ID

        Returns:
            FacilityRead: 수정 완료된 시설 정보 스키마
        """
        facility = await FacilityService.get_facility(db, facility_id)
        update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(facility, field, value)

        facility.updated_by = actor_id
        await db.commit()
        await db.refresh(facility)
        return FacilityRead.model_validate(facility)


class SpaceService:
    """시설 내부의 공간(건물, 층, 호실 등) 계층 구조를 관리하는 서비스 클래스입니다.
    
    트리 구조 조립, 부서별 공간 편집 권한 검증 및 순환 참조 방지 로직을 처리합니다.
    """

    @staticmethod
    async def get_space_tree(db: AsyncSession, facility_id: int) -> list[SpaceRead]:
        """특정 시설에 소속된 모든 공간을 계층적 트리 구조로 조회합니다.

        비동기 지연 로딩 문제를 피하기 위해 모든 공간을 일괄 조회한 후 
        메모리 상에서 트리 구조를 조립합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            facility_id (int): 기준이 되는 시설 ID

        Returns:
            list[SpaceRead]: 최상위 노드들부터 시작하여 하위 children이 포함된 트리 리스트
        """
        stmt = (
            select(Space)
            .where(Space.facility_id == facility_id, Space.is_active)
            .order_by(Space.sort_order.asc())
        )
        result = await db.execute(stmt)
        spaces = result.scalars().all()

        # 지연 로딩 방지: 모델 데이터를 딕셔너리로 추출 후 스키마 생성
        space_reads = []
        for s in spaces:
            data = {c.name: getattr(s, c.name) for c in s.__table__.columns}
            space_reads.append(SpaceRead.model_validate(data))

        # 트리 조립 로직 (스키마 객체 간 관계 설정)
        space_dict = {s.id: s for s in space_reads}
        tree = []
        for s in space_reads:
            if s.parent_id and s.parent_id in space_dict:
                parent = space_dict[s.parent_id]
                if parent.children is None:
                    parent.children = []
                parent.children.append(s)
            else:
                tree.append(s)
        return tree

    @staticmethod
    async def create_space(db: AsyncSession, obj_in: SpaceCreate, actor_id: int) -> SpaceRead:
        """시설 내부에 새로운 공간(노드)을 생성합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (SpaceCreate): 공간 생성 정보 (시설 ID, 부모 ID, 명칭 등)
            actor_id (int): 생성 행위 수행자 ID

        Returns:
            SpaceRead: 생성 완료된 공간 정보 스키마

        Raises:
            ConflictException: 시설 내에서 중복된 공간 코드가 사용될 때 발생
        """
        existing = await db.execute(
            select(Space).where(Space.facility_id == obj_in.facility_id, Space.code == obj_in.code.upper())
        )
        if existing.scalar_one_or_none():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.DUPLICATE_CODE)

        create_data = obj_in.model_dump()
        create_data["code"] = create_data["code"].upper()
        db_obj = Space(**create_data, created_by=actor_id, updated_by=actor_id)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        
        # 지연 로딩 방지
        data = {c.name: getattr(db_obj, c.name) for c in db_obj.__table__.columns}
        return SpaceRead.model_validate(data)

    @staticmethod
    async def update_space(
        db: AsyncSession,
        space_id: int,
        obj_in: SpaceUpdate,
        actor: User,
    ) -> SpaceRead:
        """공간 정보를 수정합니다. 권한 및 순환 참조 여부를 검증합니다.

        권한 정책:
        1. 시스템 관리자(Superuser)는 모든 공간을 수정할 수 있습니다.
        2. 일반 사용자의 경우, 해당 공간의 관리 부서(`org_id`)와 본인의 부서가 일치하고,
           메타데이터상 직책이 '팀장' 또는 '부서장'급일 때만 수정이 허용됩니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            space_id (int): 수정할 대상 공간 ID
            obj_in (SpaceUpdate): 업데이트할 필드 정보
            actor (User): 수정을 시도하는 사용자 모델 객체 (권한 확인용)

        Returns:
            SpaceRead: 수정 완료된 공간 정보 스키마

        Raises:
            NotFoundException: 대상 공간이 존재하지 않을 때 발생
            BadRequestException: 권한이 없거나 순환 참조가 발생할 때 발생
        """
        space = await db.get(Space, space_id)
        if not space:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        # 권한 확인 로직 (관리자 또는 해당 부서장)
        is_admin = actor.is_superuser
        user_metadata = actor.user_metadata or {}
        duty = user_metadata.get("duty", "")
        position = user_metadata.get("position", "")
        is_leader = any(kw in [duty, position] for kw in ["부서장", "팀장", "MANAGER", "LEADER"])

        can_edit = is_admin or (space.org_id == actor.org_id and is_leader)

        if not can_edit:
            raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED)

        update_data = obj_in.model_dump(exclude_unset=True)

        # 순환 참조 방지 로직 (부모 방향으로 올라가며 체크)
        new_parent_id = update_data.get("parent_id")
        if new_parent_id is not None and new_parent_id != space.parent_id:
            if new_parent_id == space.id:
                raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.INVALID_PARENT_ORG)

            current_parent = await db.get(Space, new_parent_id)
            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == space.id:
                    raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.CIRCULAR_REFERENCE)
                current_parent = await db.get(Space, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(space, field, value)

        space.updated_by = actor.id
        await db.commit()
        await db.refresh(space)
        
        # 지연 로딩 방지
        data = {c.name: getattr(space, c.name) for c in space.__table__.columns}
        return SpaceRead.model_validate(data)
