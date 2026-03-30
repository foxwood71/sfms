import type { GlobalToken } from "antd";

/**
 * SFMS UI/UX 레이아웃 표준 상수
 */
export const LAYOUT_CONSTANTS = {
    /** 상단 네비게이션을 제외한 전체 페이지 헤더 높이 */
    HEADER_HEIGHT: 56,
    /** 페이지 컨테이너 내부의 실제 콘텐츠 영역 계산식 (카드 높이 표준화) */
    CONTENT_HEIGHT: "calc(100vh - 180px)",
    /** 테이블 내부 스크롤 가용 높이 (필터 없을 때) */
    TABLE_VIEW_HEIGHT: "calc(100vh - 400px)",
    /** 테이블 내부 스크롤 가용 높이 (필터 있을 때) */
    TABLE_VIEW_HEIGHT_WITH_FILTER: "calc(100vh - 460px)",
    /** 드로어/모달 내부 폼 아이템 간격 */
    FORM_GUTTER: 16,
};

/**
 * 벤토(Bento) 스타일 공통 디자인 토큰 및 테이블 스타일
 */
export const BENTO_STYLE = (token: GlobalToken) => ({
    padding: "12px 16px",
    background: token.colorFillAlter,
    borderRadius: token.borderRadiusLG,
    border: `1px solid ${token.colorBorderSecondary}`,
});

/**
 * 전역 공통 테이블 스타일 (CSS-in-JS용 문자열)
 * 모든 관리 페이지의 <style> 태그에 공통 삽입
 */
export const getStandardTableStyle = (token: GlobalToken) => `
    /* 1. 테이블 컨테이너 및 레이아웃 */
    .ant-table-wrapper { height: 100%; overflow: hidden; display: flex; flex-direction: column; }
    .ant-spin-nested-loading, .ant-spin-container, .ant-table { height: 100% !important; display: flex; flex-direction: column; }
    .ant-table-body { flex: 1; overflow-y: auto !important; }

    /* 2. 헤더(Thead) 스타일 통일 */
    .ant-table-thead > tr > th {
        background: ${token.colorFillAlter} !important;
        font-weight: 600 !important;
        border-bottom: 1px solid ${token.colorBorderSecondary} !important;
        padding: 12px 16px !important;
        white-space: nowrap;
    }

    /* 3. 행(Row) 호버 및 활성 상태 - [FIX] 정렬 컬럼 배경색 간섭 해결 */
    .ant-table-tbody > tr.ant-table-row:hover > td,
    .ant-table-tbody > tr.ant-table-row:hover > td.ant-table-column-sort {
        background: ${token.colorFillQuaternary} !important;
    }
    .ant-table-tbody > tr.ant-table-row-selected > td,
    .ant-table-tbody > tr.ant-table-row-selected > td.ant-table-column-sort {
        background: ${token.colorPrimaryBg} !important;
    }

    /* 4. 액션 아이콘 및 툴 버튼 */
    .ant-btn-text.ant-btn-sm {
        color: ${token.colorTextSecondary};
    }
    .ant-btn-text.ant-btn-sm:hover {
        color: ${token.colorPrimary};
        background: ${token.colorPrimaryBg};
    }

    /* 5. [FIX] 선택(체크박스) 컬럼 가림 현상 방지 및 정렬 일치화 */
    .ant-table-thead > tr > th.ant-table-selection-column,
    .ant-table-tbody > tr > td.ant-table-selection-column {
        text-align: left !important;
        padding-left: 20px !important; 
        padding-right: 0 !important;
        width: 56px !important;
        min-width: 56px !important;
        max-width: 56px !important;
        position: relative;
        z-index: 2;
    }

    /* 체크박스 바로 다음 데이터 컬럼의 시작 위치를 넉넉하게 보정 */
    .ant-table-thead > tr > th.ant-table-selection-column + th,
    .ant-table-tbody > tr > td.ant-table-selection-column + td {
        padding-left: 16px !important;
    }

    .ant-table-selection {
        display: flex;
        justify-content: flex-start;
        align-items: center;
    }

    /* 정렬(Sorter) 아이콘 위치 최적화 */
    .ant-table-column-sorter {
        margin-left: 8px;
        color: ${token.colorTextQuaternary};
    }
`;
