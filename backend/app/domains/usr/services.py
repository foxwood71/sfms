"""사용자(User) 및 조직(Organization) 도메인의 비즈니스 로직(Service)을 담당하는 모듈입니다."""

from datetime import datetime
from typing import Any, Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from app.core.constants import ErrorCode
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    CustomException,
    NotFoundException,
)
from app.core.security import get_password_hash
from app.domains.usr.models import Organization, User
from app.domains.usr.schemas import OrgCreate, OrgUpdate, UserCreate, UserUpdate


class OrgService:
    """조직(Organization) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def get_organizations(
        db: AsyncSession, mode: str = "tree", is_active: str = "true"
    ) -> List[Any]:
        """명세서 2.1: 조직 목록 조회 (Flat vs Tree)"""
        stmt = select(Organization)
        if is_active == "true":
            stmt = stmt.where(Organization.is_active == True)

        stmt = stmt.order_by(Organization.sort_order.asc())
        result = await db.execute(stmt)
        orgs = list(result.scalars().all())

        if mode == "flat":
            return orgs

        # Tree 구조 조립 로직 (메모리 재귀)
        org_dict = {org.id: {**org.__dict__, "children": []} for org in orgs}
        tree = []
        for org_id, org_data in org_dict.items():
            parent_id = org_data.get("parent_id")
            if parent_id and parent_id in org_dict:
                org_dict[parent_id]["children"].append(org_data)
            else:
                tree.append(org_data)
        return tree

    # 별명 붙이기 (함수 객체를 다른 이름에 할당)
    get_org_tree = get_organizations

    @staticmethod
    async def create_organizations(db: AsyncSession, obj_in: OrgCreate) -> Organization:
        """새로운 조직을 생성합니다. 코드 중복 및 상위 부서 유효성을 검증합니다."""
        # 1. 코드 중복 검증
        stmt = select(Organization).where(Organization.code == obj_in.code)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise CustomException(
                error_code=ErrorCode.DUPLICATE_ORG_CODE,
                message="이미 존재하는 조직 코드입니다.",
            )

        # 2. 상위 부서 유효성 검증
        if obj_in.parent_id:
            parent = await db.get(Organization, obj_in.parent_id)
            if not parent:
                raise CustomException(
                    error_code=ErrorCode.INVALID_PARENT_ORG,
                    message="유효하지 않은 상위 부서 ID입니다.",
                )

        db_obj = Organization(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()  # DB에 반영하여 ID 확보
        return db_obj

    @staticmethod
    async def update_organizations(
        db: AsyncSession, org_id: int, obj_in: OrgUpdate
    ) -> Organization:
        """조직 정보를 수정합니다. 순환 참조를 방지하는 방어 로직이 포함되어 있습니다."""
        org = await db.get(Organization, org_id)
        if not org:
            raise NotFoundException(message="해당 조직을 찾을 수 없습니다.")

        update_data = obj_in.model_dump(exclude_unset=True)

        # 상위 부서(parent_id) 변경 시 순환 참조(Circular Reference) 방지 로직
        new_parent_id = update_data.get("parent_id")
        if new_parent_id is not None and new_parent_id != org.parent_id:
            if new_parent_id == org.id:
                raise CustomException(
                    error_code=ErrorCode.INVALID_PARENT_ORG,
                    message="자기 자신을 상위 부서로 지정할 수 없습니다.",
                )

            # DFS/BFS 탐색으로 대상 부모가 나의 자손인지 확인
            current_parent = await db.get(Organization, new_parent_id)
            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == org.id:
                    raise CustomException(
                        error_code=ErrorCode.CIRCULAR_REFERENCE,
                        message="하위 부서를 상위 부서로 지정할 수 없습니다 (순환 참조).",
                    )
                current_parent = await db.get(Organization, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(org, field, value)

        return org

    @staticmethod
    async def delete_organizations(db: AsyncSession, org_id: int) -> None:
        """
        조직을 삭제합니다. 하위 부서나 소속된 사용자가 있으면 삭제를 차단합니다.
        """
        org = await db.get(Organization, org_id)
        if not org:
            raise NotFoundException(message="해당 조직을 찾을 수 없습니다.")

        # 1. 하위 부서 존재 여부 체크
        child_stmt = select(Organization).where(Organization.parent_id == org_id)
        child_result = await db.execute(child_stmt)
        if child_result.scalars().first():
            raise ConflictException(
                error_code=4091, message="하위 부서가 존재하여 삭제할 수 없습니다."
            )

        # 2. 부서원 존재 여부 체크
        user_stmt = select(User).where(User.org_id == org_id)
        user_result = await db.execute(user_stmt)
        if user_result.scalars().first():
            raise ConflictException(
                error_code=4095, message="소속된 사용자가 존재하여 삭제할 수 없습니다."
            )

        await db.delete(org)


class UserService:
    """사용자(User) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def create_user(db: AsyncSession, obj_in: UserCreate) -> User:
        """
        신규 사용자를 생성합니다. ID, 이메일, 사번 중복을 각각 검증합니다.
        """
        # 중복 검증 로직 모음
        checks = [
            (User.login_id == obj_in.login_id, 4090, "이미 사용 중인 로그인 ID입니다."),
            (User.email == obj_in.email, 4093, "이미 등록된 이메일 주소입니다."),
            (User.emp_code == obj_in.emp_code, 4094, "이미 등록된 사원 번호입니다."),
        ]

        for condition, code, msg in checks:
            stmt = select(User).where(condition)
            result = await db.execute(stmt)
            if result.scalar_one_or_none():
                raise ConflictException(error_code=code, message=msg)

        create_data = obj_in.model_dump(exclude={"password"})

        create_data["password_hash"] = get_password_hash(obj_in.password)

        db_obj = User(**create_data)
        db.add(db_obj)
        await db.flush()
        return db_obj

    @staticmethod
    async def delete_user(db: AsyncSession, user_id: int) -> None:
        """
        사용자를 논리적 삭제(Soft Delete) 처리합니다.
        물리적 삭제 대신 is_active 상태를 False로 변경합니다.
        """
        user = await db.get(User, user_id)
        if not user:
            raise NotFoundException(message="해당 사용자를 찾을 수 없습니다.")

        user.is_active = False
        # 퇴사 일자를 metadata에 기록
        current_meta = user.user_metadata or {}
        current_meta["retired_at"] = datetime.now().strftime("%Y-%m-%d")
        # 만약 상세 시간까지 필요하다면 아래 방식을 추천드려요 (ISO 포맷)
        # current_meta["retired_at"] = datetime.now().isoformat()  # 2026-03-05T22:44:16... 형태
        user.user_metadata = current_meta

    @staticmethod
    async def get_user(db: AsyncSession, user_id: int) -> User:
        """특정 사용자 정보를 상세 조회합니다."""
        user = await db.get(User, user_id)
        if not user:
            from app.core.exceptions import NotFoundException

            raise NotFoundException(message="해당 사용자를 찾을 수 없습니다.")
        return user

    @staticmethod
    async def get_my_info_with_org(db: AsyncSession, user_id: int):
        """
        사용자 상세 정보와 소속 조직 정보를 조인하여 조회합니다.

        명세서 2.3 요구사항에 따라 User 모델과 Organization 모델을 조인하며,  # 명세서 준수
        프론트엔드에서 org_name 등의 정보를 추가 호출 없이 즉시 사용할 수 있도록 합니다.

        Args:
            db (AsyncSession): 비동기 데이터베이스 세션 객체
            user_id (int): 조회하고자 하는 사용자의 고유 ID (PK)

        Returns:
            User: 조직(Organization) 정보가 포함된(Eager Loaded) 사용자 모델 객체

        Raises:
            NotFoundException: 해당 ID를 가진 사용자가 존재하지 않을 경우 발생
        """
        # 조직(Organization) 정보를 조인하여 한 번에 가져옴
        stmt = (
            select(User)
            .options(joinedload(User.organization))
            .where(User.id == user_id)
        )
        result = await db.execute(stmt)
        user = result.scalar_one_or_none()

        if not user:
            raise NotFoundException(message="사용자를 찾을 수 없습니다.")

        # 프론트엔드 요구사항에 맞춰 데이터 조립 가능
        return user

    @staticmethod
    async def get_user_by_login_id(db: AsyncSession, login_id: str) -> Optional[User]:
        """로그인 ID(문자열)를 기반으로 사용자를 조회합니다."""
        from sqlalchemy import select

        stmt = select(User).where(User.login_id == login_id)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def get_user_by_id(db: AsyncSession, user_id: int) -> Optional[User]:
        """
        사용자의 고유 ID(PK)를 기반으로 사용자 정보를 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            user_id (int): 조회할 사용자의 PK

        Returns:
            Optional[User]: 사용자 객체 또는 없으면 None
        """
        # SQLAlchemy 2.0에서는 db.get()이 가장 깔끔하고 빠릅니다.
        return await db.get(User, user_id)
