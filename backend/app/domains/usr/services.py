"""사용자(User) 및 조직(Organization) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 조직의 계층 구조 관리, 사용자 계정 생성 및 수정, 비밀번호 관리,
그리고 프로필 이미지 업로드 등의 핵심 인사/조직 업무 로직을 수행합니다.
"""

from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

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
from app.domains.sys.schemas import AuditLogCreate
from app.domains.sys.services import AuditLogService
from app.domains.usr.models import Organization, User
from app.domains.usr.schemas import (
    OrgCreate,
    OrgRead,
    OrgUpdate,
    UserCreate,
    UserRead,
    UserPasswordUpdate,
    UserUpdate,
)

from . import DOMAIN


class OrgService:
    """조직(Organization) 및 부서 관리 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.
    
    부서 간 계층 구조(Tree)를 조립하고, 순환 참조 방지 및 하위 부서 일괄 조회 기능을 제공합니다.
    """

    @staticmethod
    async def get_descendant_org_ids(db: AsyncSession, org_id: int) -> list[int]:
        """특정 조직을 포함하여 모든 하위 조직의 ID 목록을 재귀적으로 조회합니다.

        SQL의 Recursive CTE를 활용하여 깊이에 상관없이 모든 자손 노드의 ID를 추출합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            org_id (int): 기준이 되는 최상위 조직 ID

        Returns:
            list[int]: 자기 자신 및 모든 하위 부서의 고유 ID 리스트
        """
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
        db: AsyncSession, mode: str = "tree", is_active: bool = True
    ) -> list[OrgRead]:
        """전체 조직 목록을 트리 또는 평면 리스트 구조로 조회합니다.

        비동기 환경에서의 지연 로딩 에러(MissingGreenlet)를 방지하기 위해 
        모델 데이터를 딕셔너리로 미리 추출한 후 스키마를 생성하여 반환합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            mode (str, optional): 조회 모드 ('tree': 계층 구조, 'flat': 단순 리스트). 기본값은 "tree".
            is_active (bool, optional): 활성화된 부서만 포함할지 여부. 기본값은 True.

        Returns:
            list[OrgRead]: 조직 정보 리스트 (모드에 따라 children 필드 포함 여부 결정)
        """
        stmt = select(Organization)
        if is_active:
            stmt = stmt.where(Organization.is_active == True)

        stmt = stmt.order_by(Organization.sort_order.asc())
        result = await db.execute(stmt)
        orgs = list(result.scalars().all())

        # 지연 로딩 방지: 모델 데이터를 딕셔너리로 미리 추출하여 스키마 생성
        org_reads = []
        for org in orgs:
            data = {c.name: getattr(org, c.name) for c in org.__table__.columns}
            org_reads.append(OrgRead.model_validate(data))

        if mode == "flat":
            return org_reads

        # Tree 구조 조립 로직
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
        """새로운 조직(부서)을 등록합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (OrgCreate): 신규 부서 등록 정보
            actor_id (int): 행위 수행자 고유 ID

        Returns:
            OrgRead: 생성 완료된 부서 정보 스키마

        Raises:
            ConflictException: 이미 동일한 부서 코드가 존재하거나 상위 부서 ID가 유효하지 않을 때 발생
        """
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
                    domain=DOMAIN, error_code=ErrorCode.INVALID_PARENT_ORG
                )

        db_obj = Organization(
            **obj_in.model_dump(), created_by=actor_id, updated_by=actor_id
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        
        # 지연 로딩 방지
        data = {c.name: getattr(db_obj, c.name) for c in db_obj.__table__.columns}
        return OrgRead.model_validate(data)

    @staticmethod
    async def get_organization(db: AsyncSession, org_id: int) -> Organization:
        """특정 조직 정보를 ID로 단건 조회합니다. (내부 서비스용 모델 반환)

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            org_id (int): 조회할 조직의 고유 ID

        Returns:
            Organization: SQLAlchemy 모델 객체

        Raises:
            NotFoundException: 해당 ID의 조직이 존재하지 않을 때 발생
        """
        org = await db.get(Organization, org_id)
        if not org:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return org

    @staticmethod
    async def update_organizations(
        db: AsyncSession, org_id: int, obj_in: OrgUpdate, actor_id: int
    ) -> OrgRead:
        """기존 조직 정보를 수정합니다. 순환 참조 여부를 엄격히 검증합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            org_id (int): 수정할 대상 조직 ID
            obj_in (OrgUpdate): 업데이트할 필드 정보
            actor_id (int): 행위 수행자 ID

        Returns:
            OrgRead: 수정 완료된 부서 정보 스키마

        Raises:
            BadRequestException: 자기 자신을 부모로 설정하거나 순환 참조가 발생할 때 발생
        """
        org = await OrgService.get_organization(db, org_id)
        update_data = obj_in.model_dump(exclude_unset=True)

        new_parent_id = update_data.get("parent_id")
        if new_parent_id is not None and new_parent_id != org.parent_id:
            if new_parent_id == org.id:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.INVALID_PARENT_ORG
                )

            current_parent = await db.get(Organization, new_parent_id)
            while current_parent and current_parent.parent_id:
                if current_parent.parent_id == org.id:
                    raise BadRequestException(
                        domain=DOMAIN, error_code=ErrorCode.CIRCULAR_REFERENCE
                    )
                current_parent = await db.get(Organization, current_parent.parent_id)

        for field, value in update_data.items():
            setattr(org, field, value)

        org.updated_by = actor_id
        await db.commit()
        await db.refresh(org)
        
        # 지연 로딩 방지
        data = {c.name: getattr(org, c.name) for c in org.__table__.columns}
        return OrgRead.model_validate(data)

    @staticmethod
    async def delete_organizations(db: AsyncSession, org_id: int) -> None:
        """조직 정보를 영구 삭제합니다.

        다음의 경우 삭제가 차단됩니다:
        1. 하위 부서가 하나라도 존재하는 경우.
        2. 해당 부서에 소속된 사용자가 존재하는 경우.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            org_id (int): 삭제할 조직 ID

        Raises:
            ConflictException: 하위 데이터가 존재하여 삭제할 수 없을 때 발생
        """
        org = await OrgService.get_organization(db, org_id)

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
    """사용자(User) 계정 및 프로필 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.
    
    사용자 등록, 정보 수정, 권한별 필드 제한, 비밀번호 관리 및 프로필 이미지 업로드를 담당합니다.
    """

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
    ) -> list[User]:
        """사용자 목록을 다양한 조건으로 검색하고 페이징 처리하여 반환합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            page (int, optional): 조회할 페이지 번호. 기본값은 1.
            size (int, optional): 페이지당 레코드 수. 기본값은 20.
            sort (str | None, optional): 정렬 기준 ('name' 등). 기본값은 None.
            org_id (int | None, optional): 특정 부서 필터. 기본값은 None.
            include_children (bool, optional): 하위 부서 소속 사용자 포함 여부. 기본값은 False.
            keyword (str | None, optional): 성명, ID, 사번 통합 검색 키워드. 기본값은 None.
            is_active (bool | None, optional): 활성/비활성 계정 필터. 기본값은 None.

        Returns:
            list[User]: 조회된 사용자 모델 객체 리스트
        """
        stmt = select(User)
        if is_active is not None:
            stmt = stmt.where(User.is_active == is_active)

        if keyword:
            stmt = stmt.where(
                or_(
                    User.name.ilike(f"%{keyword}%"),
                    User.login_id.ilike(f"%{keyword}%"),
                    User.emp_code.ilike(f"%{keyword}%"),
                )
            )

        if org_id:
            if include_children:
                descendant_org_ids = await OrgService.get_descendant_org_ids(db, org_id)
                stmt = stmt.where(User.org_id.in_(descendant_org_ids))
            else:
                stmt = stmt.where(User.org_id == org_id)

        if sort == "name":
            stmt = stmt.order_by(User.name.asc())
        else:
            stmt = stmt.order_by(User.created_at.desc())

        stmt = stmt.offset((page - 1) * size).limit(size)
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def create_user(db: AsyncSession, obj_in: UserCreate, actor_id: int) -> User:
        """신규 사용자 계정을 생성합니다. ID, 이메일, 사번의 중복 여부를 체크합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (UserCreate): 사용자 생성 정보
            actor_id (int): 생성을 수행한 사용자 ID

        Returns:
            User: 생성 완료된 사용자 모델 객체

        Raises:
            ConflictException: 로그인 ID, 이메일, 또는 사번이 이미 존재할 때 발생
        """
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

        create_data = obj_in.model_dump(exclude={"password"})
        create_data["password_hash"] = get_password_hash(obj_in.password)
        create_data["created_by"] = actor_id
        create_data["updated_by"] = actor_id

        user = User(**create_data)
        db.add(user)
        await db.commit()
        await db.refresh(user)
        return user

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
        """사용자 정보를 수정합니다. 관리자 여부에 따라 수정 가능한 필드가 제한됩니다.

        일반 사용자는 본인의 이름, 이메일 등 프로필은 수정 가능하나 
        부서(org_id)나 활성 상태(is_active) 변경은 차단(무시)됩니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 수정할 대상 사용자 ID
            user_in (UserUpdate): 업데이트할 데이터
            actor_id (int): 수정 행위를 수행하는 사용자 ID
            actor_is_admin (bool): 수행자가 관리자 권한을 가졌는지 여부
            ip (str): 요청자 IP 주소 (감사로그용)
            user_agent (str): 요청자 브라우저 정보 (감사로그용)

        Returns:
            User: 수정 완료된 사용자 모델 객체
        """
        user = await UserService.get_user(db, user_id)
        update_data = user_in.model_dump(exclude_unset=True)

        # 보안 로직: 관리자가 아닌 경우 부서 이동 및 상태 변경 제한
        restricted_fields = ["org_id", "is_active"]
        if not actor_is_admin:
            for field in restricted_fields:
                if field in update_data:
                    del update_data[field]

        new_email = update_data.get("email")
        if new_email and new_email != user.email:
            stmt = select(User).where(User.email == new_email)
            existing = await db.execute(stmt)
            if existing.scalar_one_or_none():
                raise ConflictException(
                    domain=DOMAIN, error_code=ErrorCode.DUPLICATE_EMAIL
                )

        old_org_id = user.org_id
        new_org_id = update_data.get("org_id")
        is_org_changed = "org_id" in update_data and old_org_id != new_org_id

        for key, value in update_data.items():
            setattr(user, key, value)

        user.updated_by = actor_id

        if is_org_changed:
            await AuditLogService.create_audit_log(
                db,
                AuditLogCreate(
                    action_type="ORG_CHANGE",
                    target_domain="USR",
                    target_table="users",
                    target_id=str(user.id),
                    actor_user_id=actor_id,
                    client_ip=ip,
                    user_agent=user_agent,
                    snapshot={"old_org_id": old_org_id, "new_org_id": new_org_id},
                    description=f"사용자 {user.name}의 부서 변경",
                ),
            )

        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def change_password(
        db: AsyncSession,
        user_id: int,
        password_in: UserPasswordUpdate,
        current_user: User,
    ) -> None:
        """사용자의 비밀번호를 변경합니다.

        본인의 경우 현재 비밀번호 확인이 필수이며, 
        관리자는 현재 비밀번호 확인 없이 강제 변경이 가능합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 대상 사용자 ID
            password_in (UserPasswordUpdate): 비밀번호 변경 데이터 (현재/신규 PW)
            current_user (User): 행위 수행자 객체

        Raises:
            BadRequestException: 현재 비밀번호가 일치하지 않거나 권한이 없을 때 발생
        """
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
        """사용자 계정을 비활성화(소프트 삭제) 처리합니다.

        실제로 데이터를 지우지 않고 `is_active` 플래그를 False로 변경하며, 
        메타데이터에 퇴사 일시를 기록합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 대상 사용자 ID
            actor_id (int): 행위 수행자 ID
        """
        user = await UserService.get_user(db, user_id)
        user.is_active = False
        user.updated_by = actor_id

        current_meta = user.user_metadata or {}
        current_meta["retired_at"] = datetime.now().isoformat()
        user.user_metadata = current_meta

        await db.commit()

    @staticmethod
    async def get_user(db: AsyncSession, user_id: int) -> User:
        """특정 사용자 정보를 ID로 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 조회할 사용자 ID

        Returns:
            User: 사용자 모델 객체

        Raises:
            NotFoundException: 해당 사용자가 존재하지 않을 때 발생
        """
        user = await db.get(User, user_id)
        if not user:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return user

    @staticmethod
    async def get_user_by_login_id(db: AsyncSession, login_id: str) -> User | None:
        """로그인 ID를 기반으로 사용자를 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            login_id (str): 검색할 로그인 아이디

        Returns:
            User | None: 조회된 사용자 객체 또는 None
        """
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
        """사용자의 프로필 이미지를 업로드하고 연동합니다.

        이 메서드는 다음 작업을 수행합니다:
        1. 기존에 등록된 프로필 이미지가 있다면 삭제 처리.
        2. 신규 이미지 파일을 MinIO 스토리지에 스트림 업로드.
        3. CMM 도메인의 통합 첨부파일 메타데이터 생성.
        4. 사용자의 profile_image_id 필드 갱신.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 이미지 주체인 사용자 ID
            file (UploadFile): 업로드할 이미지 파일 객체
            actor_id (int): 업로드 행위 수행자 ID

        Returns:
            User: 프로필 정보가 갱신된 사용자 모델 객체

        Raises:
            ServiceUnavailableException: 스토리지 서버(MinIO) 연결 오류 시 발생
        """
        user = await UserService.get_user(db, user_id)

        # 1. 기존 이미지 메타데이터 삭제 (있는 경우)
        if user.profile_image_id:
            await AttachmentService.delete_attachment(
                db,
                attachment_id=user.profile_image_id,
                actor_id=actor_id,
                actor_org_id=user.org_id,
                is_admin=True,
            )

        # 2. 파일 스토리지 업로드
        new_attachment_id = uuid.uuid4()
        file_ext = file.filename.split(".")[-1] if file.filename else "bin"
        object_name = f"USR/PROFILE/{new_attachment_id.hex}.{file_ext}"

        file_data = await file.read()
        # 2. MinIO 스토리지 업로드
        if not upload_file_stream(
            object_name, file_data, file.content_type or "application/octet-stream"
        ):
            raise ServiceUnavailableException(
                domain=DOMAIN, error_code=ErrorCode.STORAGE_ERROR
            )
        # 3. 첨부파일 메타데이터 생성
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

        # 4. 사용자 정보 갱신
        user.profile_image_id = new_attachment_id
        user.updated_by = actor_id

        await db.commit()
        await db.refresh(user)
        return user
