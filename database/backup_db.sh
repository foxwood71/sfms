#!/bin/bash

# SFMS Database 전체 백업 스크립트 (Container 기반)
# 호스트에 pg_dump가 설치되어 있지 않아도 컨테이너 내부 툴을 사용해 안전하게 백업합니다.

# 1. 설정 정보 로드 (.env 파일에서 추출)
ENV_FILE="backend/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: .env file not found in backend directory."
    exit 1
fi

# DATABASE_URL 추출
DB_URL=$(grep DATABASE_URL "$ENV_FILE" | cut -d '=' -f2)
DB_USER=$(echo $DB_URL | sed -e 's|.*//\(.*\):.*@.*|\1|')
DB_PASS=$(echo $DB_URL | sed -e 's|.*//.*:\(.*\)@.*|\1|')
DB_NAME=$(echo $DB_URL | sed -e 's|.*/\(.*\)|\1|')

# 2. 백업 파일명 설정
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="database/backups"
mkdir -p "$BACKUP_DIR"
BACKUP_FILE="$BACKUP_DIR/sfms_full_backup_$DATE.sql"

# 3. 컨테이너 이름 확인
DOCKER_BIN=$(which podman || echo "docker")
# 'pgsql' 이라는 단어가 포함된 실행 중인 컨테이너 찾기
CONTAINER_NAME=$($DOCKER_BIN ps --format "{{.Names}}" | grep "pgsql" | head -n 1)

if [ -z "$CONTAINER_NAME" ]; then
    echo "❌ ERROR: PostgreSQL container (with 'pgsql' in name) is not running."
    exit 1
fi

echo "--------------------------------------------------"
echo "🚀 SFMS Database Backup Starting..."
echo "📅 Date: $DATE"
echo "📦 Container: $CONTAINER_NAME"
echo "🗄️ Target DB: $DB_NAME"
echo "--------------------------------------------------"

# 4. 컨테이너 내부에서 pg_dump 실행
$DOCKER_BIN exec -e PGPASSWORD="$DB_PASS" "$CONTAINER_NAME" \
    pg_dump -U "$DB_USER" --clean --if-exists --no-owner --no-privileges "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    echo "✅ SUCCESS: Backup completed!"
    echo "📂 File Path: $BACKUP_FILE"
    echo "💾 File Size: $(du -h $BACKUP_FILE | cut -f1)"
    echo ""
    echo "💡 How to Restore in another environment:"
    echo "   # 1. Start your pgsql container"
    echo "   # 2. Run this command (replace bracketed values):"
    echo "   cat $BACKUP_FILE | $DOCKER_BIN exec -i <New_Container_Name> psql -U <User> -d <DB_Name>"
else
    echo "❌ ERROR: Backup failed."
    rm -f "$BACKUP_FILE"
    exit 1
fi
