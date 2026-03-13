"""사용자(User) 및 조직(Organization) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 조직의 계층 구조 관리, 사용자 계정 생성 및 수정, 비밀번호 관리,
그리고 프로필 이미지 업로드 등의 핵심 인사/조직 업무 로직을 수행합니다.
"""

from __future__ import annotations

import uuid
from datetime import datetime

from fastapi import UploadFile
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
    ServiceUnavailableException,
)
from app.core.security import get_password_hash, verify_password
from app.core.storage import upload_file_stream

# cmm 도메인 의존성 (프로필 이미지 연동용)
from app.domains.cmm.schemas import AttachmentCreate
from app.domains.cmm.services import AttachmentService
from app.domains.usr.models import Organization, User
from app.domains.usr.schemas import (
    OrgCreate,
    OrgRead,
    OrgUpdate,
    UserCreate,
    UserPasswordUpdate,
    UserUpdate,
)

from . import DOMAIN


class OrganizationService:
    """조직(Organization) 및 부서 관리 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.

    부서 간 계층 구조(Tree)를 조립하고, 순환 참조 방지 및 하위 부서 일괄 조회 기능을 제공합니다.
    """

    @staticmethod
    async def get_descendant_org_ids(db: AsyncSession, org_id: int) -> list[int]:
        """특정 조직을 포함하여 모든 하위 조직의 ID 목록을 재귀적으로 조회합니다."""
        anchor_stmt = (
            select(Organization.id)
            .where(Organization.id == org_id)
            .cte(recursive=True, name="org_cte")
        )
        recursive_stmt = select(Organization.id).join(
            anchor_stmt, Organization.parent_id == anchor_stmt.c.id
        )
        org_cte = anchor_stmt.union_all(recursive_stmt)
        final_stmt = select(org_cte.c.id)
        result = await db.execute(final_stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_organizations(
        db: AsyncSession, mode: str = "tree", is_active: bool | None = None
    ) -> list[OrgRead]:
        """전체 조직 목록을 트리 또는 평면 리스트 구조로 조회합니다."""
        stmt = select(Organization)
        if is_active is not None:
            stmt = stmt.where(Organization.is_active == is_active)

        stmt = stmt.order_by(Organization.sort_order.asc())
        result = await db.execute(stmt)
        orgs = list(result.scalars().all())

        org_reads = []
        for org in orgs:
            data = {c.name: getattr(org, c.name) for c in org.__table__.columns}
            org_reads.append(OrgRead.model_validate(data))

        if mode == "flat":
            return org_reads

        org_dict = {org.id: org for org in org_reads}
        tree = []
        for org in org_reads:
            if org.parent_id and org.parent_id in org_dict:
                parent = org_dict[org.parent_id]
                if parent.children is None:
                    parent.children = []
                parent.children.append(org)
            else:
                tree.append(org)
        return tree

    @staticmethod
    async def create_organizations(
        db: AsyncSession, obj_in: OrgCreate, actor_id: int
    ) -> OrgRead:
        """새로운 조직(부서)을 등록합니다."""
        stmt = select(Organization).where(Organization.code == obj_in.code)
        result = await db.execute(stmt)
        if result.scalar_one_or_none():
            raise ConflictException(
                domain=DOMAIN, error_code=ErrorCode.DUPLICATE_ORG_CODE
            )

        if obj_in.parent_id:
            parent = await db.get(Organization, obj_in.parent_id)
            if not parent:
                raise ConflictException(
                    domain=DOMAIN, error_code=ErrorCode.USR_INVALID_PARENT
                )

        db_obj = Organization(
            **obj_in.model_dump(), created_by=actor_id, updated_by=actor_id
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)

        data = {c.name: getattr(db_obj, c.name) for c in db_obj.__table__.columns}
        return OrgRead.model_validate(data)

    @staticmethod
    async def get_organization(db: AsyncSession, org_id: int) -> Organization:
        """특정 조직 정보를 ID로 단건 조회합니다."""
        org = await db.get(Organization, org_id)
        if not org:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return org

    @staticmethod
    async def update_organizations(
        db: AsyncSession, org_id: int, obj_in: OrgUpdate, actor_id: int
    ) -> OrgRead:
        """기존 조직 정보를 수정합니다. 비활성화 제약 조건을 포함합니다."""
        org = await OrganizationService.get_organization(db, org_id)
        update_data = obj_in.model_dump(exclude_unset=True)

        new_active_status = update_data.get("is_active")
        if new_active_status is False and org.is_active is True:
            child_stmt = select(Organization).where(
                Organization.parent_id == org_id, Organization.is_active
            )
            active_child = (await db.execute(child_stmt)).scalars().first()
            if active_child:
                raise BadRequestException(
                    domain=DOMAIN,
                    error_code=ErrorCode.ACTIVE_CHILDREN_EXIST
                )

        new_parent_id = update_data.get("parent_id")
        if new_parent_id is not None and new_parent_id != org.parent_id:
            if new_parent_id == org.id:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.USR_INVALID_PARENT
                )

            current_parent = await db.get(Organization, new_parent_id)
            if not current_parent:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.USR_INVALID_PARENT
                )

            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == org.id:
                    raise BadRequestException(
                        domain=DOMAIN, error_code=ErrorCode.USR_CIRCULAR_REF
                    )
                current_parent = await db.get(Organization, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(org, field, value)

        org.updated_by = actor_id
        await db.commit()
        await db.refresh(org)

        data = {c.name: getattr(org, c.name) for c in org.__table__.columns}
        return OrgRead.model_validate(data)

    @staticmethod
    async def delete_organizations(db: AsyncSession, org_id: int) -> None:
        """조직 정보를 영구 삭제합니다."""
        org = await OrganizationService.get_organization(db, org_id)
        child_stmt = select(Organization).where(Organization.parent_id == org_id)
        if (await db.execute(child_stmt)).scalars().first():
            raise ConflictException(
                domain=DOMAIN, error_code=ErrorCode.ORG_HAS_CHILDREN
            )
        user_stmt = select(User).where(User.org_id == org_id)
        if (await db.execute(user_stmt)).scalars().first():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.ORG_HAS_USERS)
        await db.delete(org)
        await db.commit()


