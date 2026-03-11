import {
	DatabaseOutlined,
	HeartOutlined,
	LoginOutlined,
	NotificationOutlined,
	UploadOutlined,
} from "@ant-design/icons";
import { App, Button, Card, Divider, Space, Tag, Typography, Upload } from "antd";
import type { AxiosError } from "axios";
import React, { useState } from "react";
import type { APIErrorResponse } from "../../shared/api/types";
import { http } from "../../shared/api/http";

/**
 * API Tester 컴포넌트
 * - 백엔드 API와의 통신을 테스트하고 응답을 확인하는 도구입니다.
 */
const ApiTester: React.FC = () => {
	const { message } = App.useApp();
	const [loading, setLoading] = useState<boolean>(false);
	const [response, setResponse] = useState<unknown>(null);
	const [token, setToken] = useState<string | null>(localStorage.getItem("accessToken"));

	const handleLoginTest = async () => {
		setLoading(true);
		try {
			const res = await http.post("/iam/auth/login", {
				login_id: "admin",
				password: "password123",
			});
			const accessToken = res.data.access_token;
			localStorage.setItem("accessToken", accessToken);
			setToken(accessToken);
			message.success("로그인 성공! 토큰이 저장되었습니다.");
			setResponse(res.data);
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			setResponse(err.response?.data || err.message);
		} finally {
			setLoading(false);
		}
	};

	const handleHealthCheck = async () => {
		setLoading(true);
		try {
			const res = await http.get("/health");
			setResponse(res.data);
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			setResponse(err.response?.data || err.message);
		} finally {
			setLoading(false);
		}
	};

	const handleMeTest = async () => {
		setLoading(true);
		try {
			const res = await http.get("/iam/auth/me", {
				headers: { Authorization: `Bearer ${token}` },
			});
			setResponse(res.data);
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			setResponse(err.response?.data || err.message);
		} finally {
			setLoading(false);
		}
	};

	const handleCustomUpload = async (options: { file: File | string | Blob; onSuccess: (res: unknown) => void; onError: (err: Error) => void }) => {
		const { file, onSuccess, onError } = options;
		const formData = new FormData();
		formData.append("file", file);

		try {
			const res = await http.post("/cmm/files/upload", formData, {
				headers: { "Content-Type": "multipart/form-data" },
			});
			onSuccess(res.data);
			setResponse(res.data);
			message.success("파일 업로드 성공");
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			onError(new Error(err.message));
			setResponse(err.response?.data || err.message);
		}
	};

	return (
		<div style={{ padding: 24 }}>
			<Typography.Title level={2}>API 통신 테스트</Typography.Title>
			<Typography.Paragraph>백엔드 서비스와의 연결 상태 및 인증 토큰 작동 여부를 확인합니다.</Typography.Paragraph>

			<Space size="middle" style={{ marginBottom: 24 }}>
				<Button type="primary" icon={<LoginOutlined />} onClick={handleLoginTest} loading={loading}>
					테스트 로그인 (admin)
				</Button>
				<Button icon={<HeartOutlined />} onClick={handleHealthCheck} loading={loading}>
					Health Check
				</Button>
				<Button
					icon={<DatabaseOutlined />}
					onClick={handleMeTest}
					loading={loading}
					disabled={!token}
					danger={!token}
				>
					내 정보 조회 (Auth 필요)
				</Button>
			</Space>

			<Card title="파일 업로드 테스트" style={{ marginBottom: 24 }}>
				<Upload customRequest={handleCustomUpload as any} showUploadList={false}>
					<Button icon={<UploadOutlined />}>파일 선택 및 업로드</Button>
				</Upload>
			</Card>

			<Divider orientation="left">응답 결과 (JSON)</Divider>

			<Card style={{ background: "#f5f5f5", borderRadius: 8 }}>
				<div style={{ marginBottom: 8 }}>
					<Tag color={token ? "green" : "red"}>{token ? "토큰 있음" : "토큰 없음"}</Tag>
					{token && <Typography.Text code ellipsis style={{ maxWidth: 300 }}>{token}</Typography.Text>}
				</div>
				<pre style={{ margin: 0, whiteSpace: "pre-wrap", wordBreak: "break-all" }}>
					{JSON.stringify(response, null, 2)}
				</pre>
			</Card>
		</div>
	);
};

export default ApiTester;
