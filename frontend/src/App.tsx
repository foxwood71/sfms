import { App as AntdApp, ConfigProvider } from "antd";
import koKR from "antd/locale/ko_KR";
import { useTranslation } from "react-i18next";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import ApiTester from "./domains/cmm/ApiTester";
import CodeManagePage from "./domains/cmm/pages/CodeManagePage";
// 상대 경로 임포트 (Vite 별칭 이슈 방지)
import LoginPage from "./domains/iam/pages/LoginPage";
import OrganizationPage from "./domains/usr/pages/OrganizationPage";
import UserListPage from "./domains/usr/pages/UserListPage";
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
	const { t } = useTranslation();
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
							element={
								isAuthenticated ? <Navigate to="/" replace /> : <LoginPage />
							}
						/>

						{/* 메인 서비스 영역 (인증 필요) */}
						<Route
							path="/"
							element={
								isAuthenticated ? (
									<MainLayout />
								) : (
									<Navigate to="/login" replace />
								)
							}
						>
							<Route index element={<Navigate to="/dashboard" replace />} />
							<Route
								path="dashboard"
								element={<PagePlaceholder title={t("menu.dashboard")} />}
							/>

							{/* 사용자 및 조직 */}
							<Route path="usr/organizations" element={<OrganizationPage />} />
							<Route path="usr/users" element={<UserListPage />} />

							{/* 인증 및 권한 */}
							<Route
								path="iam/roles"
								element={<PagePlaceholder title={t("menu.iam-roles")} />}
							/>

							{/* 시설 및 공간 */}
							<Route
								path="fac/spaces"
								element={<PagePlaceholder title={t("menu.fac-spaces")} />}
							/>
							<Route
								path="fac/facilities"
								element={<PagePlaceholder title={t("menu.fac-facilities")} />}
							/>

							{/* 공통 설정 */}
							<Route path="cmm/codes" element={<CodeManagePage />} />

							{/* 시스템 관리 */}
							<Route
								path="sys/audit-logs"
								element={<PagePlaceholder title={t("menu.sys-audit-logs")} />}
							/>
							<Route path="sys/api-tester" element={<ApiTester />} />
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
