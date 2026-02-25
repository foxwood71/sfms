import React from "react";
import { Outlet, useNavigate, useLocation } from "react-router-dom";
import { ProLayout } from "@ant-design/pro-components";
import {
  DashboardOutlined,
  BankOutlined,
  ToolOutlined,
  SettingOutlined,
  LogoutOutlined,
} from "@ant-design/icons";
import { Dropdown } from "antd";

export default function MainLayout() {
  const navigate = useNavigate();
  const location = useLocation();

  //  도메인별 메뉴 정의 (DDD 구조 반영)
  const route = {
    path: "/",
    routes: [
      {
        path: "/dashboard",
        name: "대시보드",
        icon: <DashboardOutlined />,
      },
      {
        path: "/fac",
        name: "시설 관리",
        icon: <BankOutlined />,
        routes: [
          { path: "/fac/list", name: "시설 목록" },
          { path: "/fac/register", name: "시설 등록" },
        ],
      },
      {
        path: "/eqp",
        name: "설비 관리",
        icon: <ToolOutlined />,
        routes: [
          { path: "/eqp/list", name: "설비 목록" },
          { path: "/eqp/maintenance", name: "유지보수 이력" },
        ],
      },
      {
        path: "/cmm",
        name: "시스템 관리",
        icon: <SettingOutlined />,
        routes: [
          { path: "/cmm/codes", name: "공통 코드" },
          { path: "/cmm/users", name: "사용자 관리" },
        ],
      },
    ],
  };

  return (
    <div style={{ height: "100vh" }}>
      <ProLayout
        title="SFMS"
        logo="https://gw.alipayobjects.com/zos/rmsportal/KDpgvguMpGfqaHPjicRK.svg" //  로고 이미지 교체 가능
        layout="mix" //  사이드바 + 헤더 혼합 모드
        splitMenus={false}
        route={route}
        location={location}
        menuItemRender={(item, dom) => (
          <div
            onClick={() => navigate(item.path || "/")}
            style={{ display: "flex", alignItems: "center", gap: 8 }}
          >
            {dom}
          </div>
        )}
        avatarProps={{
          src: "https://gw.alipayobjects.com/zos/antfincdn/efFD%24IOql2/weixintupian_20170331104822.jpg",
          size: "small",
          title: "관리자",
          render: (props, dom) => (
            <Dropdown
              menu={{
                items: [
                  {
                    key: "logout",
                    icon: <LogoutOutlined />,
                    label: "로그아웃",
                    onClick: () => alert("로그아웃 되었습니다."),
                  },
                ],
              }}
            >
              {dom}
            </Dropdown>
          ),
        }}
      >
        {/* 각 페이지 컴포넌트가 렌더링되는 위치 */}
        <Outlet />
      </ProLayout>
    </div>
  );
}
