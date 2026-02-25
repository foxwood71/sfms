"""CMM 도메인 엔티티 정의 모듈.

PostgreSQL 'cmm' 스키마에 정의된 공통 코드 및 첨부파일
테이블과 매핑되는 SQLAlchemy 모델을 포함합니다.
"""

import uuid
from typing import ClassVar

from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func

from app.core.database import Base  # app.core.database 명칭 사용


class SystemDomain(Base):
    """시스템 도메인 관리 테이블.

    각 비즈니스 도메인(예: FAC-시설, WWT-폐수처리)을 정의하고
    해당 도메인의 스키마와 메타데이터를 관리.

    Attributes:
        domain_code: 도메인 코드 (PK, 3자리, 예: FAC).
        domain_name: 도메인 명칭 (예: 시설관리).
        schema_name: PostgreSQL 스키마명 (예: fac).
        description: 도메인 설명.
        is_active: 활성화 여부.
        created_at: 생성일시.

    """

    __tablename__ = "system_domains"
    __table_args__: ClassVar[dict] = {"schema": "cmm"}

    domain_code = Column(String(3), primary_key=True)
    domain_name = Column(String(50), nullable=False)
    schema_name = Column(String(50), nullable=False)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CodeGroup(Base):
    """코드그룹 마스터 테이블.

    공통 코드 그룹을 관리 (예: 상태코드, 유형코드).
    다국어/다중 도메인 코드 체계를 지원.

    Attributes:
        group_code: 그룹코드 (PK, 예: STATUS).
        group_name: 그룹명 (예: 상태코드).
        description: 그룹 설명.
        is_system: 시스템 기본 코드 여부.
        is_active: 활성화 여부.
        created_at: 생성일시.
        updated_at: 수정일시.

    """

    __tablename__ = "code_groups"
    __table_args__: ClassVar[dict] = {"schema": "cmm"}

    group_code = Column(String(30), primary_key=True)
    group_name = Column(String(100), nullable=False)
    description = Column(Text)
    is_system = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class CodeDetail(Base):
    """공통 코드 상세 정보를 관리하는 모델.

    가변 속성을 저장하기 위한 JSONB props 필드를 포함하며,
    그룹 코드와 상세 코드의 복합 키 구조를 가집니다.

    Attributes:
        group_code (str): 코드 그룹 식별자 (FK).
        detail_code (str): 상세 코드 식별자 (PK).
        detail_name (str): 사용자에게 표시될 코드 명칭.
        props (dict): 코드별 가변 메타데이터 (색상, 아이콘 등).
        sort_order (int): UI 출력 순서.
    """

    __tablename__ = "code_details"
    __table_args__: ClassVar[dict] = {"schema": "cmm"}

    group_code = Column(
        String(30),
        ForeignKey("cmm.code_groups.group_code"),
        primary_key=True,
    )
    detail_code = Column(String(30), primary_key=True)
    detail_name = Column(String(100), nullable=False)
    props = Column(JSONB, server_default="{}")  # 가변 속성 저장용 JSONB
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)


class Attachment(Base):
    """파일 첨부 관리 테이블.

    MinIO S3-compatible 스토리지와 연동된 파일 메타데이터.

    Attributes:
        file_id: UUID 파일 고유ID (PK).
        domain_code: 도메인 코드 (FK).
        ref_id: 연관 데이터 ID (예: FAC-001).
        file_name: 원본 파일명.
        file_path: MinIO 경로.
        file_size: 파일 크기 (bytes).
        content_type: MIME 타입.
        created_at: 업로드일시.

    """

    __tablename__ = "attachments"
    __table_args__: ClassVar[dict] = {"schema": "cmm"}

    file_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    domain_code = Column(String(3), ForeignKey("cmm.system_domains.domain_code"))
    ref_id = Column(String(50))  # 연관된 데이터 ID (예: FAC-001)
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(BigInteger)
    content_type = Column(String(100))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
