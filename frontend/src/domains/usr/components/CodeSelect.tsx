import { useQuery } from "@tanstack/react-query";
import { Select, type SelectProps } from "antd";
import React from "react";
import { getCodeDetails } from "../../cmm/api";

/**
 * 공통 코드 셀렉트 Props
 */
interface CodeSelectProps extends Omit<SelectProps, "options"> {
    groupCode: string;
    activeOnly?: boolean;
}

/**
 * 공통 코드를 조회하여 Select 옵션으로 렌더링하는 컴포넌트
 */
const CodeSelect: React.FC<CodeSelectProps> = ({
    groupCode,
    activeOnly = true,
    placeholder = "선택하세요",
    ...props
}) => {
    const { data, isLoading } = useQuery({
        queryKey: ["codeDetails", groupCode],
        queryFn: () => getCodeDetails(groupCode),
        staleTime: Infinity,
    });

    const options = React.useMemo(() => {
        if (!data) return [];
        const list = activeOnly ? data.filter((item) => item.is_active) : data;
        return list
            .sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
            .map((item) => ({
                label: item.detail_name,
                value: item.detail_code,
            }));
    }, [data, activeOnly]);

    return <Select {...props} loading={isLoading} placeholder={placeholder} options={options} />;
};

export default CodeSelect;
