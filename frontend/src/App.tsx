import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import CodeManagePage from "@/domains/cmm/pages/CodeManagePage";
import MainLayout from "./shared/layout/MainLayout";

//  임시 페이지 컴포넌트 (테스트용)
const PagePlaceholder = ({ title }: { title: string }) => (
	<div style={{ padding: 24, background: "#fff", minHeight: 360 }}>
		<h2>{title}</h2>
		<p>이곳에 {title} 화면이 들어갑니다.</p>
	</div>
);

function App() {
	return (
		<BrowserRouter>
			<Routes>
				{/* 메인 레이아웃 적용 */}
				<Route path="/" element={<MainLayout />}>
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

					{/* 공통 관리 (CMM) */}
					<Route path="cmm/codes" element={<CodeManagePage />} />
					<Route
						path="cmm/users"
						element={<PagePlaceholder title="사용자 관리" />}
					/>
				</Route>
			</Routes>
		</BrowserRouter>
	);
}

export default App;
