"""전역 시스템 로깅 모듈 (Global System Logging).

이 모듈은 애플리케이션 전역에서 사용할 수 있는 표준 로거(Logger)를 설정하고 제공합니다.
FastAPI 동작 중 발생하는 시스템 에러, 인프라 연결 상태, 중요 이벤트를
터미널(Console)과 파일(File)에 동시에 기록합니다.

주요 기능:
    - 표준 출력(Console) 로깅: 실시간 디버깅 및 도커(Docker) 컨테이너 로그 수집용
    - 파일(File) 로깅: 영구 보관 및 사후 장애 분석용
    - 로그 롤링(Log Rotation): 매일 자정(Midnight) 기준으로 새로운 파일 생성
    - 로그 보존 정책: 최근 30일(backupCount=30)의 로그만 보관하여 디스크 용량 관리

사용법:
    비즈니스 로직이나 인프라 로직(예: health.py)에서 다음과 같이 임포트하여 사용합니다.

    >>> from app.core.logger import logger
    >>> logger.info("서비스가 정상적으로 시작되었습니다.")
    >>> logger.error(f"DB 연결 실패: {e}")

출력 포맷:
    YYYY-MM-DD HH:MM:SS - sfms - LEVEL - 메시지
    (예: 2026-03-07 12:30:00 - sfms - ERROR - Health check failed)

Dependencies:
    - logging: Python 표준 로깅 라이브러리
    - logging.handlers.TimedRotatingFileHandler: 시간 기반 로그 파일 롤링 핸들러
"""

import logging
import os
import sys
from logging.handlers import TimedRotatingFileHandler

# 로그 파일이 저장될 루트 디렉토리 설정
LOG_DIR = "logs"

# 프로세스 시작 시 로그 디렉토리가 없으면 자동 생성합니다.
if not os.path.exists(LOG_DIR):
    os.makedirs(LOG_DIR)


def setup_logger() -> logging.Logger:
    """SFMS 프로젝트의 전역 로거(Logger) 인스턴스를 생성하고 설정합니다.

    이 함수는 싱글톤(Singleton) 패턴처럼 모듈 로드 시 최초 1회만 실행되며,
    이후에는 설정이 완료된 `logger` 객체를 전역으로 내보냅니다.

    Returns:
        logging.Logger: 설정이 완료된 시스템 로거 인스턴스

    """
    # 프로젝트 최상위 로거 이름("sfms") 지정
    logger = logging.getLogger("sfms")
    logger.setLevel(
        logging.INFO
    )  # 기본 로그 레벨 설정 (DEBUG, INFO, WARNING, ERROR, CRITICAL)

    # 로그 출력 포맷 정의 (시간 - 로거이름 - 레벨 - 메시지)
    formatter = logging.Formatter(
        fmt="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # 1. 콘솔 출력 핸들러 설정 (터미널 출력용)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)

    # 2. 파일 출력 핸들러 설정 (매일 자정 롤링, 30일 보관, UTF-8 인코딩)
    file_handler = TimedRotatingFileHandler(
        filename=os.path.join(LOG_DIR, "system.log"),
        when="midnight",
        interval=1,
        backupCount=30,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)

    # 핸들러 중복 추가 방지 (Hot Reload 시 로그가 두 번 찍히는 현상 방지)
    if not logger.handlers:
        logger.addHandler(console_handler)
        logger.addHandler(file_handler)

    return logger


# 모듈 임포트 시 즉시 사용할 수 있도록 로거 인스턴스를 생성하여 내보냅니다.
logger = setup_logger()
