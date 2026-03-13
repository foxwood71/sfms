import asyncio
import httpx

BASE_URL = "http://127.0.0.1:8000/api/v1"

async def test_auth_flow():
    async with httpx.AsyncClient() as client:
        # 1. 로그인 시도
        print("--- 1. Login Attempt ---")
        login_data = {
            "login_id": "admin",
            "password": "password123" # 초기 비밀번호 확인 필요
        }
        login_res = await client.post(f"{BASE_URL}/auth/login", json=login_data)
        
        if login_res.status_code != 200:
            print(f"Login Failed: {login_res.status_code}")
            print(login_res.json())
            return

        token_data = login_res.json().get("data", {})
        access_token = token_data.get("access_token")
        print(f"Login Success! Token: {access_token[:20]}...")

        # 2. 내 정보 조회 시도
        print("\n--- 2. Fetch Me Attempt ---")
        headers = {"Authorization": f"Bearer {access_token}"}
        me_res = await client.get(f"{BASE_URL}/auth/me", headers=headers)
        
        print(f"Me Response Status: {me_res.status_code}")
        print(f"Me Response Body: {me_res.json()}")

if __name__ == "__main__":
    asyncio.run(test_auth_flow())
