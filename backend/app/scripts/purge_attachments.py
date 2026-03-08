"""첨부파일 영구 삭제 배치 스크립트 (Garbage Collection).

소프트 삭제(is_deleted=True)된 지 일정 기간이 지난 파일을 
DB와 MinIO 스토리지에서 물리적으로 완전히 삭제합니다.

실행 방법:
    python -m app.scripts.purge_attachments --days 30
"""

import argparse
import asyncio
import os
import sys

# 프로젝트 루트를 Python Path에 추가 (상위 디렉토리 참조를 위해)
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


from app.core.database import async_session_factory
from app.domains.cmm.services import AttachmentService


async def main():
    """첨부파일 영구 삭제 배치의 메인 실행 함수입니다.
    
    명령줄 인자를 파싱하고 데이터베이스 세션을 생성하여 
    삭제 기준을 충족하는 파일들을 물리적으로 제거합니다.
    """
    # 1. 인자 처리
    parser = argparse.ArgumentParser(description="소프트 삭제된 파일을 영구 파기합니다.")
    parser.add_argument("--days", type=int, default=30, help="삭제 유지 기간 (기본 30일)")
    args = parser.parse_args()

    print(f"[{sys.argv[0]}] 배치를 시작합니다. (기준 기간: {args.days}일)")

    # 2. DB 세션 생성 및 서비스 호출
    async with async_session_factory() as db:
        try:
            deleted_count = await AttachmentService.purge_deleted_attachments(db, days_threshold=args.days)
            print(f"SUCCESS: 총 {deleted_count}개의 파일이 영구 삭제되었습니다.")
        except Exception as e:
            print(f"ERROR: 배치 실행 중 오류가 발생했습니다: {str(e)}")
            sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
