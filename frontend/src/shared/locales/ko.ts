import i18n from "../configs/i18n";

/**
 * 서버에서 전달받은 에러 키를 사용자 친화적인 한국어 메시지로 변환합니다.
 * @param errorKey 서버 응답의 message 필드에 담긴 영문 문자열 키
 * @returns 변환된 한국어 메시지 (없을 경우 키 자체 반환)
 */
export const getErrorMessage = (errorKey: string | undefined): string => {
    if (!errorKey) return i18n.t("common.save_failure");
    
    // errors 객체 내에서 영문 키로 메시지 추출
    const translated = i18n.t(`errors.${errorKey}`);
    
    // i18next는 번역이 없을 경우 키를 그대로 반환하므로, 이를 체크하여 대체 메시지 처리
    if (translated === `errors.${errorKey}`) {
        return errorKey || i18n.t("errors.UNKNOWN");
    }
    
    return translated;
};

/**
 * [호환성 레이어] 기존 MESSAGES 상수를 사용하는 코드들을 위해 
 * getter를 활용하여 실시간 번역된 값을 제공합니다.
 */
export const MESSAGES = {
    get COMMON() {
        return {
            SAVE_SUCCESS: i18n.t("common.save_success"),
            SAVE_FAILURE: i18n.t("common.save_failure"),
            DELETE_CONFIRM: i18n.t("common.delete_confirm"),
            DELETE_SUCCESS: i18n.t("common.delete_success"),
            FETCH_FAILURE: i18n.t("common.fetch_failure"),
            SELECT_PLACEHOLDER: i18n.t("common.select_placeholder"),
            SEARCH_PLACEHOLDER: i18n.t("common.search_placeholder"),
            CANCEL: i18n.t("common.cancel"),
            CONFIRM: i18n.t("common.confirm"),
            RELOAD: i18n.t("common.reload"),
        };
    },

    get AUTH() {
        return {
            LOGIN_SUCCESS: i18n.t("auth.login_success"),
            LOGIN_FAILURE: i18n.t("auth.login_failure"),
            LOGOUT_SUCCESS: i18n.t("auth.logout_success"),
            SESSION_EXPIRED: i18n.t("auth.session_expired"),
            REQUIRED_LOGIN: i18n.t("auth.required_login"),
            ID_PLACEHOLDER: i18n.t("auth.id_placeholder"),
            PWD_PLACEHOLDER: i18n.t("auth.pwd_placeholder"),
        };
    }
};
