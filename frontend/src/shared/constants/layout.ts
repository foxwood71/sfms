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
 * 벤토(Bento) 스타일 공통 디자인 토큰
 */
export const BENTO_STYLE = (token: any) => ({
	padding: "12px 16px",
	background: token.colorFillAlter,
	borderRadius: token.borderRadiusLG,
	border: `1px solid ${token.colorBorderSecondary}`,
});
