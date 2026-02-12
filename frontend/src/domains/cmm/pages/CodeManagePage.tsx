import React, { useState } from "react";
import { ProCard, ProTable } from "@ant-design/pro-components";
import type { ProColumns } from "@ant-design/pro-components";
import { useQuery } from "@tanstack/react-query";
import { getCodeGroups, getCodeDetails } from "../api";
import type { CodeGroup, CodeDetail } from "../types";
import { Tag, Button } from "antd";
import { PlusOutlined } from "@ant-design/icons";

const CodeManagePage: React.FC = () => {
  // 선택된 그룹 코드 상태 관리
  const [selectedGroup, setSelectedGroup] = useState<string | null>(null);

  // 1. 코드 그룹 데이터 가져오기 (React Query)
  const { data: groups, isLoading: isGroupLoading } = useQuery({
    queryKey: ["codeGroups"],
    queryFn: getCodeGroups,
  });

  // 2. 선택된 그룹의 상세 코드 가져오기
  const { data: details, isLoading: isDetailLoading } = useQuery({
    queryKey: ["codeDetails", selectedGroup],
    queryFn: () => getCodeDetails(selectedGroup!),
    enabled: !!selectedGroup, // 그룹이 선택되었을 때만 실행
  });

  // 테이블 컬럼 정의: 코드 그룹
  const groupColumns: ProColumns<CodeGroup>[] = [
    {
      title: "그룹 코드",
      dataIndex: "group_code",
      copyable: true,
      width: 120,
    },
    {
      title: "그룹명",
      dataIndex: "group_name",
      ellipsis: true,
    },
    {
      title: "상태",
      dataIndex: "is_active",
      width: 80,
      render: (_, record) => (
        <Tag color={record.is_active ? "green" : "red"}>
          {record.is_active ? "사용" : "미사용"}
        </Tag>
      ),
    },
  ];

  // 테이블 컬럼 정의: 상세 코드
  const detailColumns: ProColumns<CodeDetail>[] = [
    {
      title: "상세 코드",
      dataIndex: "detail_code",
      width: 100,
    },
    {
      title: "코드명",
      dataIndex: "detail_name",
    },
    {
      title: "정렬",
      dataIndex: "sort_order",
      width: 80,
      align: "center",
    },
    {
      title: "상태",
      dataIndex: "is_active",
      width: 80,
      valueEnum: {
        true: { text: "사용", status: "Success" },
        false: { text: "미사용", status: "Error" },
      },
    },
  ];

  return (
    <ProCard ghost gutter={8} style={{ height: "calc(100vh - 100px)" }}>
      {/* 좌측 패널: 코드 그룹 목록 */}
      <ProCard colSpan={10} title="코드 그룹" headerBordered>
        <ProTable<CodeGroup>
          rowKey="group_code"
          columns={groupColumns}
          dataSource={groups}
          loading={isGroupLoading}
          search={false} // 검색창 숨김 (심플하게)
          options={false} // 설정 버튼 숨김
          pagination={{ pageSize: 10 }}
          toolBarRender={() => [
            <Button key="add" type="primary" icon={<PlusOutlined />}>
              그룹 추가
            </Button>,
          ]}
          onRow={(record) => ({
            onClick: () => setSelectedGroup(record.group_code),
            style: {
              cursor: "pointer",
              backgroundColor:
                selectedGroup === record.group_code ? "#e6f7ff" : "inherit",
            },
          })}
        />
      </ProCard>

      {/* 우측 패널: 상세 코드 목록 */}
      <ProCard
        colSpan={14}
        title={selectedGroup ? `[${selectedGroup}] 상세 코드` : "상세 코드"}
        headerBordered
      >
        {selectedGroup ? (
          <ProTable<CodeDetail>
            rowKey="detail_code"
            columns={detailColumns}
            dataSource={details}
            loading={isDetailLoading}
            search={false}
            options={false}
            pagination={false}
            toolBarRender={() => [
              <Button key="add" icon={<PlusOutlined />}>
                코드 추가
              </Button>,
            ]}
          />
        ) : (
          <div style={{ textAlign: "center", padding: 50, color: "#999" }}>
            좌측에서 그룹을 선택해주세요.
          </div>
        )}
      </ProCard>
    </ProCard>
  );
};

export default CodeManagePage;
