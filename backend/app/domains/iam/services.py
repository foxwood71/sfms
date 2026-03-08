"""인증 및 권한(IAM) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 사용자 인증, JWT 토큰 관리, 역할(Role) CRUD,
사용자별 역할 할당(RBAC) 등의 핵심 보안 로직을 담당합니다.
"""

from datetime import datetime
from typing import Any

from sqlalchemy import delete, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import redis_client
from app.core.codes import ErrorCode
from app.core.exceptions import (
    ConflictException,
    ForbiddenException,
    NotFoundException,
    RateLimitException,
    UnauthorizedException,
)
from app.core.security import verify_password
from app.domains.iam.models import Role, UserRole
from app.domains.iam.schemas import LoginRequest, RoleCreate, RoleUpdate
from app.domains.sys.schemas import AuditLogCreate
from app.domains.sys.services import AuditLogService
from app.domains.usr.models import User
from app.domains.usr.services import UserService

from . import DOMAIN


class AuthService:
    """사용자 인증 및 세션 관리를 담당하는 서비스 클래스입니다.

    아이디/비밀번호 검증, IP 기반 로그인 시도 제한(Rate Limiting), 
    비밀번호 오류 횟수에 따른 계정 잠금 정책 등을 중앙에서 관리합니다.
    """

    @staticmethod
    async def authenticate_user(
        db: AsyncSession,
        login_in: LoginRequest,
        ip: str,
        user_agent: str = "unknown",
    ) -> User:
        """사용자의 자격 증명(ID/PW)을 검증하고 인증 여부를 결정합니다.

        이 메서드는 다음 보안 로직을 순차적으로 수행합니다:
        1. Redis를 이용한 IP별 로그인 시도 횟수 제한 (분당 10회).
        2. 비밀번호 해시 비교를 통한 본인 확인.
        3. 비밀번호 5회 실패 시 계정 잠금 상태 확인.
        4. 성공 시 실패 카운트 초기화 및 감사 로그 기록.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            login_in (LoginRequest): 로그인 요청 정보 (login_id, password)
            ip (str): 접속 클라이언트의 공인 IP 주소
            user_agent (str, optional): 접속 브라우저/기기 정보. 기본값은 "unknown".

        Returns:
            User: 인증에 성공한 사용자 모델 객체

        Raises:
            RateLimitException: 짧은 시간 내 너무 많은 로그인 시도가 감지될 때 발생
            UnauthorizedException: 아이디가 없거나 비밀번호가 일치하지 않을 때 발생
            ForbiddenException: 계정이 잠겼거나(LOCKED) 비활성화(DISABLED)된 상태일 때 발생
        """
        # 1. IP 기반 로그인 시도 횟수 제한 (Rate Limiting)
        rate_key = f"rate_limit:login:{ip}"
        count = await redis_client.get(rate_key)
        if count and int(count) >= 10:  # 분당 10회 제한
            raise RateLimitException(
                domain=DOMAIN, error_code=ErrorCode.TOO_MANY_REQUESTS
            )

        await redis_client.incr(rate_key)
        if not count:
            await redis_client.expire(rate_key, 60)

        # 2. 사용자 조회
        user = await UserService.get_user_by_login_id(db, login_id=login_in.login_id)

        # 3. 비밀번호 검증 및 실패 카운트 처리
        if not user or not verify_password(login_in.password, user.password_hash):
            if user:
                user.login_fail_count += 1
                await db.commit()
            raise UnauthorizedException(domain=DOMAIN, error_code=ErrorCode.AUTH_FAILED)

        # 4. 계정 잠금 상태 확인
        if user.login_fail_count >= 5:
            raise ForbiddenException(domain=DOMAIN, error_code=ErrorCode.ACCOUNT_LOCKED)

        if not user.is_active:
            raise ForbiddenException(
                domain=DOMAIN, error_code=ErrorCode.ACCOUNT_DISABLED
            )

        # 5. 로그인 성공 처리
        user.login_fail_count = 0
        user.last_login_at = datetime.now()

        # 6. 감사 로그(Audit Log) 기록
        await AuditLogService.create_audit_log(
            db,
            AuditLogCreate(
                action_type="LOGIN",
                target_domain="IAM",
                target_table="users",
                target_id=str(user.id),
                actor_user_id=user.id,
                client_ip=ip,
                user_agent=user_agent,
                description=f"사용자 '{user.login_id}' 로그인 성공",
            ),
        )

        await db.commit()
        return user


