FROM node:20-alpine

WORKDIR /app

# 1. pnpm 전역 설치 (설계서 기술 스택 반영)
RUN npm install -g pnpm

# 2. 패키지 의존성 파일 먼저 복사 (캐시 최적화)
# pnpm-lock.yaml이 아직 없다면 무시되도록 와일드카드(*) 사용
COPY package.json pnpm-lock.yaml* ./

# 3. 패키지 설치
RUN pnpm install

# 4. 소스 코드 전체 복사
COPY . .

# 5. Vite 기본 개발 포트 명시 (도큐멘테이션 목적)
EXPOSE 5173

# 6. 개발 서버 실행 (외부 접속 허용을 위해 --host 0.0.0.0 필수)
CMD ["pnpm", "run", "dev", "--host", "0.0.0.0"]