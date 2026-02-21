infra/
├── .env                 # 모든 인프라 비밀번호 마스터 키
├── compose.yaml         # 인프라 설계도
├── gitea/               # Git 서버 설정 및 데이터
├── nginx/               # 리버스 프록시 설정 및 SSL 인증서
│   └── conf.d/          # default.conf 등 세부 설정
├── pgadm/               # pgAdmin 관리 설정
├── pgsql/               # DB 초기화 스크립트 (init.sql)
├── redis/               # Redis 설정 파일
├── minio/               # 오브젝트 스토리지 관련 설정
├──portainer/            # 컨테이너 관리 도구
└── data/
    ├──pgsql/            # DB의 실제 데이터 파일 저장
    ├──redis/            # 캐시 데이터 저장 (설정 시 필요)
    ├──minio/            # 업로드한 이미지, 도면 파일 저장
    ├──pgadm/            # 관리자 계정 설정 및 기록 저장
    ├──gitea/            # Git 레포지토리 및 환경 설정 저장
    ├──portainer/        # 컨테이너 관리 도구 데이터 저장
    └── logs/            
        ├── nginx/       # Nginx 서버 로그 저장 
        └── backend/     # FastAPI 서버 로그 저장

```bash
# infra 폴더 안에서 실행하세요!
mkdir -p data/pgsql \
         data/redis \
         data/minio \
         data/pgadm \
         data/gitea \
         data/portainer \
         data/logs/nginx \
         data/logs/backend
```