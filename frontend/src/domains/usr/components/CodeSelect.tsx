import { useQuery } from "@tanstack/react-query";
import { Select } from "antd";
import type { SelectProps } from "antd";
import type React from "react";
import { getCodeDetails } from "@/domains/cmm/api";

interface CodeSelectProps extends SelectProps {
	/** 조회할 공통 코드 그룹 키 */
	groupCode: string;
	/** 비활성 코드 포함 여부 */
	includeInactive?: boolean;
}

/**
 * 시스템 공통 코드를 조회하여 선택 목록으로 표시하는 컴포넌트 (Zero Any 적용)
 */
const CodeSelect: React.FC<CodeSelectProps> = ({ 
	groupCode, 
	includeInactive = false, 
	placeholder = "선택하세요", 
	...rest 
}) => {
	const { data: codes, isLoading } = useQuery({
		queryKey: ["codeDetails", groupCode, includeInactive],
		queryFn: () => getCodeDetails(groupCode, includeInactive ? undefined : true),
	});

	// API 응답 데이터를 Ant Design Select 옵션 규격으로 변환
	const options = codes?.map((code) => ({
		label: code.detail_name,
		value: code.detail_code,
		disabled: !code.is_active,
	})) || [];

	return (
		<Select
			placeholder={placeholder}
			loading={isLoading}
			options={options}
			showSearch
			optionFilterProp="label"
			allowClear
			{...rest}
		/>
	);
};

export default CodeSelect;
