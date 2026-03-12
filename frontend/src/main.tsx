import "@ant-design/v5-patch-for-react-19";
import { QueryClientProvider } from "@tanstack/react-query";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";
import "./shared/configs/i18n"; // i18n 설정 로드
import { queryClient } from "./shared/api/queryClient";

const rootElement = document.getElementById("root");
if (rootElement) {
    createRoot(rootElement).render(
        <StrictMode>
            <QueryClientProvider client={queryClient}>
                <App />
            </QueryClientProvider>
        </StrictMode>,
    );
}