class RoleService:
    """시스템 역할(Role) 및 권한 매트릭스를 관리하는 서비스 클래스입니다.

    역할의 생성, 수정, 삭제(CRUD)와 시스템 필수 역할(SUPER_ADMIN 등)에 대한 
    보호 정책을 관리합니다.
    """

    @staticmethod
    async def get_roles(
        db: AsyncSession,
        keyword: str | None = None,
        page: int = 1,
        size: int = 20,
    ) -> list[Role]:
        """역할 목록을 검색 조건과 페이징에 맞춰 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            keyword (str, optional): 역할 명칭 또는 코드에 포함된 키워드 검색. 기본값은 None.
            page (int, optional): 조회할 페이지 번호 (1부터 시작). 기본값은 1.
            size (int, optional): 페이지당 레코드 수. 기본값은 20.

        Returns:
            list[Role]: 조회된 역할 모델 리스트
        """
        stmt = select(Role)
        if keyword:
            stmt = stmt.where(
                or_(Role.name.ilike(f"%{keyword}%"), Role.code.ilike(f"%{keyword}%"))
            )

        stmt = stmt.order_by(Role.id.asc()).offset((page - 1) * size).limit(size)
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_role(db: AsyncSession, role_id: int) -> Role:
        """특정 역할의 상세 정보를 ID로 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            role_id (int): 역할의 고유 ID

        Returns:
            Role: 조회된 역할 모델 객체

        Raises:
            NotFoundException: 해당 ID를 가진 역할이 데이터베이스에 없을 때 발생
        """
        role = await db.get(Role, role_id)
        if not role:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return role

    @staticmethod
    async def create_role(db: AsyncSession, role_in: RoleCreate, actor_id: int) -> Role:
        """새로운 시스템 역할을 정의하고 저장합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            role_in (RoleCreate): 역할 생성 정보 (명칭, 코드, 권한 JSON 등)
            actor_id (int): 생성을 수행하는 관리자 사용자 ID

        Returns:
            Role: 생성된 역할 모델 객체

        Raises:
            ConflictException: 이미 동일한 역할 코드가 등록되어 있을 때 발생
        """
        role_code = role_in.code.upper()

        stmt = select(Role).where(Role.code == role_code)
        existing = await db.execute(stmt)
        if existing.scalar_one_or_none():
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.DUPLICATE_CODE)

        new_role = Role(
            **role_in.model_dump(exclude={"code"}),
            code=role_code,
            created_by=actor_id,
            updated_by=actor_id,
        )
        db.add(new_role)
        await db.commit()
        await db.refresh(new_role)
        return new_role

    @staticmethod
    async def update_role(
        db: AsyncSession, role_id: int, role_in: RoleUpdate, actor_id: int
    ) -> Role:
        """기존 역할 정보를 수정합니다.

        시스템 필수 역할(`is_system=True`)의 경우 코드 변경이 차단되며, 
        명칭과 권한 매트릭스만 수정할 수 있도록 보호 정책이 적용됩니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            role_id (int): 수정할 대상 역할 ID
            role_in (RoleUpdate): 업데이트할 필드 정보
            actor_id (int): 수정을 수행하는 관리자 사용자 ID

        Returns:
            Role: 수정 완료된 역할 모델 객체
        """
        role = await RoleService.get_role(db, role_id)
        update_data = role_in.model_dump(exclude_unset=True)

        if role.is_system:
            # 시스템 역할은 명칭과 권한 매트릭스만 수정 허용
            update_data = {
                k: v for k, v in update_data.items() if k in ["name", "permissions"]
            }

        for key, value in update_data.items():
            setattr(role, key, value)

        role.updated_by = actor_id
        await db.commit()
        await db.refresh(role)
        return role

    @staticmethod
    async def delete_role(db: AsyncSession, role_id: int) -> None:
        """특정 역할을 영구 삭제합니다.

        다음의 경우 삭제가 거부됩니다:
        1. 시스템 필수 역할인 경우 (`is_system=True`).
        2. 해당 역할을 보유하고 있는 사용자가 한 명이라도 존재하는 경우.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            role_id (int): 삭제할 역할 고유 ID

        Raises:
            ConflictException: 시스템 역할이거나 리소스가 사용 중인 경우 발생
        """
        role = await RoleService.get_role(db, role_id)

        if role.is_system:
            raise ConflictException(
                domain=DOMAIN, error_code=ErrorCode.SYSTEM_RESOURCE_MOD
            )

        usage_stmt = select(func.count(UserRole.user_id)).where(
            UserRole.role_id == role_id
        )
        result = await db.execute(usage_stmt)
        if (result.scalar() or 0) > 0:
            raise ConflictException(domain=DOMAIN, error_code=ErrorCode.RESOURCE_IN_USE)

        await db.delete(role)
        await db.commit()


