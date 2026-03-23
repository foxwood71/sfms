"""시설 및 공간 관리(FAC) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 공통 코드와 연동된 시설 분류, 공간 계층 구조를 관리하며
분류 코드 기반의 관리 코드 자동 생성 로직을 포함합니다.
"""

from __future__ import annotations

import uuid
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
...

from app.core.codes import ErrorCode
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.domains.fac.models import Facility, FacilityCategory, Space, SpaceFunction, SpaceType
from app.domains.fac.schemas import (
    FacilityCategoryRead,
    FacilityCreate,
    FacilityRead,
    FacilityUpdate,
    SpaceCreate,
    SpaceFunctionRead,
    SpaceRead,
    SpaceTypeRead,
    SpaceUpdate,
)
from app.domains.usr.models import User

from . import DOMAIN


class FacilityService:
    """최상위 시설(사업소/처리장 등) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def list_categories(db: AsyncSession) -> list[FacilityCategoryRead]:
        """등록된 모든 시설 카테고리(뷰) 목록을 조회합니다."""
        stmt = select(FacilityCategory).order_by(FacilityCategory.sort_order.asc())
        result = await db.execute(stmt)
        return [FacilityCategoryRead.model_validate(c) for c in result.scalars().all()]

    @staticmethod
    async def list_facilities(db: AsyncSession) -> list[FacilityRead]:
        """시스템에 등록된 모든 최상위 시설 목록을 조회합니다."""
        stmt = select(Facility).order_by(Facility.sort_order.asc(), Facility.name.asc())
        result = await db.execute(stmt)
        facilities = result.scalars().all()
        return [FacilityRead.model_validate(f) for f in facilities]

    @staticmethod
    async def get_facility_read(db: AsyncSession, facility_id: int) -> FacilityRead:
        """특정 시설 정보를 상세 조회합니다."""
        facility = await db.get(Facility, facility_id)
        if not facility:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return FacilityRead.model_validate(facility)

    @staticmethod
    async def create_facility(
        db: AsyncSession, obj_in: FacilityCreate, actor_id: int
    ) -> FacilityRead:
        """새로운 최상위 시설을 등록합니다. (코드 자동 생성 로직 포함)"""
        
        # 1. 관리 코드 자동 생성 (분류3자 + 순번3자리)
        # 예: STP -> STP001, STP002 ...
        prefix = obj_in.category_code.upper()
        stmt = select(func.count(Facility.id)).where(Facility.category_code == prefix)
        result = await db.execute(stmt)
        count = result.scalar() or 0
        new_code = f"{prefix}{str(count + 1).zfill(3)}"
        
        # 중복 체크 (수동 입력 대비)
        existing = await db.execute(select(Facility).where(Facility.code == new_code))
        if existing.scalar_one_or_none():
            # 만약 중복된다면 유니크한 코드가 나올 때까지 시도하거나 에러 발생
            new_code = f"{prefix}{uuid.uuid4().hex[:5].upper()}"

        create_data = obj_in.model_dump()
        create_data["code"] = new_code
        
        db_obj = Facility(**create_data, created_by=actor_id, updated_by=actor_id)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return FacilityRead.model_validate(db_obj)

    @staticmethod
    async def update_facility(
        db: AsyncSession, facility_id: int, obj_in: FacilityUpdate, actor_id: int
    ) -> FacilityRead:
        """기존 시설 정보를 수정합니다."""
        facility = await db.get(Facility, facility_id)
        if not facility:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
            
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(facility, field, value)

        facility.updated_by = actor_id
        await db.commit()
        await db.refresh(facility)
        return FacilityRead.model_validate(facility)

    @staticmethod
    async def delete_facility(db: AsyncSession, facility_id: int) -> None:
        """시설을 삭제합니다. 하위 공간이 있는 경우 삭제 불가."""
        facility = await db.get(Facility, facility_id)
        if not facility:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        stmt = select(Space).where(Space.facility_id == facility_id)
        result = await db.execute(stmt)
        if result.scalars().first():
            raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.HAS_CHILD_DATA)

        await db.delete(facility)
        await db.commit()


class SpaceService:
    """시설 내부의 공간 계층 구조를 관리하는 서비스 클래스입니다."""

    @staticmethod
    async def list_space_types(db: AsyncSession) -> list[SpaceTypeRead]:
        """공간 물리적 유형 목록(뷰)을 조회합니다."""
        stmt = select(SpaceType).order_by(SpaceType.sort_order.asc())
        result = await db.execute(stmt)
        return [SpaceTypeRead.model_validate(t) for t in result.scalars().all()]

    @staticmethod
    async def list_space_functions(db: AsyncSession) -> list[SpaceFunctionRead]:
        """공간 기능적 용도 목록(뷰)을 조회합니다."""
        stmt = select(SpaceFunction).order_by(SpaceFunction.sort_order.asc())
        result = await db.execute(stmt)
        return [SpaceFunctionRead.model_validate(f) for f in result.scalars().all()]

    @staticmethod
    async def get_space_tree(db: AsyncSession, facility_id: int) -> list[SpaceRead]:
        """특정 시설의 공간을 트리 구조로 조회합니다."""
        stmt = select(Space).where(Space.facility_id == facility_id).order_by(Space.sort_order.asc())
        result = await db.execute(stmt)
        spaces = result.scalars().all()

        space_reads = []
        for s in spaces:
            data = {c.name: getattr(s, c.name) for c in s.__table__.columns}
            space_reads.append(SpaceRead.model_validate(data))

        space_dict = {s.id: s for s in space_reads}
        tree = []
        for s in space_reads:
            if s.parent_id and s.parent_id in space_dict:
                parent = space_dict[s.parent_id]
                if parent.children is None: parent.children = []
                parent.children.append(s)
            else:
                tree.append(s)
        return tree

    @staticmethod
    async def create_space(
        db: AsyncSession, obj_in: SpaceCreate, actor_id: int
    ) -> SpaceRead:
        """새로운 공간을 생성합니다. (코드 자동 생성 로직 포함)"""
        
        # 1. 공간 코드 자동 생성 (유형3자 + 순번3자리)
        prefix = obj_in.space_type_code.upper()
        stmt = select(func.count(Space.id)).where(
            Space.facility_id == obj_in.facility_id,
            Space.space_type_code == prefix
        )
        result = await db.execute(stmt)
        count = result.scalar() or 0
        new_code = f"{prefix}{str(count + 1).zfill(3)}"

        create_data = obj_in.model_dump()
        create_data["code"] = new_code
        
        db_obj = Space(**create_data, created_by=actor_id, updated_by=actor_id)
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        
        data = {c.name: getattr(db_obj, c.name) for c in db_obj.__table__.columns}
        return SpaceRead.model_validate(data)

    @staticmethod
    async def update_space(
        db: AsyncSession, space_id: int, obj_in: SpaceUpdate, actor: User
    ) -> SpaceRead:
        """공간 정보를 수정합니다."""
        space = await db.get(Space, space_id)
        if not space:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        # 권한 확인 등 기존 로직 유지...
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(space, field, value)

        space.updated_by = actor.id
        await db.commit()
        await db.refresh(space)
        
        data = {c.name: getattr(space, c.name) for c in space.__table__.columns}
        return SpaceRead.model_validate(data)

    @staticmethod
    async def delete_space(db: AsyncSession, space_id: int) -> None:
        """공간을 삭제합니다."""
        space = await db.get(Space, space_id)
        if not space:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        stmt = select(Space).where(Space.parent_id == space_id)
        result = await db.execute(stmt)
        if result.scalars().first():
            raise BadRequestException(domain=DOMAIN, error_code=ErrorCode.HAS_CHILD_DATA)

        await db.delete(space)
        await db.commit()
