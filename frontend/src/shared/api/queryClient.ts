/**
 *
 * React Query 클라이언트 설정
 *
 */

import { QueryClient } from "@tanstack/react-query";

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1, // 실패 시 1번만 재시도
      staleTime: 1000 * 60, // 1분 동안은 데이터를 '신선'하다고 판단 (재요청 안 함)
      refetchOnWindowFocus: false, // 윈도우 포커스 될 때마다 재요청 방지
    },
  },
});