class UserRoleService:
    """사용자와 역할 간의 할당 관계를 관리하는 서비스 클래스입니다.
    
    사용자에게 여러 역할을 부여하거나 제거하는 다대다(M:N) 관계 로직을 처리합니다.
    """

    @staticmethod
    async def assign_roles_to_user(
        db: AsyncSession,
        user_id: int,
        role_ids: list[int],
        actor_id: int,
        ip: str,
        user_agent: str,
    ) -> None:
        """사용자에게 역할을 새로 할당합니다. (기존 관계를 모두 지우고 교체하는 방식).

        이 과정은 'GRANT_ROLE' 타입의 감사 로그로 기록되며, 
        기존에 Redis에 저장된 해당 사용자의 권한 캐시를 자동으로 무효화합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            user_id (int): 대상 사용자의 ID
            role_ids (list[int]): 할당할 신규 역할 ID 리스트
            actor_id (int): 할당 행위를 수행하는 관리자 ID
            ip (str): 요청자 IP 주소 (감사로그용)
            user_agent (str): 요청자 브라우저 정보 (감사로그용)

        Raises:
            NotFoundException: 요청한 역할 ID 중 일부가 유효하지 않을 때 발생
        """
        user = await UserService.get_user(db, user_id)

        # 1. 기존 역할 관계 삭제
        await db.execute(delete(UserRole).where(UserRole.user_id == user_id))

        # 2. 신규 역할 관계 추가
        if role_ids:
            check_stmt = select(Role.id).where(Role.id.in_(role_ids))
            result = await db.execute(check_stmt)
            valid_ids = result.scalars().all()

            if len(valid_ids) != len(set(role_ids)):
                raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

            new_relations = [
                UserRole(user_id=user_id, role_id=rid, assigned_by=actor_id)
                for rid in valid_ids
            ]
            db.add_all(new_relations)

        # 3. 감사 로그 기록
        await AuditLogService.create_audit_log(
            db,
            AuditLogCreate(
                action_type="GRANT_ROLE",
                target_domain="IAM",
                target_table="user_roles",
                target_id=str(user_id),
                actor_user_id=actor_id,
                client_ip=ip,
                user_agent=user_agent,
                snapshot={"assigned_role_ids": role_ids},
                description=f"사용자 {user.name}에게 권한 그룹 {role_ids} 할당",
            ),
        )

        # 4. 권한 캐시 무효화
        await redis_client.delete(f"user_permissions:{user_id}")

        await db.commit()


class PermissionService:
    """프론트엔드 UI 및 메뉴 구성을 위한 권한 리소스 메타데이터 서비스입니다."""

    _RESOURCE_MAP = {
        "USR": {
            "label": "사용자 관리",
            "actions": ["READ", "CREATE", "UPDATE", "DELETE"],
        },
        "FAC": {"label": "시설 관리", "actions": ["READ", "UPDATE_STATUS", "CONTROL"]},
        "ORG": {
            "label": "조직 관리",
            "actions": ["READ", "CREATE", "UPDATE", "DELETE"],
        },
        "IAM": {"label": "권한 관리", "actions": ["READ", "UPDATE_ROLE", "GRANT_ROLE"]},
    }

    @classmethod
    async def get_permission_resources(cls) -> dict[str, Any]:
        """UI에서 권한 설정 매트릭스를 구성하기 위한 리소스별 액션 맵을 반환합니다.

        Returns:
            dict[str, Any]: 리소스 코드를 키로 하는 메타데이터 딕셔너리
        """
        return cls._RESOURCE_MAP
