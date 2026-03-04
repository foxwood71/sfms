"""사용자(User) 및 조직(Organization) 도메인의 비즈니스 로직(Service)을 담당하는 모듈입니다."""

from typing import Any, Dict, List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.domains.usr.models import Organization, User
from app.domains.usr.schemas import OrgCreate, OrgUpdate, UserCreate, UserUpdate

# TODO: app.core.security 모듈에 get_password_hash 함수 구현 필요
# from app.core.security import get_password_hash


class OrgService:
    """조직(Organization) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def get_org_tree(db: AsyncSession) -> List[Dict[str, Any]]:
        """
        활성화된 전체 조직을 조회하여 트리 구조(계층형 JSON)로 조립하여 반환합니다.

        DB의 재귀 쿼리 대신, 전체를 한 번에 조회한 후 메모리에서 조립하여 성능을 최적화합니다.
        """
        stmt = (
            select(Organization)
            .where(Organization.is_active == True)
            .order_by(Organization.sort_order)
        )  # noqa: E712
        result = await db.execute(stmt)
        orgs = result.scalars().all()

        # 인메모리 트리 조립 로직
        org_dict = {org.id: org.__dict__.copy() for org in orgs}
        for org in org_dict.values():
            org["children"] = []  # 자식 노드 초기화

        tree = []
        for org in org_dict.values():
            parent_id = org.get("parent_id")
            if parent_id and parent_id in org_dict:
                org_dict[parent_id]["children"].append(org)
            else:
                tree.append(org)  # 최상위(Root) 노드

        return tree

    @staticmethod
    async def create_org(db: AsyncSession, obj_in: OrgCreate) -> Organization:
        """새로운 조직을 생성합니다. 코드 중복 및 상위 부서 유효성을 검증합니다."""
        # 1. 코드 중복 검증
        stmt = select(Organization).where(Organization.code == obj_in.code)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise ConflictException(
                error_code=4090, message="이미 존재하는 조직 코드입니다."
            )

        # 2. 상위 부서 유효성 검증
        if obj_in.parent_id:
            parent = await db.get(Organization, obj_in.parent_id)
            if not parent:
                raise BadRequestException(
                    error_code=4003, message="유효하지 않은 상위 부서 ID입니다."
                )

        db_obj = Organization(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()  # DB에 반영하여 ID 확보
        return db_obj

    @staticmethod
    async def update_org(
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
                raise BadRequestException(
                    error_code=4003,
                    message="자기 자신을 상위 부서로 지정할 수 없습니다.",
                )

            # DFS/BFS 탐색으로 대상 부모가 나의 자손인지 확인
            current_parent = await db.get(Organization, new_parent_id)
            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == org.id:
                    raise BadRequestException(
                        error_code=4005,
                        message="하위 부서를 상위 부서로 지정할 수 없습니다 (순환 참조).",
                    )
                current_parent = await db.get(Organization, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(org, field, value)

        return org

    @staticmethod
    async def delete_org(db: AsyncSession, org_id: int) -> None:
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

        # 임시 비밀번호 해싱 처리 (get_password_hash는 외부 구현 필요)
        # create_data["password_hash"] = get_password_hash(obj_in.password)
        create_data["password_hash"] = (
            f"hashed_{obj_in.password}"  # TODO: 실제 해시 함수로 교체 필요
        )

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
        current_meta["retired_at"] = "2026-03-04"  # TODO: 현재 시간 동적 매핑 필요
        user.user_metadata = current_meta
