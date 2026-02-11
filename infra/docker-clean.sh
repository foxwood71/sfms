#!/bin/bash
set -u

docker compose down
docker volume rm $(docker volume ls -q)
docker rmi $(docker images -q)
sudo rm -rf data/pgsql data/pgadm data/gitea/etc data/gitea/data
mkdir -p data/pgsql data/pgadm data/gitea/etc data/gitea/data