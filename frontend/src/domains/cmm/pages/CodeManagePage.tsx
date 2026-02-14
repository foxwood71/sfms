import React, { useState } from "react";
import {
  PageContainer,
  ProCard,
  ProTable,
  ModalForm,
  ProFormText,
  ProFormTextArea,
  ProFormSwitch,
} from "@ant-design/pro-components";
import type { ProColumns } from "@ant-design/pro-components";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { getCodeGroups, getCodeDetails, createCodeGroup } from "../api";
import type { CodeGroup, CodeDetail } from "../types";
import { Tag, Button, message } from "antd";
import { PlusOutlined } from "@ant-design/icons";

const CodeManagePage: React.FC = () => {
  const queryClient = useQueryClient(); // React Query 클라이언트 (목록 갱신용)
  // 선택된 그룹 코드 상태 관리
  const [selectedGroup, setSelectedGroup] = useState<string | null>(null);
  const [modalVisible, setModalVisible] = useState(false);

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

  // 3. 코드 그룹 생성 뮤테이션
  const createGroupMutation = useMutation({
    mutationFn: createCodeGroup,
    onSuccess: () => {
      message.success("저장되었습니다.");
      setModalVisible(false); // 모달 닫기
      queryClient.invalidateQueries({ queryKey: ["codeGroups"] }); // 목록 새로고침
    },
    onError: (error: any) => {
      message.error(
        "저장 실패: " + (error.response?.data?.detail || error.message),
      );
    },
  });

  // 4. 저장 버튼 클릭 시 실행될 함수
  const handleAddGroup = async (values: any) => {
    // API 호출
    await createGroupMutation.mutateAsync({
      ...values,
      is_system: false, // 기본값 설정
    });
    return true;
  };

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
    <PageContainer header={{ title: "공통 코드 관리" }}>
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
              <Button
                key="add"
                type="primary"
                icon={<PlusOutlined />}
                onClick={() => setModalVisible(true)}
              >
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
      {/* ✅ 그룹 추가 모달 */}
      <ModalForm
        title="새 코드 그룹 추가"
        open={modalVisible}
        onOpenChange={setModalVisible}
        onFinish={handleAddGroup} // 실제 저장 함수 연결
        modalProps={{ destroyOnClose: true }}
      >
        <ProFormText
          name="group_code"
          label="그룹 코드"
          placeholder="예: FAC_TYPE"
          required
          rules={[{ required: true, message: "그룹 코드를 입력해주세요" }]}
        />
        <ProFormText
          name="group_name"
          label="그룹명"
          placeholder="예: 시설 유형"
          required
          rules={[{ required: true, message: "그룹명을 입력해주세요" }]}
        />
        <ProFormTextArea name="description" label="설명" />
        <ProFormSwitch name="is_active" label="사용 여부" initialValue={true} />
      </ModalForm>
    </PageContainer>
  );
};

export default CodeManagePage;
