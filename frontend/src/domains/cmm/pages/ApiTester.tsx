import { BugOutlined, SendOutlined } from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { Button, Input, Select, Space, Tag, Typography, theme } from "antd";
import type React from "react";
import { useState } from "react";
import { http } from "@/shared/api/http";
import type { APIResponse } from "@/shared/types/api";

const { Text, Title } = Typography;

/**
 * 시스템 관리자용 API 엔드포인트 테스트 도구 (Zero Any 적용)
 */
const ApiTester: React.FC = () => {
	const { token } = theme.useToken();
	const [method, setMethod] = useState<string>("GET");
	const [url, setUrl] = useState<string>("/health");
	const [loading, setLoading] = useState<boolean>(false);
	const [response, setResponse] = useState<APIResponse<unknown> | null>(null);
	const [error, setError] = useState<any>(null);

	const handleTest = async () => {
		setLoading(true);
		setResponse(null);
		setError(null);
		try {
			const res = await http.request({
				method,
				url,
			});
			setResponse(res.data);
		} catch (err: any) {
			setError(err.response?.data || err.message);
		} finally {
			setLoading(false);
		}
	};

	return (
		<PageContainer title="API 테스터" subTitle="시스템 엔드포인트 연동 테스트">
			<ProCard layout="vertical" gutter={16} ghost>
				<ProCard title="요청 설정" headerBordered>
					<Space.Compact style={{ width: "100%" }}>
						<Select
							value={method}
							onChange={setMethod}
							options={[
								{ value: "GET", label: "GET" },
								{ value: "POST", label: "POST" },
								{ value: "PUT", label: "PUT" },
								{ value: "DELETE", label: "DELETE" },
							]}
							style={{ width: 120 }}
						/>
						<Input
							value={url}
							onChange={(e) => setUrl(e.target.value)}
							placeholder="/api/v1/..."
							onPressEnter={handleTest}
						/>
						<Button type="primary" icon={<SendOutlined />} loading={loading} onClick={handleTest}>
							전송
						</Button>
					</Space.Compact>
				</ProCard>

				<ProCard title="응답 결과" headerBordered style={{ marginTop: 16 }}>
					{loading ? (
						<div style={{ textAlign: "center", padding: 40 }}>요청 처리 중...</div>
					) : response ? (
						<div>
							<Space style={{ marginBottom: 16 }}>
								<Tag color="green">SUCCESS</Tag>
								<Text type="secondary">Status: {response.status}</Text>
							</Space>
							<pre style={{ 
								padding: 16, 
								background: token.colorBgLayout, 
								borderRadius: token.borderRadius,
								overflow: "auto",
								maxHeight: 500
							}}>
								{JSON.stringify(response, null, 2)}
							</pre>
						</div>
					) : error ? (
						<div>
							<Space style={{ marginBottom: 16 }}>
								<Tag color="error">ERROR</Tag>
								<BugOutlined style={{ color: token.colorError }} />
							</Space>
							<pre style={{ 
								padding: 16, 
								background: "#fff1f0", 
								color: token.colorError,
								borderRadius: token.borderRadius,
								border: "1px solid #ffa39e"
							}}>
								{JSON.stringify(error, null, 2)}
							</pre>
						</div>
					) : (
						<div style={{ color: token.colorTextDisabled, textAlign: "center", padding: 40 }}>
							상단에서 API를 호출하면 결과가 여기에 표시됩니다.
						</div>
					)}
				</ProCard>
			</ProCard>
		</PageContainer>
	);
};

export default ApiTester;
