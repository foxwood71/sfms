# ====================================================================
# @docker 한글지원 image 빌드 스크립트 생성 
#   postgresql16을 기준으로 작성
# ====================================================================
# --------------------------------------------------------------------
#  0. 사전작업
# --------------------------------------------------------------------
#  0.1 docker compose 프로젝트 디렉토리 생성
#     $ mkdir -p ~/porjects/gumc && cd ~/porjects/gumc
#     $ mkdir -p vol/pgsql
#     $ mkdir pgsql
#     $ PWD
#       ~/porjects/gumc
#
#  0.2 postgresql 확장 추가 및 설정 변경 shell 스크립트 작성 - pg cron 확장 추가
#     $ touch pgsql/01_set_config.sh
#     $ chmod +x pgsql/01_set_config.sh
#     $ code pgsql/01_set_config.sh   
#    
#  0.3 postgresql database 초기화용 sql 스크립트 작성 
#     $ touch pgsql/02_init.sql 
#     $ code pgsql/02_init.sql    
#
#  0.4 자체 서명 인증서 및 이미지에 사용가능하도록 서명파일 사용자와 사용자 그룹 변경
#     $ openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./pgsql/pgsql.key -out ./pgsql/pgsql.crt -subj "/C=KR/ST=Gyeonggi-do/L=Gwangju-si/O=gumc/CN=pgsql"
#     $ sudo chown 5050:5050 ./pgadm/pgadm.key    // pgadmin4는 5050:5050으로 설정하게 문서화 되어 있음
#     $ sudo chown 5050:5050 ./pgadm/pgadm.crt    // pgadmin4는 5050:5050으로 설정하게 문서화 되어 있음
#
#  0.5 Dockerfile 생성
#     $ touch pgsql/Dockerfile
#     $ code pgsql/Dockerfile
#
# --------------------------------------------------------------------
# Dockerfile

FROM postgres:16-bookworm

#### 환경 변수 설정
ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8
ENV TZ=Asia/Seoul
ENV POSTGRESQL_VERSION=16
ENV PGROONGA_VERSION=4.0.5-1


#### 의존성 및 패키지 설치 (레이어 최적화: RUN 명령어를 하나로 통합)
RUN apt-get update && apt-get install -y -V \
    lsb-release \
    wget \
    locales \
    postgresql-common \
    && sed -i 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen ko_KR.UTF-8 \
    && ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime \
    && wget https://apache.jfrog.io/artifactory/arrow/debian/apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    && apt-get install -y -V ./apache-arrow-apt-source-latest-$(lsb_release --codename --short).deb \
    && wget https://packages.groonga.org/debian/groonga-apt-source-latest-$(lsb_release --codename --short).deb \
    && apt-get install -y -V ./groonga-apt-source-latest-$(lsb_release --codename --short).deb \
    && apt-get update && apt-get install -y -V \
    postgresql-${POSTGRESQL_VERSION}-pgdg-pgroonga=${PGROONGA_VERSION} \
    postgresql-${POSTGRESQL_VERSION}-cron \
    groonga-normalizer-mysql \
    groonga-token-filter-stem \
    groonga-tokenizer-mecab \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* *.deb

#### 설정 파일 및 인증서 복사
# [삭제] 보안을 위해 키와 인증서를 secrets로 관리
# COPY pgsql.key /etc/ssl/certs/server.key --> compose secrets로 변경
# COPY pgsql.crt /etc/ssl/certs/server.crt --> compose secrets로 변경
COPY 00_configure_system.sh /docker-entrypoint-initdb.d/00_configure_system.sh
COPY 10_global_init.sql /docker-entrypoint-initdb.d/10_global_init.sql
COPY 20_app_gitea.sql /docker-entrypoint-initdb.d/20_app_gitea.sql

#### 파일 권한 변경 (PostgreSQL 실행 사용자인 postgres가 소유하도록 변경)
# RUN chown postgres:postgres /etc/ssl/certs/server.key /etc/ssl/certs/server.crt \
#     && chmod 0600 /etc/ssl/certs/server.key \
#     && chmod 0644 /etc/ssl/certs/server.crt \
#     && chown postgres:postgres /docker-entrypoint-initdb.d/01_set_config.sh \
#     && chmod +x /docker-entrypoint-initdb.d/01_set_config.sh \
#     && chown postgres:postgres /docker-entrypoint-initdb.d/02_init.sql

RUN chown postgres:postgres /docker-entrypoint-initdb.d/00_configure_system.sh \
    && chmod +x /docker-entrypoint-initdb.d/00_configure_system.sh \
    && chown postgres:postgres /docker-entrypoint-initdb.d/10_global_init.sql \
    && chown postgres:postgres /docker-entrypoint-initdb.d/20_app_gitea.sql

#### 컨테이너 실행 설정
CMD ["postgres", "-c", "shared_preload_libraries=pg_cron,pgroonga", "-c", "cron.database_name=postgres"]