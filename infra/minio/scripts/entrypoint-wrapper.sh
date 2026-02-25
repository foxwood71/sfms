#!/bin/bash
# MinIO는 bash를 지원하므로 pipefail을 안전하게 사용할 수 있습니다.
# -e: (에러 발생 시 종료)
# -u: (미정의 변수 사용 시 에러)
# -o pipefail: (파이프라인 에러 감지)

set -euo pipefail

echo "<minio Wrapper Script 시작...>"

# 1. 비밀번호 시크릿 존재 여부 점검
# MinIO는 compose 파일의 MINIO_ROOT_PASSWORD_FILE 변수를 통해 
# 도커가 알아서 비밀번호를 읽어가므로, 여기서는 파일 유무만 안전하게 체크합니다.
if [ -f "/run/secrets/minio-password" ]; then
    echo "✅ [Security] 비밀번호 시크릿 파일이 정상적으로 감지되었습니다."
else
    echo "⚠️ [Warning] 비밀번호 시크릿 파일이 없습니다! 접속 에러가 발생할 수 있습니다."
fi

# 2. 인증서 스마트 적용 및 SSL 자동 활성화 (조건부)
echo "🔍 [Security] MinIO SSL 인증서 점검 중..."
CERT_DIR="/certs"

if [ -f "/run/secrets/minio-key" ] && [ -f "/run/secrets/minio-cert" ]; then
    echo "✅ SSL 인증서 발견! 복사 및 권한 설정, TLS 활성화를 진행합니다."
    
    # 인증서 폴더 준비 (MinIO는 기본적으로 root(0) 유저를 사용합니다)
    mkdir -p "$CERT_DIR/CAs"
    chown -R 0:0 "$CERT_DIR"
    chmod 700 "$CERT_DIR"

    # 키 파일 복사 및 이름 변경 (MinIO 고정 규칙)
    cp /run/secrets/minio-key "$CERT_DIR/private.key"
    chown 0:0 "$CERT_DIR/private.key"
    chmod 0600 "$CERT_DIR/private.key"

    # 인증서 파일 복사 및 이름 변경 (MinIO 고정 규칙)
    cp /run/secrets/minio-cert "$CERT_DIR/public.crt"
    chown 0:0 "$CERT_DIR/public.crt"
    chmod 0644 "$CERT_DIR/public.crt"

    echo "<minio TLS(SSL) 설정 적용 및 서버 실행...>"
    # 컴포즈에서 넘겨준 명령어($@) 뒤에 --certs-dir 옵션을 알아서 덧붙여서 실행!
    exec minio "$@" --certs-dir "$CERT_DIR"
else
    echo "⚠️ SSL 인증서 없음! 개발 모드로 판단하여 인증서 복사 및 TLS 설정을 스킵합니다."
    echo "<minio 일반(HTTP) 서버 실행...>"
    
    # 인증서가 없으면 기본 명령어만 실행
    exec minio "$@"
fi