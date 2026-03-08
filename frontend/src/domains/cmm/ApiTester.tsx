import React, { useState } from "react";
import { Button, Card, Space, Typography, Tag, Divider, Upload, App } from "antd";
import { UploadOutlined, LoginOutlined, HeartOutlined, DatabaseOutlined, NotificationOutlined } from "@ant-design/icons";
import { http } from "../../shared/api/http";

const { Title, Text } = Typography;

const ApiTester: React.FC = () => {
  const { message } = App.useApp(); // [Added] 컨텍스트 기반 메시지 사용
  const [loading, setLoading] = useState<boolean>(false);
  const [response, setResponse] = useState<any>(null);
  const [token, setToken] = useState<string | null>(localStorage.getItem("accessToken"));

  // 1. 로그인 테스트 (admin / admin1234)
  const handleLogin = async () => {
    setLoading(true);
    try {
      const res = await http.post("/auth/login", {
        login_id: "admin",
        password: "admin1234",
      });
      const accessToken = res.data.data.access_token;
      setToken(accessToken);
      localStorage.setItem("accessToken", accessToken);
      message.success("로그인 성공! 토큰이 저장되었습니다.");
      setResponse(res.data);
    } catch (error: any) {
      setResponse(error.response?.data || error.message);
    } finally {
      setLoading(false);
    }
  };

  // 2. 헬스체크 테스트
  const handleHealthCheck = async () => {
    setLoading(true);
    try {
      const res = await http.get("/health");
      setResponse(res.data);
    } catch (error: any) {
      setResponse(error.response?.data || error.message);
    } finally {
      setLoading(false);
    }
  };

  // 3. 코드 그룹 조회 테스트 (CMM)
  const handleListCodes = async () => {
    if (!token) return message.warning("먼저 로그인해주세요.");
    setLoading(true);
    try {
      const res = await http.get("/cmm/codes", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setResponse(res.data);
    } catch (error: any) {
      setResponse(error.response?.data || error.message);
    } finally {
      setLoading(false);
    }
  };

  // 4. 알림 목록 조회 테스트 (CMM)
  const handleListNotifications = async () => {
    if (!token) return message.warning("먼저 로그인해주세요.");
    setLoading(true);
    try {
      const res = await http.get("/cmm/notifications", {
        headers: { Authorization: `Bearer ${token}` },
      });
      setResponse(res.data);
    } catch (error: any) {
      setResponse(error.response?.data || error.message);
    } finally {
      setLoading(false);
    }
  };

  // 5. 파일 업로드 테스트 (CMM)
  const customRequest = async (options: any) => {
    const { file, onSuccess, onError } = options;
    if (!token) return message.warning("먼저 로그인해주세요.");
    
    setLoading(true);
    const formData = new FormData();
    formData.append("file", file);

    try {
      const res = await http.post("/cmm/upload", formData, {
        headers: { 
          "Content-Type": "multipart/form-data",
          "Authorization": `Bearer ${token}` 
        },
        params: {
          domain_code: "CMM",
          resource_type: "TEST",
          ref_id: 1,
          category_code: "GENERAL"
        }
      });
      setResponse(res.data);
      onSuccess(res.data);
      message.success("파일 업로드 성공!");
    } catch (error: any) {
      setResponse(error.response?.data || error.message);
      onError(error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: "24px" }}>
      <Title level={2}>🚀 SFMS Backend API Tester</Title>
      <Text type="secondary">오늘 리팩토링된 API들을 리액트 환경에서 실시간으로 테스트합니다.</Text>
      
      <div style={{ marginTop: "24px", display: "flex", gap: "24px" }}>
        {/* 컨트롤 패널 */}
        <Card title="API Controls" style={{ width: "400px" }}>
          <Space direction="vertical" style={{ width: "100%" }} size="middle">
            <Text strong>인증 상태: </Text>
            {token ? <Tag color="green">로그인됨</Tag> : <Tag color="red">로그인 필요</Tag>}
            
            <Divider orientation="left">핵심 기능</Divider>
            <Button block type="primary" icon={<LoginOutlined />} onClick={handleLogin} loading={loading}>
              로그인 (admin / admin1234)
            </Button>
            <Button block icon={<HeartOutlined />} onClick={handleHealthCheck} loading={loading}>
              시스템 헬스체크
            </Button>
            
            <Divider orientation="left">CMM 도메인</Divider>
            <Button block icon={<DatabaseOutlined />} onClick={handleListCodes} loading={loading}>
              공통 코드 목록 조회
            </Button>
            <Button block icon={<NotificationOutlined />} onClick={handleListNotifications} loading={loading}>
              알림 목록 조회
            </Button>
            
            <Upload customRequest={customRequest} showUploadList={false}>
              <Button block icon={<UploadOutlined />} loading={loading}>
                파일 업로드 테스트
              </Button>
            </Upload>
            
            <Button block danger onClick={() => {
              localStorage.removeItem("accessToken");
              setToken(null);
              setResponse(null);
              message.info("로그아웃되었습니다.");
            }}>
              인증 정보 초기화
            </Button>
          </Space>
        </Card>

        {/* 결과 패널 */}
        <Card 
          title="Response JSON" 
          style={{ flex: 1, backgroundColor: "#fafafa", border: "1px solid #d9d9d9", overflow: "auto" }}
          extra={<Button size="small" onClick={() => setResponse(null)}>Clear</Button>}
        >
          {response ? (
            <pre style={{ 
              fontSize: "13px", 
              margin: 0, 
              whiteSpace: "pre-wrap", 
              wordBreak: "break-all",
              color: "#000",
              padding: "12px",
              backgroundColor: "#fff",
              borderRadius: "4px",
              border: "1px solid #f0f0f0"
            }}>
              {JSON.stringify(response, null, 2)}
            </pre>
          ) : (
            <div style={{ textAlign: "center", color: "#999", paddingTop: "40px" }}>
              API를 호출하면 여기에 결과가 표시됩니다.
            </div>
          )}
        </Card>
      </div>
    </div>
  );
};

export default ApiTester;
