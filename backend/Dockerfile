FROM python:3.13-slim

# 1. Python 컨테이너 필수 환경 변수 설정\
# 파이썬 바이트코드(.pyc) 파일 생성 방지
ENV PYTHONDONTWRITEBYTECODE=1  
 # 로그 출력을 버퍼링 없이 즉시 콘솔에 출력 (디버깅 용이)
ENV PYTHONUNBUFFERED=1
# 컨테이너 내부 시간을 한국 시간으로 설정 
ENV TZ=Asia/Seoul  

WORKDIR /app

# 2. 시스템 의존성 설치
# asyncpg 자체는 C 확장이지만 바이너리를 제공하여 libpq-dev가 필수는 아닐 수 있으나,
# psycopg2-binary, bcrypt 등 다른 컴파일 종속성을 위해 build-essential 유지
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/* # 설치 후 apt 캐시를 지워 이미지 용량 최적화

# 3. 패키지 매니저 uv 설치 (기획안 기술 스택 반영)
# pip보다 의존성 해결 및 설치 속도가 압도적으로 빠릅니다.
RUN pip install --no-cache-dir uv

# 4. 패키지 의존성 파일 복사 (레이어 캐싱)
COPY requirements.txt .

# 5. uv를 사용한 패키지 고속 설치
# --system 플래그를 사용하여 컨테이너의 글로벌 파이썬 환경에 설치합니다.
RUN uv pip install --system --no-cache -r requirements.txt

# 6. 소스 코드 복사
# (주의: 로컬 개발 시에는 docker-compose의 volumes로 덮어씌워지지만, 이미지 빌드 완결성을 위해 필요)
COPY . .

# 7. 컨테이너 개방 포트 명시 (도큐멘테이션 목적)
EXPOSE 8000

# 8. FastAPI 실행 (로컬 개발용 핫 리로드 적용)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]