import React, { useState, useEffect } from "react";
import { Badge, Tooltip, Space, Typography } from "antd";
import { http } from "@/shared/api/http";

/**
 * 시스템 통신 상태 표시 램프 컴포넌트
 * 
 * @description 30초마다 백엔드 헬스체크 API를 호출하여 연결 상태를 시각적으로 표시합니다.
 */
const HealthIndicator: React.FC = () => {
	const [status, setStatus] = useState<"success" | "error" | "processing">("processing");
	const [lastChecked, setLastChecked] = useState<string>("");

	const checkHealth = async () => {
		try {
			// 인터셉터의 에러 처리를 피하기 위해 직접 axios 호출 시도도 가능하지만, 
			// 여기서는 공통 http 인스턴스를 사용하되 에러는 자체 캐치합니다.
			const res = await http.get("/health");
			if (res.data?.success) {
				setStatus("success");
			} else {
				setStatus("error");
			}
		} catch (error) {
			setStatus("error");
		} finally {
			setLastChecked(new Date().toLocaleTimeString());
		}
	};

	useEffect(() => {
		checkHealth();
		const interval = setInterval(checkHealth, 30000); // 30초마다 갱신
		return () => clearInterval(interval);
	}, []);

	const statusMap = {
		success: { text: "정상", color: "#52c41a", desc: "서버와 연결됨" },
		error: { text: "오류", color: "#ff4d4f", desc: "서버 연결 끊김" },
		processing: { text: "확인중", color: "#1677ff", desc: "연결 상태 확인 중..." },
	};

	const current = statusMap[status];

	return (
		<Tooltip title={`${current.desc} (마지막 확인: ${lastChecked})`}>
			<Space style={{ cursor: "pointer", padding: "0 8px" }} onClick={checkHealth}>
				<Badge color={current.color} status={status === "processing" ? "processing" : undefined} />
				<Typography.Text type="secondary" style={{ fontSize: "12px" }}>
					{current.text}
				</Typography.Text>
			</Space>
		</Tooltip>
	);
};

export default HealthIndicator;
