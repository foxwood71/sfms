import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { App, Button, Card, Form, Input, Layout, Typography, theme, Space } from "antd";
import { LockOutlined, UserOutlined } from "@ant-design/icons";
import { loginApi, getMeApi } from "../api/auth";
import { useAuthStore } from "@/shared/stores/useAuthStore";
import ThemeToggle from "@/shared/layout/components/ThemeToggle";
import HealthIndicator from "@/shared/layout/components/HealthIndicator";

const { Content, Header } = Layout;
const { Title, Text } = Typography;

/**
 * 로그인 페이지 컴포넌트
 * 
 * @description 사용자 인증을 수행하고 토큰을 발급받아 메인 대시보드로 이동시킵니다.
 * 테마 전환 기능과 시스템 통신 상태 표시 기능을 제공합니다.
 */
const LoginPage: React.FC = () => {
	const [loading, setLoading] = useState(false);
	const navigate = useNavigate();
	const { message } = App.useApp();
	const setAuth = useAuthStore((state) => state.setAuth);
	const { token } = theme.useToken();

	/**
	 * 로그인 폼 제출 핸들러
	 */
	const onFinish = async (values: any) => {
		setLoading(true);
		try {
			const tokenInfo = await loginApi({
				login_id: values.loginId,
				password: values.password,
			});

			useAuthStore.setState({ accessToken: tokenInfo.access_token });
			const userData = await getMeApi();
			setAuth(tokenInfo.access_token, tokenInfo.refresh_token, userData);

			message.success(`${userData.name}님, 환영합니다!`);
			navigate("/");
		} catch (error: any) {
			console.error("Login failed:", error);
		} finally {
			setLoading(false);
		}
	};

	return (
		<Layout style={{ minHeight: "100vh" }}>
			<Header style={{ 
				background: "transparent", 
				display: "flex", 
				justifyContent: "flex-end", 
				padding: "0 24px",
				alignItems: "center"
			}}>
				<Space size="middle">
					<HealthIndicator />
					<ThemeToggle />
				</Space>
			</Header>
			<Content style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
				<Card
					style={{ 
						width: 400, 
						boxShadow: token.boxShadowTertiary, 
						borderRadius: token.borderRadiusLG,
						background: token.colorBgContainer
					}}
					bordered={false}
				>
					<div style={{ textAlign: "center", marginBottom: 32 }}>
						<Title level={2} style={{ margin: 0, color: token.colorPrimary }}>SFMS</Title>
						<Text type="secondary">스마트 시설 관리 시스템</Text>
					</div>

					<Form
						name="login_form"
						initialValues={{ remember: true }}
						onFinish={onFinish}
						layout="vertical"
						size="large"
					>
						<Form.Item
							name="loginId"
							rules={[{ required: true, message: "아이디를 입력해주세요!" }]}
						>
							<Input 
								prefix={<UserOutlined style={{ color: token.colorTextQuaternary }} />} 
								placeholder="로그인 아이디" 
							/>
						</Form.Item>

						<Form.Item
							name="password"
							rules={[{ required: true, message: "비밀번호를 입력해주세요!" }]}
						>
							<Input.Password
								prefix={<LockOutlined style={{ color: token.colorTextQuaternary }} />}
								placeholder="비밀번호"
							/>
						</Form.Item>

						<Form.Item>
							<Button
								type="primary"
								htmlType="submit"
								loading={loading}
								block
								style={{ marginTop: 8 }}
							>
								로그인
							</Button>
						</Form.Item>
					</Form>

					<div style={{ textAlign: "center", marginTop: 16 }}>
						<Text type="secondary" style={{ fontSize: 12 }}>
							© 2026 SFMS Phase 1. All Rights Reserved.
						</Text>
					</div>
				</Card>
			</Content>
		</Layout>
	);
};

export default LoginPage;
