"""시스템 관리(SYS) 도메인의 비즈니스 로직을 처리하는 서비스 모듈입니다.

이 모듈은 감사 로그(Audit Log) 기록 및 조회, 그리고 문서 번호 자동 채번(Sequence)
규칙 관리 및 발급 로직을 담당합니다.
"""

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.codes import ErrorCode
from app.core.exceptions import NotFoundException
from app.domains.sys.models import AuditLog, SequenceRule
from app.domains.sys.schemas import (
    AuditLogCreate,
    SequenceRuleCreate,
    SequenceRuleUpdate,
)

from . import DOMAIN


class AuditLogService:
    """시스템 감사 로그(Audit Log) 관련 비즈니스 로직을 처리하는 서비스 클래스입니다.

    데이터의 생성, 수정, 삭제 이력을 추적하고 사용자 행위를 기록합니다.
    """

    @staticmethod
    async def create_audit_log(db: AsyncSession, obj_in: AuditLogCreate) -> AuditLog:
        """사용자의 행위 및 데이터 변경 스냅샷을 감사 로그로 기록합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (AuditLogCreate): 감사 로그 생성 정보 (대상 도메인, 테이블, 액션, 스냅샷 등)

        Returns:
            AuditLog: 생성된 감사 로그 SQLAlchemy 모델 객체

        """
        db_obj = AuditLog(**obj_in.model_dump())
        db.add(db_obj)
        await db.flush()
        return db_obj

    @staticmethod
    async def list_audit_logs(
        db: AsyncSession,
        skip: int = 0,
        limit: int = 100,
        target_domain: str | None = None,
        action_type: str | None = None,
    ) -> list[AuditLog]:
        """감사 로그 목록을 검색 및 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            skip (int, optional): 건너뛸 레코드 수. 기본값은 0.
            limit (int, optional): 최대 조회 레코드 수. 기본값은 100.
            target_domain (str | None, optional): 특정 업무 도메인(예: 'FAC') 필터. 기본값은 None.
            action_type (str | None, optional): 행위 유형(예: 'CREATE') 필터. 기본값은 None.

        Returns:
            list[AuditLog]: 조회된 감사 로그 모델 리스트

        """
        stmt = (
            select(AuditLog)
            .order_by(AuditLog.created_at.desc())
            .offset(skip)
            .limit(limit)
        )
        if target_domain:
            stmt = stmt.where(AuditLog.target_domain == target_domain)
        if action_type:
            stmt = stmt.where(AuditLog.action_type == action_type)

        result = await db.execute(stmt)
        return list(result.scalars().all())


