FROM postgres:16-bookworm

#### 환경 변수 설정
ENV LANG=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8
ENV TZ=Asia/Seoul
ENV POSTGRESQL_VERSION=16
ENV PGROONGA_VERSION=4.0.5-1

#### 의존성 및 패키지 설치
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

#### 설정 파일 및 SQL 스크립트 복사 (재배치된 경로 반영)
# scripts 및 sql 서브 폴더에서 파일을 가져옵니다.
COPY scripts/00_configure_system.sh /docker-entrypoint-initdb.d/00_configure_system.sh
COPY sql/10_global_init.sql /docker-entrypoint-initdb.d/10_global_init.sql
COPY sql/20_app_gitea.sql /docker-entrypoint-initdb.d/20_app_gitea.sql

#### 파일 권한 변경
RUN chown postgres:postgres /docker-entrypoint-initdb.d/00_configure_system.sh \
    && chmod +x /docker-entrypoint-initdb.d/00_configure_system.sh \
    && chown postgres:postgres /docker-entrypoint-initdb.d/10_global_init.sql \
    && chown postgres:postgres /docker-entrypoint-initdb.d/20_app_gitea.sql

#### 컨테이너 실행 설정
CMD ["postgres", "-c", "shared_preload_libraries=pg_cron,pgroonga", "-c", "cron.database_name=postgres"]