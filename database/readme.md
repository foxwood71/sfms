# Postgresql script 실행방법

## 1. PostgreSQL Client 설치

### 1. 기본 저장소 사용 (가장 간단한 방법)

OS의 기본 저장소에 포함된 버전을 사용하는 방법입니다. 서버 데몬인 `postgresql-server`를 제외하고 `postgresql` 패키지명만 지정하면 클라이언트만 설치됩니다.

```bash
sudo dnf install postgresql

```

### 2. 공식 PostgreSQL 저장소 사용 (특정 버전이 필요한 경우)

운영 중인 DB 서버와 버전을 정확히 일치시켜야 하거나, 더 최신 버전의 클라이언트 도구가 필요할 때 사용하는 방법입니다.

**1. 공식 저장소(PGDG) 추가:**

```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-10-x86_64/pgdg-redhat-repo-latest.noarch.rpm

```

**2. OS 기본 PostgreSQL 모듈 비활성화 (패키지 충돌 방지):**

```bash
sudo dnf -qy module disable postgresql

```

**3. 특정 버전의 클라이언트 설치 (예: PostgreSQL 16):**
원하는 버전 번호를 붙여서 설치합니다. (서버 패키지인 `postgresql16-server`가 포함되지 않도록 주의합니다.)

```bash
sudo dnf install postgresql16

```

---

### 3. 설치 확인

설치가 완료된 후, 아래 명령어를 통해 클라이언트 도구가 정상적으로 설치되었는지 버전을 확인할 수 있습니다.

```bash
psql --version

```

### 4. Database deploy

터미널(명령줄)에서 `psql` 명령어를 사용하여 현재 디렉토리에 있는 SQL 스크립트 파일을 바로 실행할 수 있습니다.

```bash
psql -h localhost -U sfms_admin -d sfms_db -f deploy.pgsql

```

**사용된 옵션 설명:**

* `-h localhost`: 데이터베이스 서버 호스트를 지정합니다.
* `-U sfms_admin`: 접속할 사용자 계정을 지정합니다.
* `-d sfms_db`: 대상 데이터베이스를 지정합니다.
* `-f deploy.pgsql`: 실행할 SQL 파일의 경로를 지정합니다.

명령어를 실행하면 `sfms_admin` 계정의 비밀번호를 묻는 프롬프트가 나타나며, 비밀번호를 입력하면 파일 내의 쿼리들이 순차적으로 실행됩니다.

#### 1. 결과와 에러를 하나의 파일에 모두 저장하기 (권장)

정상적인 쿼리 실행 결과와 에러 메시지를 시간 순서대로 한 곳에서 확인하고 싶을 때 사용합니다. 명령어 끝에 `> 파일명 2>&1`을 추가합니다.

```bash
psql -h localhost -U sfms_admin -d sfms_db -f 00_deploy.pgsql > execute_result.log 2>&1

```

**옵션 설명:**

* `> execute_result.log`: 쿼리 실행 결과(표준 출력)를 `execute_result.log`라는 파일에 덮어써서 저장합니다.
* `2>&1`: 에러 메시지(표준 에러, `2`)를 정상 결과(`1`)와 같은 파일로 보냅니다.

#### 2. 결과와 에러를 각각 분리해서 저장하기

정상 처리된 로그와 에러 로그를 구분해서 관리해야 할 때 유용합니다.

```bash
psql -h localhost -U sfms_admin -d sfms_db -f 00_deploy.pgsql > result.log 2> error.log

```

**옵션 설명:**

* `> result.log`: 정상적인 실행 결과만 저장합니다.
* `2> error.log`: 실행 중 발생한 에러 메시지만 따로 모아서 저장합니다.

---

**💡 배포 스크립트 실행 시 추가 팁**
기본적으로 `psql`은 파일 안의 특정 쿼리에서 에러가 발생해도 멈추지 않고 다음 쿼리를 계속 실행합니다. 파일명(`deplou.pgsql` / `deploy.pgsql`)으로 보아 구조를 변경하거나 데이터를 밀어 넣는 스크립트일 확률이 높아 보이는데, 이런 경우 에러 발생 시 즉시 멈추는 것이 안전합니다.

이때는 `-v ON_ERROR_STOP=1` 옵션을 추가하는 것을 권장합니다.

```bash
psql -h localhost -U sfms_admin -d sfms_db -v ON_ERROR_STOP=1 -f 00_deploy.pgsql > execute_result.log 2>&1

```

파일에 저장된 로그를 터미널 창에서 바로 열어보거나, 실행되는 과정을 실시간으로 모니터링하는 방법(`cat`, `tail` 명령어 등)도 함께 안내해 드릴까요?
