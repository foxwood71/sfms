import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { ConfigProvider, App as AntdApp } from "antd";
import koKR from "antd/locale/ko_KR";
import LoginPage from "@/domains/iam/pages/LoginPage";
import CodeManagePage from "@/domains/cmm/pages/CodeManagePage";
import ApiTester from "@/domains/cmm/ApiTester";
import MainLayout from "./shared/layout/MainLayout";
import { useAuthStore } from "./shared/stores/useAuthStore";
import { useThemeStore } from "./shared/stores/useThemeStore";
import { getThemeConfig } from "./styles/theme";

/**
 * 임시 페이지 컴포넌트
 */
const PagePlaceholder = ({ title }: { title: string }) => (
	<div style={{ padding: 24, background: "transparent", minHeight: 360 }}>
		<h2>{title}</h2>
		<p>이곳에 {title} 화면이 들어갑니다.</p>
	</div>
);

/**
 * SFMS 애플리케이션 메인 라우터 및 테마 공급 컴포넌트
 */
function App() {
	const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
	const themeMode = useThemeStore((state) => state.theme);

	return (
		<ConfigProvider locale={koKR} theme={getThemeConfig(themeMode)}>
			<AntdApp>
				<BrowserRouter>
					<Routes>
						{/* 로그인 페이지 */}
						<Route 
							path="/login" 
							element={isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />} 
						/>

						{/* 메인 서비스 영역 (인증 필요) */}
						<Route 
							path="/" 
							element={isAuthenticated ? <MainLayout /> : <Navigate to="/login" replace />}
						>
							<Route index element={<Navigate to="/dashboard" replace />} />
							<Route path="dashboard" element={<PagePlaceholder title="대시보드" />} />
							
							{/* 시설 관리 */}
							<Route path="fac/list" element={<PagePlaceholder title="시설 목록" />} />
							<Route path="fac/register" element={<PagePlaceholder title="시설 등록" />} />

							{/* 시스템/공통 설정 */}
							<Route path="cmm/codes" element={<CodeManagePage />} />
							<Route path="usr/users" element={<PagePlaceholder title="사용자 관리" />} />
							<Route path="usr/organizations" element={<PagePlaceholder title="조직도 관리" />} />
							<Route path="sys/audit-logs" element={<PagePlaceholder title="감사 로그" />} />

							{/* 개발 도구 */}
							<Route path="dev/tester" element={<ApiTester />} />
						</Route>

						{/* 404 처리 */}
						<Route path="*" element={<Navigate to="/" replace />} />
					</Routes>
				</BrowserRouter>
			</AntdApp>
		</ConfigProvider>
	);
}

export default App;
