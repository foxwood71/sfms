import uuid
from sqlalchemy import Column, String, Boolean, Integer, ForeignKey, DateTime, Text, BigInteger
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.sql import func
from app.core.database import Base  # app.core.database 명칭 사용


class SystemDomain(Base):
    __tablename__ = "system_domains"
    __table_args__ = {"schema": "cmm"}

    domain_code = Column(String(3), primary_key=True)
    domain_name = Column(String(50), nullable=False)
    schema_name = Column(String(50), nullable=False)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())


class CodeGroup(Base):
    __tablename__ = "code_groups"
    __table_args__ = {"schema": "cmm"}

    group_code = Column(String(30), primary_key=True)
    group_name = Column(String(100), nullable=False)
    description = Column(Text)
    is_system = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class CodeDetail(Base):
    __tablename__ = "code_details"
    __table_args__ = {"schema": "cmm"}

    group_code = Column(String(30), ForeignKey("cmm.code_groups.group_code"), primary_key=True)
    detail_code = Column(String(30), primary_key=True)
    detail_name = Column(String(100), nullable=False)
    props = Column(JSONB, server_default='{}')  # 가변 속성 저장용 JSONB
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)


class Attachment(Base):
    __tablename__ = "attachments"
    __table_args__ = {"schema": "cmm"}

    file_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    domain_code = Column(String(3), ForeignKey("cmm.system_domains.domain_code"))
    ref_id = Column(String(50))  # 연관된 데이터 ID (예: FAC-001)
    file_name = Column(String(255), nullable=False)
    file_path = Column(String(500), nullable=False)
    file_size = Column(BigInteger)
    content_type = Column(String(100))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
