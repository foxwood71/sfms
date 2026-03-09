import React from "react";
import { TreeSelect, type TreeSelectProps } from "antd";
import { useQuery } from "@tanstack/react-query";
import { getOrganizationsApi } from "../api";
import type { Organization } from "../types";

/**
 * 조직 트리 셀렉트 Props
 */
interface OrgTreeSelectProps extends Omit<TreeSelectProps, "treeData"> {
	/** 활성 상태인 조직만 표시할지 여부 (기본값: true) */
	activeOnly?: boolean;
}

/**
 * 조직(부서) 선택을 위한 트리형 셀렉트 컴포넌트
 */
const OrgTreeSelect: React.FC<OrgTreeSelectProps> = ({ 
	activeOnly = true, 
	placeholder = "부서를 선택하세요",
	...props 
}) => {
	const { data, isLoading } = useQuery({
		queryKey: ["organizations", "tree", activeOnly],
		queryFn: () => getOrganizationsApi("tree", activeOnly),
		staleTime: 5 * 60 * 1000,
	});

	const mapOrgToTreeData = (orgs: Organization[]): any[] => {
		return orgs.map((org) => ({
			id: org.id,
			value: org.id,
			title: org.name,
			children: org.children && org.children.length > 0 ? mapOrgToTreeData(org.children) : undefined,
		}));
	};

	const treeData = React.useMemo(() => {
		if (!data?.data) return [];
		return mapOrgToTreeData(data.data);
	}, [data]);

	return (
		<TreeSelect
			{...props}
			showSearch
			style={{ width: "100%", ...props.style }}
			dropdownStyle={{ maxHeight: 400, overflow: "auto" }}
			placeholder={placeholder}
			allowClear
			treeDefaultExpandAll
			treeData={treeData}
			loading={isLoading}
			fieldNames={{ label: "title", value: "value", children: "children" }}
			filterTreeNode={(input, treeNode) =>
				(treeNode?.title as string)?.toLowerCase().indexOf(input.toLowerCase()) >= 0
			}
		/>
	);
};

export default OrgTreeSelect;