class SequenceRuleService:
    """도메인별 문서 번호 자동 채번 규칙을 관리하고 실시간 번호를 발급하는 서비스 클래스입니다.

    시설물 코드, 작업 지시서 번호 등 시스템 전반의 고유 식별자 생성 로직을 중앙 관리합니다.
    """

    @staticmethod
    async def list_rules(db: AsyncSession) -> list[SequenceRule]:
        """등록된 모든 채번 규칙 목록을 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션

        Returns:
            list[SequenceRule]: 채번 규칙 모델 리스트

        """
        result = await db.execute(
            select(SequenceRule).order_by(SequenceRule.domain_code, SequenceRule.prefix)
        )
        return list(result.scalars().all())

    @staticmethod
    async def get_rule(db: AsyncSession, rule_id: int) -> SequenceRule:
        """특정 채번 규칙 정보를 ID로 단건 조회합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            rule_id (int): 조회할 규칙의 고유 ID

        Returns:
            SequenceRule: 조회된 규칙 모델 객체

        Raises:
            NotFoundException: 요청한 규칙 ID가 데이터베이스에 존재하지 않을 때 발생

        """
        rule = await db.get(SequenceRule, rule_id)
        if not rule:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)
        return rule

    @staticmethod
    async def create_rule(
        db: AsyncSession, obj_in: SequenceRuleCreate, actor_id: int
    ) -> SequenceRule:
        """새로운 채번 규칙을 생성합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            obj_in (SequenceRuleCreate): 신규 규칙 설정 정보
            actor_id (int): 생성 행위를 수행하는 사용자 ID

        Returns:
            SequenceRule: 생성된 채번 규칙 모델 객체

        """
        db_obj = SequenceRule(
            **obj_in.model_dump(), created_by=actor_id, updated_by=actor_id
        )
        db.add(db_obj)
        await db.commit()
        await db.refresh(db_obj)
        return db_obj

    @staticmethod
    async def update_rule(
        db: AsyncSession, rule_id: int, obj_in: SequenceRuleUpdate, actor_id: int
    ) -> SequenceRule:
        """기존 채번 규칙의 속성(구분자, 자릿수 등)을 수정합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            rule_id (int): 수정할 대상 규칙 ID
            obj_in (SequenceRuleUpdate): 변경할 필드 정보
            actor_id (int): 수정 행위를 수행하는 사용자 ID

        Returns:
            SequenceRule: 수정 완료된 규칙 모델 객체

        """
        rule = await SequenceRuleService.get_rule(db, rule_id)
        update_data = obj_in.model_dump(exclude_unset=True)

        for field, value in update_data.items():
            setattr(rule, field, value)

        rule.updated_by = actor_id
        await db.commit()
        await db.refresh(rule)
        return rule

    @staticmethod
    async def delete_rule(db: AsyncSession, rule_id: int) -> None:
        """특정 채번 규칙을 물리적으로 삭제합니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            rule_id (int): 삭제할 규칙의 ID

        """
        rule = await SequenceRuleService.get_rule(db, rule_id)
        await db.delete(rule)
        await db.commit()

    @staticmethod
    async def get_next_sequence(db: AsyncSession, domain_code: str, prefix: str) -> str:
        """도메인 코드와 접두어를 기반으로 고유한 다음 문서 번호를 발급합니다.

        이 메서드는 다중 서버 환경에서의 중복 발급을 방지하기 위해 SELECT ... FOR UPDATE를
        통한 비관적 락(Pessimistic Locking)을 사용하여 원자적(Atomic)으로 순번을 증가시킵니다.
        연도별 초기화(YEARLY) 방식이 설정된 경우, 연도가 바뀌면 순번이 1로 자동 리셋됩니다.

        Args:
            db (AsyncSession): 데이터베이스 비동기 세션
            domain_code (str): 도메인 식별 코드 (예: 'FAC', 'CMM')
            prefix (str): 문서 종류 접두어 (예: 'WO', 'REQ')

        Returns:
            str: 규칙에 따라 포맷팅된 최종 문서 번호 (예: 'WO-2026-0001')

        Raises:
            NotFoundException: 활성화된 해당 도메인/접두어 규칙이 존재하지 않을 때 발생

        """
        stmt = (
            select(SequenceRule)
            .where(
                SequenceRule.domain_code == domain_code,
                SequenceRule.prefix == prefix,
                SequenceRule.is_active,
            )
            .with_for_update()
        )  # 동시성 제어를 위한 행 잠금 (락 획득까지 대기)

        result = await db.execute(stmt)
        rule = result.scalar_one_or_none()

        if not rule:
            raise NotFoundException(domain=DOMAIN, error_code=ErrorCode.NOT_FOUND)

        current_year = datetime.now().strftime("%Y")

        # 번호 초기화 로직 (연도별 리셋 여부 확인)
        new_seq = 1
        if rule.reset_type == "YEARLY" and rule.current_year != current_year:
            new_seq = 1
        else:
            new_seq = rule.current_seq + 1

        rule.current_seq = new_seq
        rule.current_year = current_year

        await db.commit()
        await db.refresh(rule)

        # 결과 문자열 조립
        formatted_year = (
            current_year if rule.year_format == "YYYY" else current_year[2:]
        )
        seq_part = str(new_seq).zfill(rule.padding_length)

        parts = [rule.prefix]
        if formatted_year:
            parts.append(formatted_year)
        parts.append(seq_part)

        return rule.separator.join(parts)
