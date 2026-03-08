import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { App, Button, Card, Form, Input, Layout, Typography } from "antd";
import { LockOutlined, UserOutlined } from "@ant-design/icons";
import { loginApi, getMeApi } from "../api/auth";
import { useAuthStore } from "@/shared/stores/useAuthStore";

const { Content } = Layout;
const { Title, Text } = Typography;

/**
 * 로그인 페이지 컴포넌트
 * 
 * @description 사용자 인증을 수행하고 토큰을 발급받아 메인 대시보드로 이동시킵니다.
 */
const LoginPage: React.FC = () => {
	const [loading, setLoading] = useState(false);
	const navigate = useNavigate();
	const { message } = App.useApp();
	const setAuth = useAuthStore((state) => state.setAuth);

	/**
	 * 로그인 폼 제출 핸들러
	 * 
	 * @param values { login_id, password }
	 */
	const onFinish = async (values: any) => {
		setLoading(true);
		try {
			// 1. 로그인 API 호출 (토큰 획득)
			const tokenInfo = await loginApi({
				login_id: values.loginId,
				password: values.password,
			});

			// 2. Zustand Store에 토큰 임시 저장 (getMe 호출을 위해)
			// 실제로는 setAuth가 한꺼번에 처리하지만, 내 정보를 가져와야 하므로 수동 처리
			useAuthStore.setState({ accessToken: tokenInfo.access_token });

			// 3. 내 정보 상세 조회
			const userData = await getMeApi();

			// 4. 최종 인증 상태 저장
			setAuth(tokenInfo.access_token, tokenInfo.refresh_token, userData);

			message.success(`${userData.name}님, 환영합니다!`);
			navigate("/");
		} catch (error: any) {
			// 에러 처리는 http 인터셉터에서 이미 알림을 띄우지만, 추가 처리가 필요할 경우 여기서 함
			console.error("Login failed:", error);
		} finally {
			setLoading(false);
		}
	};

	return (
		<Layout style={{ minHeight: "100vh", background: "#f0f2f5" }}>
			<Content style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
				<Card
					style={{ width: 400, boxShadow: "0 4px 12px rgba(0,0,0,0.15)", borderRadius: 8 }}
					bordered={false}
				>
					<div style={{ textAlign: "center", marginBottom: 32 }}>
						<Title level={2} style={{ margin: 0, color: "#1890ff" }}>SFMS</Title>
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
								prefix={<UserOutlined style={{ color: "rgba(0,0,0,.25)" }} />} 
								placeholder="로그인 아이디" 
							/>
						</Form.Item>

						<Form.Item
							name="password"
							rules={[{ required: true, message: "비밀번호를 입력해주세요!" }]}
						>
							<Input.Password
								prefix={<LockOutlined style={{ color: "rgba(0,0,0,.25)" }} />}
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
