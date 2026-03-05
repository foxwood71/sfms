"""
시스템 전역에서 사용하는 보안 및 비즈니스 에러 코드를 정의합니다.
명세서 6.0(에러 코드 정의)의 규격에 따라 분류되었습니다.
"""


class ErrorCode:
    """
    SFMS 시스템의 표준 에러 코드 상수를 정의하는 클래스입니다.

    HTTP 상태 코드와 별개로, 비즈니스 로직의 상세 실패 원인을 클라이언트에게
    전달하기 위해 사용됩니다.
    """

    # --- 400 계열: 잘못된 요청 (Bad Request) ---
    PASSWORD_WEAK = 4002  # CustomException - 비밀번호 복잡도 정책 위반 (8자 미만, 특수문자 미포함 등)
    INVALID_PARENT_ORG = (
        4003  # CustomException - 상위 부서 ID가 자기 자신이거나 유효하지 않음
    )
    CIRCULAR_REFERENCE = (
        4005  # CustomException - 하위 부서를 상위 부서로 지정할 수 없습(순환참조)
    )

    # --- 401 계열: 인증 실패 (Unauthorized) ---
    AUTH_FAILED = 4010  # 아이디 또는 비밀번호 불일치
    TOKEN_EXPIRED = 4011  # Access Token의 유효 기간 만료
    TOKEN_INVALID = 4012  # 서명 위조 또는 손상된 유효하지 않은 토큰

    # --- 403 계열: 권한 부족 (Forbidden) ---
    FORBIDDEN = 4030  # 해당 리소스에 접근하기 위한 Permission(권한) 없음
    ACCOUNT_LOCKED = 4031  # 비밀번호 5회 오류로 인해 잠긴 계정 (관리자 문의 필요)

    # --- 409 계열: 리소스 충돌 (Conflict) ---
    DUPLICATE_ORG_CODE = 4090  # 이미 존재하는 조직 코드입니다.
    DUPLICATE_LOGIN_ID = 4092  # 사용자(User) 생성 시 이미 존재하는 로그인 ID 사용
    DUPLICATE_EMAIL = 4093  # 사용자(User) 생성 시 이미 등록된 이메일 사용
    ORG_HAS_CHILDREN = 4091  # 하위 부서가 존재하여 삭제가 불가능한 조직
    ORG_HAS_USERS = 4095  # 소속된 사용자가 존재하여 삭제가 불가능한 조직
    DUPLICATE_CODE = 4090  # 역할(Role) 생성 시 이미 존재하는 고유 코드 사용
    ROLE_IN_USE = 4091  # 사용자가 할당되어 있어 삭제가 불가능한 역할
    SYSTEM_ROLE_MOD = 4092  # 삭제가 금지된 시스템 기본 역할에 대한 삭제 시도

    # --- 429 계열: 요청 횟수 초과 (Too Many Requests) ---
    TOO_MANY_REQUESTS = 4290  # 단시간 내 너무 많은 로그인 시도 (IP 기반 차단)
