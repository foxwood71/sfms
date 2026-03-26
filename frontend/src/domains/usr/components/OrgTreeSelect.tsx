import { useQuery } from "@tanstack/react-query";
import type { TreeSelectProps } from "antd";
import { TreeSelect } from "antd";
import type { DataNode } from "antd/es/tree";
import type React from "react";
import { useMemo } from "react";
import { getOrganizationsApi } from "@/domains/usr/api";
import type { Organization } from "@/domains/usr/types";

interface OrgTreeSelectProps extends TreeSelectProps {
	/** 비활성 부서 포함 여부 */
	includeInactive?: boolean;
}

/**
 * 조직(부서) 구조를 트리 선택 목록으로 표시하는 컴포넌트
 * [FIX] ID 0(시스템 관리) 처리 오류 방지를 위해 모든 value를 문자열로 관리합니다.
 */
const OrgTreeSelect: React.FC<OrgTreeSelectProps> = ({
	includeInactive = false,
	placeholder = "부서를 선택하세요",
	...rest
}) => {
	const { data: orgResponse, isLoading } = useQuery({
		queryKey: ["organizations", "tree", includeInactive],
		queryFn: () =>
			getOrganizationsApi("tree", includeInactive ? undefined : true),
	});

	// [FIX] key와 value를 명시적으로 String으로 변환하여 숫자 0의 함정 회피
	const treeData = useMemo(() => {
		const mapNodes = (items: Organization[]): DataNode[] => {
			return items.map((item) => ({
				title: item.name,
				value: String(item.id),
				key: String(item.id),
				disabled: !item.is_active,
				children: item.children ? mapNodes(item.children) : [],
			}));
		};
		return mapNodes(orgResponse?.data || []);
	}, [orgResponse]);

	return (
		<TreeSelect
			style={{ width: "100%" }}
			styles={{
				popup: {
					root: { maxHeight: 400, overflow: "auto" },
				},
			}}
			placeholder={placeholder}
			treeData={treeData}
			treeDefaultExpandAll
			loading={isLoading}
			allowClear
			showSearch
			treeNodeFilterProp="title"
			{...rest}
		/>
	);
};

export default OrgTreeSelect;
