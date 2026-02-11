# @docker 한글지원 image 빌드 스크립트 생성

- postgresql16을 기준으로 작성

## 1. 사전작업

- 1.1 docker compose 프로젝트 디렉토리 생성

```bash
mkdir -p ~/porjects/gumc && cd ~/porjects/gumc
mkdir -p vols/pgsql vols/pgsql vols/pgadm vols/gitea/etc vols/gitea/data
mkdir pgsql pgadm gitea
PWD
```

## 2. postgres

- 2.1 postgresql 시스템 설정 셀 스크립트 생성

```bash
touch pgsql/00_configure_system.sh
code pgsql/00_configure_system.sh
```

- 2.2 postgresql 데이터베이스 초기화용 sql 스크립트 작성

```bash
touch pgsql/10_global_init.sql pgsql/20_app_gitea.sql
code pgsql/10_global_init.sql
code pgsql/20_app_gitea.sql
```

- 2.3 postgresql 자체 서명 인증서 생성

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./pgsql/pgsql.key -out ./pgsql/pgsql.crt -subj "/C=KR/ST=Gyeonggi-do/L=Gwangju-si/O=gumc/CN=pgsql"
chmod 644 pgsql-key
```

- 2.4 postgresql 패스워드파일 생성

```bash
touch pgsql/pass.txt
echo pgpass >> pgsql/pass.txt
```

- 2.5 postgresql 환경변수파일 생성

```bash
touch pgsql/.env
echo GUMC_USER_VER=1.12 >> pgsql/.env
```

- 2.6 postgresql Dockerfile 생성

```bash
touch pgsql/Dockerfile
code pgsql/Dockerfile
```

---

## 3. pgadm4

- 3.1 pgadm4 시스템 설정 셀 스크립트 생성

```bash
touch pgadm/00_configure_system.sh
code pgadm/00_configure_system.sh
```

- 3.2 pgadm4 자체 서명 인증서 생성

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./pgadm/pgadm.key -out ./pgadm/pgadm.crt -subj "/C=KR/ST=Gyeonggi-do/L=Gwangju-si/O=gumc/CN=pgadm"
chmod 644 pgadm-key
```

- 3.3 pgadm4 패스워드파일 생성

```bash
touch pgadm/pass.txt
echo adpass >> pgadm/pass.txt
```

- 3.4 pgadm4 환경변수파일 생성

```bash
touch pgadm/.env
echo GUMC_USER_VER=1.12 >> pgadm/.env
```

---

## 4. gitea

---

- 4.1 gitea 시스템 설정 셀 스크립트 생성

```bash
touch gitea/00_configure_system.sh
code gitea/00_configure_system.sh
```

- 4.2 gitea 자체 서명 인증서 생성

```bash
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./gitea/gitea.key -out ./gitea/gitea.crt -subj "/C=KR/ST=Gyeonggi-do/L=Gwangju-si/O=gumc/CN=gitea"
chmod 644 gitea-key
```

4.3 gitea 패스워드파일 생성

```bash
touch gitea/pass.txt
echo gitpass >> gitea/pass.txt
```

4.4 gitea 환경변수파일 생성

```bash
touch gitea/.env
echo GUMC_USER_VER=1.12 >> gitea/.env
```

## 5. docker compose 파일 생성

```bash
touch docker-compose.yml
code docker-compose.yml
```

---

## 6. docker compose 실행 명령 및 점검 사항

- 6.1 docker compose build

```bash
docker compose up --build -d
docker compose up -d --force-recreate postgres
docker logs pgsal
```

- 6.2 docker compose clean restart

```bash
docker compose down
docker rm -f $(docker ps -a -q) # => down 확인
docker volume rm $(docker volume ls -q)
docker rmi $(docker images -q)
sudo rm -rf vols/pgsql vols/pgadm vols/gitea/etc vols/gitea/data
mkdir -p vols/pgsql vols/pgadm vols/gitea/etc vols/gitea/data
pass init "foxtreekr@naver.com"
docker compose up -d
```

- 6.3 docker container state check

```bash
docker exec -it pgsql bash
docker logs -f --tail 10 pgsql
docker inspect --format "{{json .State.Health }}" pgsql | jq
docker inspect --format "{{json .State.Health }}" $(docker compose ps -q postgres) | jq
docker exec -it pgsql bash
Sroot@1a6eb48b7107:/# psql -U postgres -p 5432 -h localhost
```

---

### 7 컨테이너 네트워크 확인

- 7.1 ip address 확인

```bash
docker inspect gitea | grep IPAddress

             "SecondaryIPAddresses": null,
             "IPAddress": "",
                     "IPAddress": "172.18.0.2",
```

---

- 7.2 pgsql ssl connection check

```bash
docker exec -it pgsql bash
  root@1a6eb48b7107:/# psql -U postgres -p 5432 -h localhost
    psql (15.8 (Debian 15.8-1.pgdg120+1))
    SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off)
    Type "help" for help.
    postgres=#
```

---

### 8 gitea 접속 테스트

- 웹 브라우저에서 테스트
  1. https://{ip}:3000 접속
  2. 에러가 발생한다면, docker-compose logs -f 명령어를 통해서 디버깅
  3. 초기 설정 화면 확인 후 아래에 설치하기 누르면 완료
  4. 계정 생성
  5. repository 생성
  6. console에서 git clone 실시

- 사설인증서인 경우 에러가 발생하므로 다음과 같이 입력한다.

```bash
  git -c http.sslVerify=false clone https://localhost:3000/foxtreekr/gitea-test-repo.git
```

- git 동작 테스트

```bash
ssh git clone
```

- ssh public key를 gitea에 등록후 다음과 같이 입력한다

```bash
git clone ssh://git@localhost:15022/foxtreekr/gitea-test-repo.git
```
