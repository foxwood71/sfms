#!/bin/bash
set -u

# 1. 컨테이너 및 네트워크 종료
podman-compose -f compose.dev.yaml down

# 2. 모든 볼륨 일괄 삭제 (SC2046 해결: xargs 사용)
echo "🗑️ 컨테이너 및 네트워크 삭제 중..."
podman volume ls -q | xargs -r podman volume rm  # 볼륨이 없을 때 에러 나는 것을 방지(-r)

# 3. 모든 이미지 일괄 삭제 (SC2046 해결: xargs 사용)
podman images -q | xargs -r podman rmi  # 이미지가 없을 때 에러 나는 것을 방지(-r)

# 4. 마운트된 로컬 데이터 폴더 초기화 (권한 문제 방지를 위해 sudo 유지)\
echo "🗑️ 기존 데이터 폴더 삭제 중..."
podman unshare rm -rf data/pgsql data/pgadm data/gitea/etc data/gitea/data

# 5. 깨끗한 상태로 폴더 다시 생성
echo "📁 폴더 다시 생성 중..."
podman unshare mkdir -p data/pgsql data/pgadm data/gitea/conf data/gitea/data

# 6. 각 서비스별 UID에 맞춰 소유권 즉시 재할당
echo "🔑 소유권 재설정 중..."
# pgsql (999)
podman unshare chown -R 999:999 ./data/pgsql
# pgadm (5050)
podman unshare chown -R 5050:5050 ./data/pgadm
# gitea (1000)
podman unshare chown -R 1000:1000 ./data/gitea

echo "✅ 모든 초기화가 완료되었습니다!"