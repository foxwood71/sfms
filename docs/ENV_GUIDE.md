# 🔐 SFMS 환경 설정 및 패스워드 가이드 (개발용)

본 문서는 SFMS 개발 및 인프라 구축에 사용되는 실제 설정값과 비밀번호를 정리합니다.

---

## 📂 1. 서비스별 접속 및 인증 정보

| 서비스 | 호스트/포트 (로컬) | 사용자 계정 (ID) | 비밀번호 (Password) | 용도 |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `localhost:5432` | `sfms_usr` | `pgpass` | 메인 데이터베이스 |
| **Redis** | `localhost:6379` | `default` | `rdpass` | 캐시 및 세션 서버 |
| **MinIO Console** | `localhost:9001` | `sfms_usr` | `miniopass` | 오브젝트 스토리지 관리 |
| **MinIO API (S3)** | `localhost:9000` | `sfms_usr` | `miniopass` | 파일 업로드/다운로드 API |
| **pgAdmin** | `localhost:5050` | `admin@sfms.com` | `pgpass` | DB GUI 관리 도구 |
| **Gitea** | `localhost:3300` | `admin` | `pgpass` | 로컬 소스 저장소 |
| **Portainer** | `localhost:9443` | `admin` | `ptpass` | 컨테이너 관리 도구 |
| **Nginx** | `localhost:80/443` | - | `ngpass` | 리버스 프록시 인증 (필요시) |

---

## 📂 2. 백엔드 설정 상세 (`backend/.env`)

*   `DATABASE_URL`: `postgresql+asyncpg://sfms_usr:pgpass@localhost:5432/sfms_db`
*   `REDIS_URL`: `redis://:rdpass@localhost:6379/0`
*   `S3_ENDPOINT`: `http://localhost:9000`
*   `MINIO_ACCESS_KEY`: `sfms_usr`
*   `MINIO_SECRET_KEY`: `miniopass`

---

## 📂 3. 비밀번호 파일 위치 (Secrets)

보안 로직에 의해 아래 파일들이 컨테이너 구동 시 비밀번호 소스로 사용됩니다.

*   `backend/secrets/password.txt`: `bepass`
*   `infra/pgsql/secrets/password.txt`: `pgpass`
*   `infra/redis/secrets/password.txt`: `rdpass`
*   `infra/minio/secrets/password.txt`: `miniopass`
*   `infra/portainer/secrets/password.txt`: `ptpass`
*   `infra/nginx/secrets/password.txt`: `ngpass`

---

## 📂 4. 테스트 계정 정보

백엔드 테스트 및 초기 로그인 시 사용하는 기본 계정입니다.

*   **관리자 (Admin)**: `admin` / `admin1234`
*   **일반 사용자**: `user1` / `password123`

---

## 🛡️ 주의사항
1.  본 패스워드들은 **개발용(Local/Dev)** 환경을 위한 기본값입니다.
2.  운영(Prod) 환경 배포 시에는 반드시 모든 패스워드를 강력한 문자열로 변경하고 이 문서를 폐기해야 합니다.
3.  인프라 재구축 시 `setup-infra.sh`를 통해 위 비밀번호들이 각 `secrets/*.txt` 파일에 자동 할당됩니다.

---
최종 갱신일: 2026-03-08
