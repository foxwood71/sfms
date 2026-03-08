"""공통 관리(CMM) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 시스템의 기준 정보가 되는 공통 코드 관리, 통합 첨부파일 처리,
그리고 사용자 대상 알림 발송 및 조회 로직을 담당합니다.
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import delete, select, update
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload, selectinload

from app.core.codes import ErrorCode
from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    NotFoundException,
)
from app.domains.cmm.models import Attachment, CodeDetail, CodeGroup, Notification
from app.domains.cmm.schemas import (
    AttachmentCreate,
    CodeDetailCreate,
    CodeDetailRead,
    CodeDetailUpdate,
    CodeGroupCreate,
    CodeGroupRead,
    CodeGroupUpdate,
    NotificationCreate,
)

from . import DOMAIN


class CodeService:
    """공통 코드(그룹 및 상세)를 관리하는 서비스 클래스입니다.
    
    시스템 전반에서 사용되는 각종 구분값과 상태 코드를 계층적으로 관리합니다.
    """

    @staticmethod
    async def get_code_group(db: AsyncSession, group_code: str) -> CodeGroupRead:
        """특정 코드 그룹과 하위 상세 코드 목록을 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            group_code (str): 조회할 그룹 코드 식별자

        Returns:
            CodeGroupRead: 그룹 정보 및 상세 코드 리스트가 포함된 스키마

        Raises:
            NotFoundException: 해당 코드가 존재하지 않을 경우 발생
        """
        stmt = (
            select(CodeGroup)
            .options(joinedload(CodeGroup.details))
            .where(CodeGroup.group_code == group_code)
        )
        result = await db.execute(stmt)
        group = result.unique().scalar_one_or_none()
        if not group:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return CodeGroupRead.model_validate(group)

    @staticmethod
    async def list_active_codes(db: AsyncSession, domain_code: str | None = None) -> list[CodeGroupRead]:
        """활성화된 전체 코드 목록을 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            domain_code (str | None, optional): 특정 도메인(예: 'FAC') 필터링. 기본값은 None.

        Returns:
            list[CodeGroupRead]: 활성화된 코드 그룹 목록
        """
        stmt = (
            select(CodeGroup)
            .options(joinedload(CodeGroup.details))
            .where(CodeGroup.is_active)
        )
        if domain_code:
            stmt = stmt.where(CodeGroup.domain_code == domain_code)

        result = await db.execute(stmt)
        groups = result.unique().scalars().all()
        return [CodeGroupRead.model_validate(g) for g in groups]

    @staticmethod
    async def create_code_group(db: AsyncSession, obj_in: CodeGroupCreate, actor_id: int) -> CodeGroupRead:
        """신규 코드 그룹을 생성합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            obj_in (CodeGroupCreate): 생성 정보 스키마
            actor_id (int): 생성자 고유 ID

        Returns:
            CodeGroupRead: 생성된 그룹 정보

        Raises:
            ConflictException: 이미 동일한 그룹 코드가 존재할 경우 발생
        """
        existing = await db.execute(
            select(CodeGroup).where(CodeGroup.group_code == obj_in.group_code)
        )
        if existing.scalar_one_or_none():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.DUPLICATE_CODE)

        db_obj = CodeGroup(**obj_in.model_dump(), created_by=actor_id, updated_by=actor_id)
        db.add(db_obj)
        await db.commit()
        
        # 즉시 로딩을 포함하여 다시 조회 후 스키마로 변환
        stmt = (
            select(CodeGroup)
            .options(selectinload(CodeGroup.details))
            .where(CodeGroup.id == db_obj.id)
        )
        result = await db.execute(stmt)
        return CodeGroupRead.model_validate(result.scalar_one())

    @staticmethod
    async def update_code_group(db: AsyncSession, group_code: str, obj_in: CodeGroupUpdate, actor_id: int) -> CodeGroupRead:
        """기존 코드 그룹 정보를 수정합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            group_code (str): 수정할 대상 그룹 코드
            obj_in (CodeGroupUpdate): 수정할 정보 스키마
            actor_id (int): 수정자 고유 ID

        Returns:
            CodeGroupRead: 수정 완료된 그룹 정보

        Raises:
            NotFoundException: 대상 그룹이 존재하지 않을 때 발생
        """
        # 1. 원본 모델 조회
        stmt = select(CodeGroup).where(CodeGroup.group_code == group_code)
        result = await db.execute(stmt)
        group = result.scalar_one_or_none()
        
        if not group:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        # 2. 데이터 업데이트
        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(group, field, value)

        group.updated_by = actor_id
        await db.commit()
        
        # 3. 즉시 로딩 후 스키마로 반환
        stmt = (
            select(CodeGroup)
            .options(selectinload(CodeGroup.details))
            .where(CodeGroup.id == group.id)
        )
        result = await db.execute(stmt)
        return CodeGroupRead.model_validate(result.scalar_one())

    @staticmethod
    async def delete_code_group(db: AsyncSession, group_code: str) -> None:
        """코드 그룹을 물리적으로 삭제합니다. 시스템 필수 코드는 삭제가 거부됩니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            group_code (str): 삭제할 대상 그룹 코드

        Raises:
            NotFoundException: 대상 그룹이 존재하지 않을 때 발생
            ConflictException: 시스템 필수 코드를 삭제하려 할 때 발생 (ErrorCode.SYSTEM_RESOURCE_MOD)
        """
        # 내부 로직용 모델 조회
        stmt = select(CodeGroup).where(CodeGroup.group_code == group_code)
        result = await db.execute(stmt)
        group = result.scalar_one_or_none()
        
        if not group:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
            
        if group.is_system:
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.SYSTEM_RESOURCE_MOD)

        await db.delete(group)
        await db.commit()

    @staticmethod
    async def create_code_detail(
        db: AsyncSession, group_code: str, obj_in: CodeDetailCreate, actor_id: int
    ) -> CodeDetailRead:
        """특정 그룹에 새로운 상세 코드를 추가합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            group_code (str): 소속될 부모 그룹 코드
            obj_in (CodeDetailCreate): 상세 코드 생성 정보
            actor_id (int): 생성자 고유 ID

        Returns:
            CodeDetailRead: 생성된 상세 코드 정보

        Raises:
            ConflictException: 동일한 상세 코드가 해당 그룹 내에 이미 존재할 때 발생
        """
        # 그룹 존재 확인
        await CodeService.get_code_group(db, group_code)
        
        existing = await db.execute(
            select(CodeDetail).where(
                CodeDetail.group_code == group_code,
                CodeDetail.detail_code == obj_in.detail_code,
            )
        )
        if existing.scalar_one_or_none():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.DUPLICATE_CODE)

        db_obj = CodeDetail(
            **obj_in.model_dump(),
            group_code=group_code,
            created_by=actor_id,
            updated_by=actor_id,
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return CodeDetailRead.model_validate(db_obj)

    @staticmethod
    async def update_code_detail(
        db: AsyncSession,
        group_code: str,
        detail_code: str,
        obj_in: CodeDetailUpdate,
        actor_id: int,
    ) -> CodeDetailRead:
        """특정 상세 코드의 명칭이나 속성을 수정합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            group_code (str): 부모 그룹 코드
            detail_code (str): 수정할 대상 상세 코드
            obj_in (CodeDetailUpdate): 수정할 데이터
            actor_id (int): 수정자 고유 ID

        Returns:
            CodeDetailRead: 수정 완료된 상세 코드 정보
        """
        stmt = select(CodeDetail).where(
            CodeDetail.group_code == group_code, CodeDetail.detail_code == detail_code
        )
        result = await db.execute(stmt)
        detail = result.scalar_one_or_none()
        if not detail:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        update_data = obj_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(detail, field, value)

        detail.updated_by = actor_id
        await db.commit()
        await db.refresh(detail)
        return CodeDetailRead.model_validate(detail)


class AttachmentService:
    """첨부파일 메타데이터 및 스토리지 연결을 관리하는 서비스 클래스입니다.
    
    실제 파일 스트림 처리는 core.storage 모듈을 활용하며, 본 클래스는 DB 메타데이터와 권한 관리를 담당합니다.
    """

    @staticmethod
    async def create_attachment_metadata(
        db: AsyncSession, obj_in: AttachmentCreate
    ) -> Attachment:
        """첨부파일 메타데이터를 생성합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            obj_in (AttachmentCreate): 파일 메타데이터 생성 정보 (ID, 경로, 크기 등)

        Returns:
            Attachment: 생성된 SQLAlchemy 모델 객체 (주의: commit은 호출자가 수행)
        """
        db_obj = Attachment(**obj_in.model_dump())
        db.add(db_obj)
        return db_obj

    @staticmethod
    async def get_attachment(db: AsyncSession, attachment_id: uuid.UUID) -> Attachment:
        """ID를 기반으로 첨부파일 메타데이터를 단건 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            attachment_id (uuid.UUID): 파일 고유 식별자

        Returns:
            Attachment: 조회된 파일 모델 객체

        Raises:
            NotFoundException: 파일 정보가 존재하지 않을 때 발생
        """
        attachment = await db.get(Attachment, attachment_id)
        if not attachment:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return attachment

    @staticmethod
    async def delete_attachment(
        db: AsyncSession,
        attachment_id: uuid.UUID,
        actor_id: int,
        actor_org_id: int | None,
        is_admin: bool = False,
        permanent: bool = False,
    ) -> None:
        """첨부파일을 삭제 처리합니다. 기본적으로 소프트 삭제를 수행합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            attachment_id (uuid.UUID): 삭제할 파일 ID
            actor_id (int): 행위 수행자 ID
            actor_org_id (int | None): 수행자의 소속 부서 ID
            is_admin (bool, optional): 관리자 권한 여부. 기본값은 False.
            permanent (bool, optional): 물리 삭제(Hard Delete) 여부. 기본값은 False.

        Raises:
            BadRequestException: 본인 또는 소속 부서 파일이 아닐 때 발생 (ErrorCode.ACCESS_DENIED)
        """
        attachment = await AttachmentService.get_attachment(db, attachment_id)

        # 권한 체크: 관리자이거나, 본인이거나, 같은 부서인 경우만 허용
        if not is_admin and attachment.created_by != actor_id:
            if not actor_org_id or attachment.org_id != actor_org_id:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED
                )

        if permanent:
            if not is_admin:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED
                )
            await db.delete(attachment)
        else:
            attachment.is_deleted = True
            attachment.updated_by = actor_id

    @staticmethod
    async def list_deleted_attachments(
        db: AsyncSession,
        actor_id: int,
        actor_org_id: int | None,
        is_admin: bool = False,
        domain_code: str | None = None,
        resource_type: str | None = None,
        ref_id: int | None = None,
        skip: int = 0,
        limit: int = 100,
    ) -> list[Attachment]:
        """소프트 삭제된 파일 목록(휴지통)을 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            actor_id (int): 행위 수행자 ID (권한 필터링용)
            actor_org_id (int | None): 소속 부서 ID
            is_admin (bool, optional): 관리자 여부. 관리자는 모든 삭제 파일을 볼 수 있습니다.
            domain_code (str | None, optional): 도메인 코드 필터.
            resource_type (str | None, optional): 리소스 유형 필터.
            ref_id (int | None, optional): 참조 ID 필터.
            skip (int, optional): 페이징 시작 오프셋. 기본값은 0.
            limit (int, optional): 페이징 제한 수. 기본값은 100.

        Returns:
            list[Attachment]: 삭제된 파일 정보 리스트
        """
        stmt = select(Attachment).where(Attachment.is_deleted)

        # 권한 필터링: 관리자가 아니면 본인 또는 부서 데이터만
        if not is_admin:
            if actor_org_id:
                stmt = stmt.where(
                    (Attachment.created_by == actor_id)
                    | (Attachment.org_id == actor_org_id)
                )
            else:
                stmt = stmt.where(Attachment.created_by == actor_id)

        if domain_code:
            stmt = stmt.where(Attachment.domain_code == domain_code)
        if resource_type:
            stmt = stmt.where(Attachment.resource_type == resource_type)
        if ref_id:
            stmt = stmt.where(Attachment.ref_id == ref_id)

        stmt = stmt.offset(skip).limit(limit)
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def restore_attachment(
        db: AsyncSession,
        attachment_id: uuid.UUID,
        actor_id: int,
        actor_org_id: int | None,
        is_admin: bool = False,
    ) -> None:
        """소프트 삭제된 파일을 다시 복구합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            attachment_id (uuid.UUID): 복구할 파일 ID
            actor_id (int): 행위 수행자 ID
            actor_org_id (int | None): 소속 부서 ID
            is_admin (bool, optional): 관리자 여부. 기본값은 False.
        """
        attachment = await AttachmentService.get_attachment(db, attachment_id)

        # 권한 체크
        if not is_admin and attachment.created_by != actor_id:
            if not actor_org_id or attachment.org_id != actor_org_id:
                raise BadRequestException(
                    domain=DOMAIN, error_code=ErrorCode.ACCESS_DENIED
                )

        attachment.is_deleted = False
        attachment.updated_by = actor_id


class NotificationService:
    """사용자 대상 알림(메시지) 관리 서비스 클래스입니다.
    
    시스템 자동 발송 및 사용자별 알림 목록 조회, 읽음 처리 기능을 수행합니다.
    """

    @staticmethod
    async def list_my_notifications(
        db: AsyncSession, user_id: int, unread_only: bool = False
    ) -> list[Notification]:
        """현재 로그인한 사용자의 수신 알림 목록을 조회합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            user_id (int): 사용자 고유 ID
            unread_only (bool, optional): 읽지 않은 알림만 필터링할지 여부. 기본값은 False.

        Returns:
            list[Notification]: 알림 목록 (최신순 정렬)
        """
        stmt = select(Notification).where(
            Notification.receiver_user_id == user_id,
            Notification.is_deleted.is_(False),
        )
        if unread_only:
            stmt = stmt.where(Notification.is_read.is_(False))

        stmt = stmt.order_by(Notification.created_at.desc())
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def mark_as_read(db: AsyncSession, notification_id: int, user_id: int) -> None:
        """특정 알림을 읽음 상태로 변경합니다.

        Args:
            db (AsyncSession): 비동기 DB 세션
            notification_id (int): 대상 알림 ID
            user_id (int): 행위 수행자 ID (본인 확인용)

        Raises:
            NotFoundException: 본인에게 발송된 알림이 아닐 때 발생
        """
        stmt = select(Notification).where(
            Notification.id == notification_id, Notification.receiver_user_id == user_id
        )
        result = await db.execute(stmt)
        notification = result.scalar_one_or_none()

        if not notification:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        if not notification.is_read:
            notification.is_read = True
            notification.read_at = datetime.now()
            await db.commit()
