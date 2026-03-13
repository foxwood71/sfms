import { http } from "@/shared/api/http";
import type { APIErrorResponse } from "@/shared/api/types";
import { Button, Card, Space, message } from "antd";
import type React from "react";

const ApiTester: React.FC = () => {
	const testHealth = async () => {
		try {
			const res = await http.get("/health");
			message.success(`Health Check: ${res.data.status}`);
		} catch (err) {
			const axiosError = err as APIErrorResponse;
			message.error(`Health Check Failed: ${axiosError.message}`);
		}
	};

	return (
		<Card title="API Connection Tester" style={{ margin: 20 }}>
			<Space>
				<Button type="primary" onClick={testHealth}>
					Test /health
				</Button>
			</Space>
		</Card>
	);
};

export default ApiTester;
