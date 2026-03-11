import { LockOutlined, UserOutlined } from "@ant-design/icons";
import { useAuthStore } from "@/shared/stores/useAuthStore";
import { App, Button, Card, Form, Input, Layout, Space, Typography, theme } from "antd";
import type { AxiosError } from "axios";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import type { APIErrorResponse } from "@/shared/api/types";
import HealthIndicator from "@/shared/layout/components/HealthIndicator";
import ThemeToggle from "@/shared/layout/components/ThemeToggle";
import { getMeApi, loginApi } from "../api/auth";

const { Content, Header } = Layout;

/**
 * 로그인 페이지 컴포넌트
 * - SFMS 시스템의 통합 인증 및 세션 관리를 담당합니다.
 */
const LoginPage: React.FC = () => {
	const [loading, setLoading] = useState(false);
	const { setAuth } = useAuthStore();
	const navigate = useNavigate();
	const { token } = theme.useToken();
	const { message } = App.useApp();

	/**
	 * 로그인 폼 제출 핸들러
	 */
	const onFinish = async (values: Record<string, string>) => {
		setLoading(true);
		try {
			// 1. 로그인 요청
			const loginRes = await loginApi(values.login_id, values.password);
			const { access_token } = loginRes.data;

			// 2. 토큰 저장 (스토어)
			localStorage.setItem("accessToken", access_token);

			// 3. 내 정보 가져오기
			const userRes = await getMeApi();
			const userData = userRes.data;

			setAuth(userData, access_token);
			message.success(`${userData.name}님, 환영합니다!`);
			navigate("/");
		} catch (error: unknown) {
			const err = error as AxiosError<APIErrorResponse>;
			const errorMsg = err.response?.data?.message || err.message || "로그인에 실패했습니다.";
			message.error(errorMsg);
			console.error("Login failed:", err);
		} finally {
			setLoading(false);
		}
	};

	return (
		<Layout style={{ minHeight: "100vh" }}>
			<Header
				style={{
					background: token.colorBgContainer,
					padding: "0 24px",
					display: "flex",
					justifyContent: "space-between",
					alignItems: "center",
					boxShadow: "0 1px 2px rgba(0,0,0,0.03)",
				}}
			>
				<Typography.Title level={4} style={{ margin: 0, display: "flex", alignItems: "center" }}>
					<Space size="small">
						<span style={{ color: token.colorPrimary }}>SFMS</span>
						<span style={{ fontSize: "14px", fontWeight: "normal", color: token.colorTextSecondary }}>
							Facility Management System
						</span>
					</Space>
				</Typography.Title>
				<Space size="middle">
					<HealthIndicator />
					<ThemeToggle />
				</Space>
			</Header>

			<Content
				style={{
					display: "flex",
					justifyContent: "center",
					alignItems: "center",
					background: token.colorBgLayout,
				}}
			>
				<Card
					style={{
						width: 420,
						boxShadow: "0 6px 16px 0 rgba(0, 0, 0, 0.08), 0 3px 6px -4px rgba(0, 0, 0, 0.12)",
						borderRadius: 12,
					}}
				>
					<div style={{ textAlign: "center", marginBottom: 32 }}>
						<Typography.Title level={2} style={{ marginBottom: 8 }}>
							Welcome Back
						</Typography.Title>
						<Typography.Text type="secondary">SFMS 통합 계정으로 로그인해 주세요</Typography.Text>
					</div>

					<Form
						name="login"
						size="large"
						initialValues={{ remember: true }}
						onFinish={onFinish}
						layout="vertical"
					>
						<Form.Item
							name="login_id"
							rules={[{ required: true, message: "아이디를 입력해 주세요!" }]}
						>
							<Input prefix={<UserOutlined style={{ color: token.colorTextDisabled }} />} placeholder="아이디" />
						</Form.Item>

						<Form.Item
							name="password"
							rules={[{ required: true, message: "비밀번호를 입력해 주세요!" }]}
						>
							<Input.Password
								prefix={<LockOutlined style={{ color: token.colorTextDisabled }} />}
								placeholder="비밀번호"
							/>
						</Form.Item>

						<Form.Item>
							<Button type="primary" htmlType="submit" loading={loading} block style={{ height: 48, marginTop: 16 }}>
								로그인
							</Button>
						</Form.Item>
					</Form>

					<div style={{ textAlign: "center", marginTop: 24 }}>
						<Typography.Text type="secondary" style={{ fontSize: 12 }}>
							© {new Date().getFullYear()} SFMS Project. All rights reserved.
						</Typography.Text>
					</div>
				</Card>
			</Content>
		</Layout>
	);
};

export default LoginPage;
