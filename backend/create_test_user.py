"""시스템 초기화를 위한 관리자 계정 생성 및 업데이트 스크립트입니다.

이 모듈은 데이터베이스에 'SUPER_ADMIN' 역할을 등록하고, 해당 권한을 가진
최상위 관리자 계정(admin)을 생성하거나 비밀번호를 초기화하는 기능을 제공합니다.
서비스 구축 초기 단계나 테스트 환경 구성 시 필수적으로 실행되어야 합니다.
"""

import asyncio

import bcrypt
from sqlalchemy import select

import app.domains.iam.models  # noqa
from app.core.database import AsyncSessionLocal
from app.domains.iam.models import Role, UserRole
from app.domains.usr.models import User


def manual_hash(password: str) -> str:
    """Bcrypt 라이브러리를 직접 사용하여 비밀번호를 해싱합니다.

    보안 강화를 위해 솔트(Salt)를 생성하고 비밀번호를 안전하게 암호화합니다.

    Args:
        password (str): 암호화할 평문 비밀번호

    Returns:
        str: 해싱 처리된 비밀번호 문자열

    """
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode("utf-8"), salt)
    return hashed.decode("utf-8")


async def create_admin():
    """최상위 관리자(SUPER_ADMIN) 역할과 계정을 생성하거나 업데이트합니다.

    1. 'SUPER_ADMIN' 역할이 없는 경우 새로 생성합니다.
    2. 'admin' 아이디를 가진 사용자가 없는 경우 생성하고, 있는 경우 비밀번호와 상태를 초기화합니다.
    3. 생성된 사용자에게 'SUPER_ADMIN' 역할을 할당합니다.

    Raises:
        Exception: 데이터베이스 처리 중 오류 발생 시 롤백 후 에러 내용을 출력합니다.

    """
    async with AsyncSessionLocal() as session:
        try:
            # 1. SUPER_ADMIN 역할 존재 확인 및 생성
            result = await session.execute(
                select(Role).where(Role.code == "SUPER_ADMIN")
            )
            admin_role = result.scalar_one_or_none()

            if not admin_role:
                print("Creating SUPER_ADMIN role...")
                admin_role = Role(
                    name="슈퍼 관리자",
                    code="SUPER_ADMIN",
                    description="시스템 전체 권한",
                    is_system=True,
                    permissions={"ALL": ["*"]},
                )
                session.add(admin_role)
                await session.flush()

            # 2. admin 계정 확인 및 생성/업데이트
            result = await session.execute(select(User).where(User.login_id == "admin"))
            user = result.scalar_one_or_none()

            # 기본 초기 비밀번호: admin1234
            pwd_hash = manual_hash("admin1234")

            if user:
                print("Admin user already exists. Updating...")
                user.password_hash = pwd_hash
                user.email = "admin@example.com"
                user.is_active = True
            else:
                print("Creating new admin user...")
                user = User(
                    login_id="admin",
                    password_hash=pwd_hash,
                    name="관리자",
                    emp_code="ADMIN001",
                    email="admin@example.com",
                    is_active=True,
                    org_id=None,
                )
                session.add(user)
                await session.flush()

            # 3. 역할 할당 확인
            result = await session.execute(
                select(UserRole).where(
                    UserRole.user_id == user.id, UserRole.role_id == admin_role.id
                )
            )
            if not result.scalar_one_or_none():
                print("Assigning SUPER_ADMIN role to admin user...")
                user_role = UserRole(user_id=user.id, role_id=admin_role.id)
                session.add(user_role)

            await session.commit()
            print("SUCCESS: Admin account with SUPER_ADMIN role is ready.")
        except Exception as e:
            print(f"ERROR: {e}")
            await session.rollback()


if __name__ == "__main__":
    asyncio.run(create_admin())
