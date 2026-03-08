import asyncio
import bcrypt
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.domains.usr.models import User
from app.domains.iam.models import Role, UserRole
import app.domains.iam.models  # noqa

def manual_hash(password: str) -> str:
    """bcrypt 라이브러리를 직접 사용하여 해싱합니다."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')

async def create_admin():
    async with AsyncSessionLocal() as session:
        try:
            # 1. SUPER_ADMIN 역할 존재 확인 및 생성
            result = await session.execute(select(Role).where(Role.code == "SUPER_ADMIN"))
            admin_role = result.scalar_one_or_none()
            
            if not admin_role:
                print("Creating SUPER_ADMIN role...")
                admin_role = Role(
                    name="슈퍼 관리자",
                    code="SUPER_ADMIN",
                    description="시스템 전체 권한",
                    is_system=True,
                    permissions={"ALL": ["*"]}
                )
                session.add(admin_role)
                await session.flush()

            # 2. admin 계정 확인 및 생성/업데이트
            result = await session.execute(select(User).where(User.login_id == "admin"))
            user = result.scalar_one_or_none()
            
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
                    org_id=None
                )
                session.add(user)
                await session.flush()
            
            # 3. 역할 할당 확인
            result = await session.execute(
                select(UserRole).where(UserRole.user_id == user.id, UserRole.role_id == admin_role.id)
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
