"""SFMS 시스템 전역에서 사용하는 보안 및 비즈니스 에러 코드를 정의합니다.

명세서 6.0(에러 코드 정의)의 규격에 따라 분류되었습니다.
"""

from enum import IntEnum


class SuccessCode(IntEnum):
    """SFMS 표준 성공 코드 (2000번대)."""

    # --- 2000: 세션 및 일반 성공 ---
    SUCCESS = 2000  # 일반 성공
    LOGIN_SUCCESS = 2001  # 로그인 성공
    LOGOUT_SUCCESS = 2002  # 로그아웃 성공
    TOKEN_REFRESH_SUCCESS = 2003  # 토큰 갱신 성공

    # --- 2100: IAM 리소스 관리 (Role, Permission) ---
    ROLE_CREATED = 2101  # 역할 생성 성공
    ROLE_UPDATED = 2102  # 역할 수정 성공
    ROLE_DELETED = 2103  # 역할 삭제 성공
    USER_ROLE_ASSIGNED = 2104  # 사용자 역할 할당 성공
    USER_ROLE_REMOVED = 2105  # 사용자 역할 제거 성공 - 미사용

    SUCCESS_CREATED = 2010  # 생성 성공
    SUCCESS_UPDATED = 2040  # 수정 성공
    SUCCESS_DELETED = 2041  # 삭제 성공

    # --- 코드별 메시지 매핑 ---
    @property
    def code(self) -> int:
        """Enum의 value 값을 'code'라는 이름으로 반환합니다."""
        return self.value  # 내부의 value를 code라는 이름으로 노출

    @property
    def message(self) -> str:
        """Enum의 name 값을 'message'라는 이름으로 반환합니다. (프론트엔드 i18n 키)."""
        return self.name


class ErrorCode(IntEnum):
    """SFMS 표준 에러 코드(4000~5000번대)."""

    # iam domain error code 및 message
    # --- 400 계열: 잘못된 요청 (BadRequest) ---
    BAD_REQUEST = 4000  # 잘못된 요청
    ID_MISMATCH = 4001  # URL ID와 페이로드 ID 불일치
    PASSWORD_WEAK = 4002  # IAM, 비밀번호 정책 위반

    # [ORG 도메인 400 계열]
    PASSWORD_MISMATCH = 4003  # 현재 비밀번호 불일치
    INVALID_PARENT_ORG = 4004  # 유효하지 않은 상위 조직 설정
    CIRCULAR_REFERENCE = 4005  # 조직도 순환 참조 발생

    # --- 401 계열: 인증 실패 (Unauthorized) ---
    AUTH_FAILED = 4010  # IAM, 아이디/비밀번호 불일치
    TOKEN_EXPIRED = 4011  # IAM, 토큰 만료
    TOKEN_INVALID = 4012  # IAM, 유효하지 않은 토큰
    TOKEN_BLACKLISTED = 4013  # IAM, 이미 사용된 리프레시 토큰
    REFRESH_TOKEN_REQUIRED = 4014  # IAM, 리프레시 토큰 누락
    AUTH_REQUIRED = 4015  # IAM, 인증이 필요함 (토큰 검증 실패 등)
    USER_NOT_IDENTIFIED = 4016  # IAM, 사용자 식별 정보(sub) 없음

    # --- 403 계열: 권한 부족 (Forbidden) ---
    FORBIDDEN = 4030  # 접근 권한 없음
    ACCOUNT_LOCKED = 4031  # IAM, 계정 잠금 상태
    ACCESS_DENIED = 4032  # 접근 거부 (권한 미달)
    ACCOUNT_DISABLED = 4033  # 계정 비활성화 상태

    # --- 404 계열: 권한 부족 (Forbidden) ---
    NOT_FOUND = 4040  # 리소스를 찾을 수 없음

    # --- 409 계열: 리소스 충돌 (Conflict) ---
    # [IAM / 시스템 공통]
    DUPLICATE_CODE = 4090  # IAM, 조직/역할 코드 중복
    RESOURCE_IN_USE = 4091  # IAM, 하위 리소스 존재 또는 사용 중으로 삭제 불가

    # [USR 도메인 409 계열]
    DUPLICATE_LOGIN_ID = 4092  # 이미 사용 중인 로그인 ID
    DUPLICATE_EMAIL = 4093  # 이미 등록된 이메일 주소
    DUPLICATE_EMP_CODE = 4094  # 이미 등록된 사원 번호

    # [ORG 도메인 409 계열]
    DUPLICATE_ORG_CODE = 4090  # 이미 사용 중인 조직 코드
    ORG_HAS_CHILDREN = 4091  # 하위 부서가 존재하여 삭제할 수 없음
    ORG_HAS_USERS = 4095  # 부서원이 존재하여 부서를 삭제할 수 없음

    # [시스템 공통 409 계열]
    SYSTEM_RESOURCE_MOD = 4099  # 시스템 필수 리소스 수정/삭제 불가

    # --- 429 계열: 요청 횟수 초과 (Too Many Requests) ---
    TOO_MANY_REQUESTS = 4290  # 로그인 시도 횟수 초과

    # --- 500 계열: 시스템 및 인프라 에러 ---
    INTERNAL_SERVER_ERROR = 5000  # SYS, 알 수 없는 서버 내부 오류
    DATABASE_ERROR = 5001  # SYS, 데이터베이스 연결 및 쿼리 오류
    REDIS_ERROR = 5002  # SYS, 레디스 연결 및 서비스 오류
    STORAGE_ERROR = 5003  # SYS, 스토리지(MinIO) 업로드 및 처리 오류
    SERVICE_UNAVAILABLE = 5030  # SYS, 서비스 점검 중 또는 과부하

    # --- 코드별 메시지 매핑 ---
    @property
    def code(self) -> int:
        """Enum의 value 값을 'code'라는 이름으로 반환합니다."""
        return self.value  # 내부의 value를 code라는 이름으로 노출

    @property
    def message(self) -> str:
        """Enum의 name 값을 'message'라는 이름으로 반환합니다. (프론트엔드 i18n 키)."""
        return self.name
