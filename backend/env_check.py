import os
import sys


def check_workspace_paths():
    """현재 작업 디렉토리와 가상환경의 관계를 확인합니다."""
    #  현재 실행 위치
    current_dir = os.getcwd()
    #  파이썬 실행 파일 경로
    python_path = sys.executable

    print("--- SFMS Path Integration Check ---")
    print(f"Current Dir: {current_dir}")  # 현재 디렉토리 출력
    print(f"Python Path: {python_path}")  # 파이썬 실행 경로 출력

    #  node_modules 존재 여부 확인
    has_root_nm = os.path.exists("../node_modules") or os.path.exists("./node_modules")

    if has_root_nm:
        print("Status: node_modules detected in workspace.")  # 노드 모듈 감지됨
    else:
        print("Status: node_modules not found in this level.")


if __name__ == "__main__":
    check_workspace_paths()
