import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { ConfigProvider, theme } from "antd";
import koKR from "antd/locale/ko_KR";
import MainLayout from "./shared/layout/MainLayout";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClient } from "./shared/api/queryClient";

import CodeManagePage from "@/domains/cmm/pages/CodeManagePage";

//  임시 페이지 컴포넌트 (테스트용)
const PagePlaceholder = ({ title }: { title: string }) => (
  <div style={{ padding: 24, background: "#fff", minHeight: 360 }}>
    <h2>{title}</h2>
    <p>이곳에 {title} 화면이 들어갑니다.</p>
  </div>
);

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider
        locale={koKR}
        theme={{
          // 다크 모드 알고리즘 적용
          algorithm: theme.darkAlgorithm,
          token: {
            colorPrimary: "#1890ff", // (선택) 포인트 컬러는 파란색 유지
          },
        }}
      >
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
      </ConfigProvider>
    </QueryClientProvider>
  );
}

export default App;
