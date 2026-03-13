import { LockOutlined, UserOutlined } from "@ant-design/icons";
import {
	LoginForm,
	ProFormCheckbox,
	ProFormText,
} from "@ant-design/pro-components";
import { useMutation } from "@tanstack/react-query";
import { App, theme } from "antd";
import type React from "react";
import { useTranslation } from "react-i18next";
import { useNavigate } from "react-router-dom";
import { http } from "@/shared/api/http";
import { useAuthStore } from "@/shared/stores/useAuthStore";
import { getMeApi, loginApi } from "../api/auth";
import type { LoginFormValues } from "../types";

/**
 * 로그인 페이지 컴포넌트 (react-i18next 적용)
 */
const LoginPage: React.FC = () => {
	const { t } = useTranslation();
	const { token } = theme.useToken();
	const navigate = useNavigate();
	const { message } = App.useApp();
	const setAuth = useAuthStore((state) => state.setAuth);

	const loginMutation = useMutation({
		mutationFn: async (values: LoginFormValues) => {
			// 1. 로그인 실행 및 응답 획득 (이미 res.data가 반환됨)
			const loginRes = await loginApi({
				login_id: values.login_id,
				password: values.password,
			});

			// APIResponse 규격에 따라 loginRes.data 안에 토큰이 들어있음
			const { access_token, refresh_token } = loginRes.data;

			if (!access_token) {
				throw new Error(t("auth.token_error"));
			}

			// 2. HTTP 클라이언트에 토큰 즉시 강제 주입
			http.defaults.headers.common.Authorization = `Bearer ${access_token}`;
			
			// 3. 스토어 우선 업데이트
			setAuth(access_token, refresh_token, null);

			// 4. 내 정보 조회 (인터셉터가 동작하므로 토큰 따로 보낼 필요 없음)
			const userRes = await getMeApi();

			return {
				accessToken: access_token,
				refreshToken: refresh_token,
				user: userRes.data,
			};
		},
		onSuccess: (data) => {
			// 5. 최종 인증 정보 완성
			setAuth(data.accessToken, data.refreshToken, data.user as any);
			message.success(t("auth.login_success"));

			// [가장 확실한 방법] 강제 새로고침을 통해 상태 초기화 및 메인 이동
			window.location.href = "/";
		},
		onError: (err: any) => {
			console.error("Login Mutation Error:", err);
			const status = err.response?.status;

			// 에러 발생 시 주입했던 헤더 제거
			delete http.defaults.headers.common["Authorization"];

			if (status === 401) {
				if (err.config?.url?.includes("/auth/login")) {
					message.error(t("auth.login_failure"));
				} else {
					message.error(t("auth.info_fetch_failure"));
				}
			} else {
				message.error(err.response?.data?.message || t("common.fetch_failure"));
			}
		},
	});

	return (
		<div
			style={{
				backgroundColor: token.colorBgLayout,
				height: "100vh",
				display: "flex",
				justifyContent: "center",
				alignItems: "center",
			}}
		>
			<style>{`body { overflow: hidden !important; }`}</style>
			<LoginForm<LoginFormValues>
				title="SFMS"
				subTitle={t("auth.subtitle")}
				onFinish={async (values) => {
					await loginMutation.mutateAsync(values);
					return true;
				}}
				submitter={{ searchConfig: { submitText: t("auth.login") } }}
			>
				<ProFormText
					name="login_id"
					fieldProps={{
						size: "large",
						prefix: <UserOutlined />,
						autoComplete: "username",
					}}
					placeholder={t("auth.id_placeholder")}
					rules={[{ required: true, message: t("auth.id_placeholder") }]}
				/>
				<ProFormText.Password
					name="password"
					fieldProps={{
						size: "large",
						prefix: <LockOutlined />,
						autoComplete: "current-password",
					}}
					placeholder={t("auth.pwd_placeholder")}
					rules={[{ required: true, message: t("auth.pwd_placeholder") }]}
				/>
				<div style={{ marginBottom: 24 }}>
					<ProFormCheckbox noStyle name="remember">
						{t("auth.remember_me")}
					</ProFormCheckbox>
					<a style={{ float: "right" }}>
						{t("auth.forgot_password")}
					</a>
				</div>
			</LoginForm>
		</div>
	);
};

export default LoginPage;
