import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { QueryClientProvider } from "@tanstack/react-query";
import { ConfigProvider } from "antd"; // Ant Design 한글 설정용
import koKR from "antd/locale/ko_KR";
import App from "./App.tsx";
import { queryClient } from "./shared/api/queryClient";
import "./index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    {/* 1. React Query 공급자 주입 */}
    <QueryClientProvider client={queryClient}>
      {/* 2. Ant Design 한글 설정 적용 */}
      <ConfigProvider locale={koKR}>
        <App />
      </ConfigProvider>
    </QueryClientProvider>
  </StrictMode>,
);
