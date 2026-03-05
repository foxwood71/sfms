"""시설 및 공간 관리(FAC) 도메인의 비즈니스 로직(Service)을 담당하는 모듈입니다."""

from typing import Any, Dict, List

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.domains.fac.models import Facility, Space
from app.domains.fac.schemas import FacilityCreate, SpaceCreate, SpaceUpdate


class SpaceService:
    """공간(Space) 관련 비즈니스 로직 클래스입니다."""

    @staticmethod
    async def get_space_tree(db: AsyncSession) -> List[Dict[str, Any]]:
        """활성화된 전체 공간을 조회하여 트리 구조로 조립합니다."""
        stmt = select(Space).where(Space.is_active == True)  # noqa: E712
        result = await db.execute(stmt)
        spaces = result.scalars().all()

        space_dict = {space.id: space.__dict__.copy() for space in spaces}
        for space in space_dict.values():
            space["children"] = []

        tree = []
        for space in space_dict.values():
            parent_id = space.get("parent_id")
            if parent_id and parent_id in space_dict:
                space_dict[parent_id]["children"].append(space)
            else:
                tree.append(space)

        return tree

    @staticmethod
    async def create_space(db: AsyncSession, obj_in: SpaceCreate) -> Space:
        """새로운 공간을 생성합니다."""
        stmt = select(Space).where(Space.code == obj_in.code)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise ConflictException(
                error_code=4090, message="이미 존재하는 공간 코드입니다."
            )

        if obj_in.parent_id:
            parent = await db.get(Space, obj_in.parent_id)
            if not parent:
                raise NotFoundException(message="상위 공간을 찾을 수 없습니다.")

        db_obj = Space(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()
        return db_obj

    @staticmethod
    async def update_space(
        db: AsyncSession, space_id: int, obj_in: SpaceUpdate
    ) -> Space:
        """공간 정보를 수정하며 상위 공간 변경 시 순환 참조를 방지합니다."""
        space = await db.get(Space, space_id)
        if not space:
            raise NotFoundException(message="해당 공간을 찾을 수 없습니다.")

        update_data = obj_in.model_dump(exclude_unset=True)

        new_parent_id = update_data.get("parent_id")
        if new_parent_id is not None and new_parent_id != space.parent_id:
            if new_parent_id == space.id:
                raise BadRequestException(
                    error_code=4003,
                    message="자기 자신을 상위 공간으로 지정할 수 없습니다.",
                )

            current_parent = await db.get(Space, new_parent_id)
            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == space.id:
                    raise BadRequestException(
                        error_code=4005,
                        message="하위 공간을 상위 공간으로 지정할 수 없습니다.",
                    )
                current_parent = await db.get(Space, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(space, field, value)

        return space


class FacilityService:
    """설비(Facility) 관련 비즈니스 로직 클래스입니다."""

    @staticmethod
    async def create_facility(db: AsyncSession, obj_in: FacilityCreate) -> Facility:
        """새로운 설비를 등록합니다."""
        stmt = select(Facility).where(Facility.code == obj_in.code)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise ConflictException(
                error_code=4090, message="이미 존재하는 설비 코드입니다."
            )

        db_obj = Facility(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()
        return db_obj
