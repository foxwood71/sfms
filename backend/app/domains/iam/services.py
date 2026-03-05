"""인증 및 권한(IAM) 도메인의 비즈니스 로직(Service)을 담당하는 모듈입니다."""

import uuid
from datetime import datetime
from typing import List, Optional

from sqlalchemy import delete, func, or_, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.cache import redis_client  # Rate Limiting용
from app.core.constants import ErrorCode
from app.core.exceptions import (
    AccountLockedException,
    BadRequestException,
    ConflictException,
    CustomException,
    NotFoundException,
    UnauthorizedException,
)
from app.core.security import verify_password
from app.domains.cmm.schemas import AuditLogCreate
from app.domains.cmm.services import AuditLogService
from app.domains.iam.models import Role, UserRole  # UserRole 모델 필요
from app.domains.iam.schemas import LoginRequest, RoleCreate, RoleRead, RoleUpdate
from app.domains.usr.models import User
from app.domains.usr.services import UserService


class AuthService:
    """인증 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def authenticate_user(
        db: AsyncSession, login_in: LoginRequest, ip: str, user_agent: str = "unknown"
    ) -> User:
        """
        사용자 자격 증명을 검증하고 로그인 프로세스를 처리합니다.

        계정 잠금 확인, 비밀번호 검증, 감사 로그 기록 등을 수행합니다.  # Ruff D102 해결
        """
        # 1. Rate Limiting (IP당 분당 5회)
        rate_key = f"rate_limit:login:{ip}"
        count = await redis_client.get(rate_key)
        if count and int(count) >= 5:
            raise CustomException(
                error_code=ErrorCode.TOO_MANY_REQUESTS,
                message="로그인 시도 횟수 초과 (IP 차단)",
            )
        await redis_client.incr(rate_key)
        if not count:
            await redis_client.expire(rate_key, 60)

        # 2. 사용자 조회 및 비번 검증
        user = await UserService.get_user_by_login_id(db, login_id=login_in.login_id)
        if not user or not verify_password(login_in.password, user.password_hash):
            if user:
                user.login_fail_count += 1
                await db.commit()
            raise CustomException(
                error_code=ErrorCode.AUTH_FAILED,
                message="아이디 또는 비밀번호가 일치하지 않습니다.",
            )

        # 3. 잠금 확인 (5회 실패 시)
        if user.login_fail_count >= 5:
            raise AccountLockedException()

        # 4. 성공 시 처리
        user.login_fail_count = 0
        user.last_login_at = datetime.now()

        # 5. Audit Log 기록
        await AuditLogService.create_audit_log(
            db,
            AuditLogCreate(
                trace_id=uuid.uuid4(),
                target_domain="IAM",
                target_id=str(user.id),
                action="LOGIN",
                ip_address=ip,
                actor_id=user.id,
                user_agent=user_agent,
                snapshot={"login_id": login_in.login_id},
            ),
        )

        await db.commit()
        return user


class RoleService:
    """역할(Role) 및 권한 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def get_roles(
        db: AsyncSession, keyword: Optional[str] = None, page: int = 1, size: int = 20
    ) -> List[Role]:
        """명세서 3.1: 역할 목록 조회 (검색 및 페이징)"""
        stmt = select(Role)

        # 이름 또는 코드로 검색
        if keyword:
            stmt = stmt.where(
                or_(Role.name.ilike(f"%{keyword}%"), Role.code.ilike(f"%{keyword}%"))
            )

        # 페이징 처리
        stmt = stmt.order_by(Role.id.asc()).offset((page - 1) * size).limit(size)
        result = await db.execute(stmt)
        return list(result.scalars().all())

    @staticmethod
    async def get_role(db: AsyncSession, role_id: int) -> Role:
        """
        명세서 3.2: 특정 역할의 상세 정보를 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 세션
            role_id (int): 조회할 역할의 고유 ID

        Returns:
            Role: 조회된 역할 객체

        Raises:
            NotFoundException: 해당 ID의 역할이 존재하지 않을 경우
        """
        role = await db.get(Role, role_id)
        if not role:
            raise NotFoundException(message="해당 역할을 찾을 수 없습니다.")

        return role

    @staticmethod
    async def create_role(db: AsyncSession, role_in: RoleCreate) -> Role:
        """명세서 3.3: 역할 생성 (대문자 변환 및 중복 체크)"""
        # code 대문자 강제 변환
        role_code = role_in.code.upper()

        # 중복 체크 (에러 코드 4090)
        stmt = select(Role).where(Role.code == role_code)
        existing = await db.execute(stmt)
        if existing.scalar_one_or_none():
            raise CustomException(
                error_code=4090, message="이미 존재하는 역할 코드입니다."
            )

        new_role = Role(**role_in.model_dump(exclude={"code"}), code=role_code)
        db.add(new_role)
        await db.commit()
        await db.refresh(new_role)
        return new_role

    @staticmethod
    async def update_role(db: AsyncSession, role_id: int, role_in: RoleUpdate) -> Role:
        """명세서 3.4: 역할 수정 (시스템 역할 보호)"""
        role = await db.get(Role, role_id)
        if not role:
            raise NotFoundException(message="역할을 찾을 수 없습니다.")

        # 시스템 역할(is_system=true) 제약 조건
        update_data = role_in.model_dump(exclude_unset=True)
        if role.is_system:
            # 시스템 역할은 name과 permissions만 수정 가능하도록 제한
            update_data = {
                k: v for k, v in update_data.items() if k in ["name", "permissions"]
            }

        for key, value in update_data.items():
            setattr(role, key, value)

        await db.commit()
        await db.refresh(role)
        return role

    @staticmethod
    async def delete_role(db: AsyncSession, role_id: int) -> None:
        """명세서 3.5: 역할 삭제 (삭제 방어 로직)"""
        role = await db.get(Role, role_id)
        if not role:
            raise NotFoundException(message="역할을 찾을 수 없습니다.")

        # 1. 시스템 역할 삭제 불가 (에러 코드 4092)
        if role.is_system:
            raise CustomException(
                error_code=4092, message="시스템 기본 역할은 삭제할 수 없습니다."
            )

        # 2. 사용 중인 역할 삭제 불가 (에러 코드 4091)
        usage_stmt = select(func.count(UserRole.user_id)).where(
            UserRole.role_id == role_id
        )
        usage_result = await db.execute(usage_stmt)
        # scalar() 결과가 None일 경우 0으로 취급하도록 'or 0' 추가
        usage_count = usage_result.scalar() or 0

        if usage_count > 0:
            raise CustomException(
                error_code=4091, message="사용 중인 역할은 삭제할 수 없습니다."
            )

        await db.delete(role)
        await db.commit()