class UserService:
    """사용자(User) 계정 및 프로필 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def get_users(
        db: AsyncSession,
        page: int = 1,
        size: int = 20,
        sort: str | None = None,
        org_id: int | None = None,
        include_children: bool = False,
        keyword: str | None = None,
        is_active: bool | None = None,
    ) -> tuple[list[User], int]:
        """사용자 목록을 다양한 조건으로 검색하고 페이징 처리하여 반환합니다."""
        from sqlalchemy import func
        from sqlalchemy.orm import joinedload, selectinload

        # 기본 쿼리 구성 (organization은 joinedload, roles는 selectinload로 즉시 로딩)
        stmt = select(User).options(
            joinedload(User.organization), selectinload(User.roles)
        )
        if is_active is not None:
            stmt = stmt.where(User.is_active == is_active)

        if keyword and keyword.strip():
            k = f"%{keyword.strip()}%"
            stmt = stmt.where(
                or_(
                    User.name.ilike(k),
                    User.login_id.ilike(k),
                    User.emp_code.ilike(k),
                    User.email.ilike(k),
                    User.phone.ilike(k),
                )
            )

        if org_id is not None:
            if include_children:
                descendant_org_ids = await OrganizationService.get_descendant_org_ids(db, org_id)
                stmt = stmt.where(User.org_id.in_(descendant_org_ids))
            else:
                stmt = stmt.where(User.org_id == org_id)

        # 전체 개수 조회 (페이징 적용 전)
        count_stmt = select(func.count()).select_from(stmt.subquery())
        total = await db.scalar(count_stmt) or 0

        # 정렬 적용
        if sort:
            try:
                field, order = sort.rsplit("_", 1)
                if field == "org_name":
                    stmt = stmt.outerjoin(User.organization)
                    column = Organization.name
                else:
                    column = getattr(User, field, None)

                if column is not None:
                    if order.lower() == "desc":
                        stmt = stmt.order_by(column.desc())
                    else:
                        stmt = stmt.order_by(column.asc())
                else:
                    stmt = stmt.order_by(User.created_at.desc())
            except (ValueError, AttributeError):
                stmt = stmt.order_by(User.created_at.desc())
        else:
            stmt = stmt.order_by(User.created_at.desc())

        stmt = stmt.offset((page - 1) * size).limit(size)
        result = await db.execute(stmt)
        users = list(result.scalars().all())

        return users, total

    @staticmethod
    async def create_user(db: AsyncSession, obj_in: UserCreate, actor_id: int) -> User:
        """신규 사용자 계정을 생성합니다."""
        checks = [
            (User.login_id == obj_in.login_id, ErrorCode.DUPLICATE_LOGIN_ID),
            (User.email == obj_in.email, ErrorCode.DUPLICATE_EMAIL),
            (User.emp_code == obj_in.emp_code, ErrorCode.DUPLICATE_EMP_CODE),
        ]

        for condition, error_code in checks:
            stmt = select(User).where(condition)
            result = await db.execute(stmt)
            if result.scalar_one_or_none():
                raise ConflictException(domain=DOMAIN, error_code=error_code)

        # metadata -> user_metadata 매핑 처리
        create_data = obj_in.model_dump(exclude={"password", "role_ids", "metadata"})
        create_data["user_metadata"] = obj_in.metadata or {}
        create_data["password_hash"] = get_password_hash(obj_in.password)
        create_data["created_by"] = actor_id
        create_data["updated_by"] = actor_id

        user = User(**create_data)
        db.add(user)
        await db.flush()

        if obj_in.role_ids:
            from app.domains.iam.services import UserRoleService

            await UserRoleService.assign_roles_to_user(
                db,
                user_id=user.id,
                role_ids=obj_in.role_ids,
                actor_id=actor_id,
                ip="system",
                user_agent="system",
            )

        await db.commit()

        from sqlalchemy.orm import joinedload, selectinload

        stmt = (
            select(User)
            .options(joinedload(User.organization), selectinload(User.roles))
            .where(User.id == user.id)
        )
        result = await db.execute(stmt)
        return result.scalar_one()

    @staticmethod
    async def update_user(
        db: AsyncSession,
        user_id: int,
        user_in: UserUpdate,
        actor_id: int,
        actor_is_admin: bool,
        ip: str,
        user_agent: str,
    ) -> User:
        """사용자 정보를 수정합니다."""
        user = await UserService.get_user(db, user_id)
        update_data = user_in.model_dump(exclude_unset=True)

        restricted_fields = ["org_id", "is_active"]
        if not actor_is_admin:
            for field in restricted_fields:
                if field in update_data:
                    del update_data[field]

        # 이메일 중복 체크
        new_email = update_data.get("email")
        if new_email and new_email != user.email:
            stmt = select(User).where(User.email == new_email)
            if (await db.execute(stmt)).scalar_one_or_none():
                raise ConflictException(
                    domain=DOMAIN, error_code=ErrorCode.DUPLICATE_EMAIL
                )

        # metadata -> user_metadata 명시적 매핑 및 병합
        if "metadata" in update_data:
            current_meta = user.user_metadata or {}
            new_meta = update_data.pop("metadata")
            user.user_metadata = {**current_meta, **new_meta}

        # 나머지 일반 필드 반영
        for key, value in update_data.items():
            if hasattr(user, key):
                setattr(user, key, value)

        user.updated_by = actor_id
        await db.commit()

        from sqlalchemy.orm import joinedload, selectinload

        stmt = (
            select(User)
            .options(joinedload(User.organization), selectinload(User.roles))
            .where(User.id == user.id)
        )
        result = await db.execute(stmt)
        return result.scalar_one()

    @staticmethod
    async def change_password(
        db: AsyncSession,
        user_id: int,
        password_in: UserPasswordUpdate,
        current_user: User,
    ) -> None:
        """사용자의 비밀번호를 변경합니다."""
        user = await UserService.get_user(db, user_id)
        is_self = current_user.id == user.id

        if is_self:
            if not password_in.current_password or not verify_password(
                password_in.current_password, user.password_hash
            ):
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.PASSWORD_MISMATCH
                )
        else:
            if not current_user.is_superuser:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED
                )

        user.password_hash = get_password_hash(password_in.new_password)
        user.updated_by = current_user.id
        await db.commit()

    @staticmethod
    async def delete_user(db: AsyncSession, user_id: int, actor_id: int) -> None:
        """사용자 계정을 퇴사 처리(비활성화)합니다."""
        user = await UserService.get_user(db, user_id)
        user.is_active = False
        user.account_status = "BLOCKED"  # 퇴사 시 계정도 차단
        user.updated_by = actor_id

        current_meta = user.user_metadata or {}
        current_meta["retired_at"] = datetime.now().isoformat()
        user.user_metadata = current_meta

        await db.commit()

    @staticmethod
    async def toggle_account_status(
        db: AsyncSession, user_id: int, actor_id: int
    ) -> User:
        """사용자 계정 상태를 전환(ACTIVE <-> BLOCKED)합니다."""
        user = await UserService.get_user(db, user_id)
        if user.account_status == "ACTIVE":
            user.account_status = "BLOCKED"
        else:
            user.account_status = "ACTIVE"

        user.updated_by = actor_id
        await db.commit()
        await db.refresh(user)

        # organization 정보 포함하여 반환
        from sqlalchemy.orm import joinedload

        stmt = (
            select(User)
            .options(joinedload(User.organization))
            .where(User.id == user.id)
        )
        result = await db.execute(stmt)
        return result.scalar_one()

    @staticmethod
    async def get_user(db: AsyncSession, user_id: int) -> User:
        """특정 사용자 정보를 ID로 조회합니다. (권한 정보 포함)"""
        from sqlalchemy.orm import joinedload, selectinload

        stmt = (
            select(User)
            .options(joinedload(User.organization), selectinload(User.roles))
            .where(User.id == user_id)
        )

        result = await db.execute(stmt)
        user = result.scalar_one_or_none()
        if not user:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return user

    @staticmethod
    async def get_user_by_login_id(db: AsyncSession, login_id: str) -> User | None:
        """로그인 ID를 기반으로 사용자를 조회합니다."""
        stmt = select(User).where(User.login_id == login_id)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    @staticmethod
    async def upload_profile_image(
        db: AsyncSession,
        user_id: int,
        file: UploadFile,
        actor_id: int,
    ) -> User:
        """사용자의 프로필 이미지를 업로드하고 연동합니다."""
        user = await UserService.get_user(db, user_id)

        if user.profile_image_id:
            await AttachmentService.delete_attachment(
                db,
                attachment_id=user.profile_image_id,
                actor_id=actor_id,
                actor_org_id=user.org_id,
                is_admin=True,
            )

        new_attachment_id = uuid.uuid4()
        file_ext = file.filename.split(".")[-1] if file.filename else "bin"
        object_name = f"USR/PROFILE/{new_attachment_id.hex}.{file_ext}"

        file_data = await file.read()
        if not upload_file_stream(
            object_name, file_data, file.content_type or "application/octet-stream"
        ):
            raise ServiceUnavailableException(
                domain=DOMAIN, error_code=ErrorCode.STORAGE_ERROR
            )
        attachment_in = AttachmentCreate(
            id=new_attachment_id,
            domain_code="USR",
            resource_type="PROFILE",
            ref_id=user.id,
            category_code="AVATAR",
            file_name=file.filename or "profile_image",
            file_path=object_name,
            file_size=len(file_data),
            content_type=file.content_type or "image/png",
            org_id=user.org_id,
            created_by=actor_id,
        )
        await AttachmentService.create_attachment_metadata(db, attachment_in)

        user.profile_image_id = new_attachment_id
        user.updated_by = actor_id

        await db.commit()
        await db.refresh(user)
        return user
