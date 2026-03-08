import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import LoginPage from "@/domains/iam/pages/LoginPage";
import CodeManagePage from "@/domains/cmm/pages/CodeManagePage";
import ApiTester from "@/domains/cmm/ApiTester";
import MainLayout from "./shared/layout/MainLayout";
import { useAuthStore } from "./shared/stores/useAuthStore";

/**
 * 임시 페이지 컴포넌트 (테스트용)
 */
const PagePlaceholder = ({ title }: { title: string }) => (
	<div style={{ padding: 24, background: "#fff", minHeight: 360 }}>
		<h2>{title}</h2>
		<p>이곳에 {title} 화면이 들어갑니다.</p>
	</div>
);

/**
 * SFMS 애플리케이션 메인 라우터 컴포넌트
 * 
 * @description 인증 상태를 감시하여 로그인 페이지 또는 메인 레이아웃으로 안내합니다.
 */
function App() {
	// 전역 상태에서 인증 여부 확인
	const isAuthenticated = useAuthStore((state) => state.isAuthenticated);

	return (
		<BrowserRouter>
			<Routes>
				{/* 1. 로그인 페이지 (미인증 상태 전용) */}
				<Route 
					path="/login" 
					element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />} 
				/>

				{/* 2. 메인 서비스 영역 (인증 필요) */}
				<Route 
					path="/" 
					element={isAuthenticated ? <MainLayout /> : <Navigate to="/login" replace />}
				>
					{/* 기본 리다이렉트: / -> /dashboard */}
					<Route index element={<Navigate to="/dashboard" replace />} />

					<Route
						path="dashboard"
						element={<PagePlaceholder title="대시보드" />}
					/>

					{/* 시설 관리 (FAC) */}
					<Route
						path="fac/list"
						element={<PagePlaceholder title="시설 목록" />}
					/>
					<Route
						path="fac/register"
						element={<PagePlaceholder title="시설 등록" />}
					/>

					{/* 설비 관리 (EQP) */}
					<Route
						path="eqp/list"
						element={<PagePlaceholder title="설비 목록" />}
					/>
					<Route
						path="eqp/maintenance"
						element={<PagePlaceholder title="유지보수" />}
					/>

					{/* 공통 관리 (CMM) 및 사용자 관리 */}
					<Route path="cmm/codes" element={<CodeManagePage />} />
					<Route
						path="usr/users"
						element={<PagePlaceholder title="사용자 관리" />}
					/>
					<Route
						path="usr/organizations"
						element={<PagePlaceholder title="조직도 관리" />}
					/>

					{/* 개발 도구 */}
					<Route path="dev/tester" element={<ApiTester />} />
				</Route>

				{/* 404 처리: 홈으로 */}
				<Route path="*" element={<Navigate to="/" replace />} />
			</Routes>
		</BrowserRouter>
	);
}

export default App;