class UserRoleService:
    """사용자-역할(User-Role) 매핑 관련 비즈니스 로직을 처리하는 서비스 클래스입니다."""

    @staticmethod
    async def assign_roles_to_user(
        db: AsyncSession,
        user_id: int,
        role_ids: List[int],
        actor_id: int,  # 누가 수행했는지 (Audit용)
        ip: str,  # 어디서 접속했는지 (Audit용)
        user_agent: str,  # 어떤 브라우저에서 접속했는지 (Audit용)
    ) -> None:
        """
        명세서 4.1: 사용자의 역할을 부여 (Full Replace)
        """
        # 0. 사용자 존재 확인
        user = await db.get(User, user_id)
        if not user:
            raise NotFoundException(message="해당 사용자를 찾을 수 없습니다.")

        # 1. 기존 역할 모두 삭제 (DELETE)
        delete_stmt = delete(UserRole).where(UserRole.user_id == user_id)
        await db.execute(delete_stmt)

        # 2. 새로운 역할 목록 검증 및 추가 (INSERT)
        if role_ids:
            # 전달받은 role_id들이 실제로 존재하는지 검증
            check_stmt = select(Role.id).where(Role.id.in_(role_ids))
            result = await db.execute(check_stmt)
            valid_role_ids = result.scalars().all()

            if len(valid_role_ids) != len(set(role_ids)):
                raise NotFoundException(message="일부 역할을 찾을 수 없습니다.")

            # 매핑 객체 일괄 생성
            new_user_roles = [
                UserRole(user_id=user_id, role_id=r_id) for r_id in valid_role_ids
            ]
            db.add_all(new_user_roles)

        # 3. Audit Log 기록 (명세서 4.1 요구사항)
        await AuditLogService.create_audit_log(
            db,
            AuditLogCreate(
                trace_id=uuid.uuid4(),
                target_domain="IAM",
                target_id=str(user_id),
                action="GRANT_ROLE",
                ip_address=ip,
                user_agent=user_agent,
                actor_id=actor_id,
                snapshot={"role_ids": role_ids},  # 변경된 역할 ID 목록 저장
            ),
        )

        # 4. Cache Invalidation (권한 즉시 반영을 위한 장치)
        # 명세서: 중요한 변경인 경우 사용자의 Refresh Token을 만료시키거나 권한 캐시를 삭제
        await redis_client.delete(
            f"user_permissions:{user_id}"
        )  # 예시: 권한 캐시 키 삭제

        await db.commit()
