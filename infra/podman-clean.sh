#!/bin/bash
set -u

# 1. 컨테이너 및 네트워크 종료
podman-compose down

# 2. 모든 볼륨 일괄 삭제 (SC2046 해결: xargs 사용)
podman volume ls -q | xargs -r podman volume rm  # 볼륨이 없을 때 에러 나는 것을 방지(-r)

# 3. 모든 이미지 일괄 삭제 (SC2046 해결: xargs 사용)
podman images -q | xargs -r podman rmi  # 이미지가 없을 때 에러 나는 것을 방지(-r)

# 4. 마운트된 로컬 데이터 폴더 초기화 (권한 문제 방지를 위해 sudo 유지)
sudo rm -rf data/pgsql data/pgadm data/gitea/etc data/gitea/data

# 5. 깨끗한 상태로 폴더 다시 생성
mkdir -p data/pgsql data/pgadm data/gitea/etc data/gitea/data