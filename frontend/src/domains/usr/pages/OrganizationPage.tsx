import {
	ApartmentOutlined,
	ClusterOutlined,
	DeleteOutlined,
	EditOutlined,
	FilterOutlined,
	PlusOutlined,
	ReloadOutlined,
	SaveOutlined,
    CompressOutlined,
    ExpandOutlined,
    CloseOutlined,
} from "@ant-design/icons";
import { PageContainer, ProCard } from "@ant-design/pro-components";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
	App,
	Button,
	Empty,
	Input,
	Popconfirm,
	Space,
	Splitter,
	Switch,
	Tree,
	Tooltip,
	theme,
    Form,
} from "antd";
import type React from "react";
import { useMemo, useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import { LAYOUT_CONSTANTS } from "@/shared/constants/layout";
import {
	createOrganizationApi,
	deleteOrganizationApi,
	getOrganizationsApi,
	updateOrganizationApi,
} from "@/domains/usr/api";
import OrgFormCard from "@/domains/usr/components/OrgFormCard";
import type { CreateOrgParams, Organization, UpdateOrgParams } from "@/domains/usr/types";

/**
 * 부서(조직) 관리 페이지 (Final Integrated Master Standard)
 */
const OrganizationPage: React.FC = () => {
	const { t } = useTranslation();
	const { message } = App.useApp();
	const queryClient = useQueryClient();
	const { token } = theme.useToken();
	const [form] = Form.useForm(); 

	// 1. 상태 관리
	const [selectedKey, setSelectedKey] = useState<React.Key | null>(null);
	const [expandedKeys, setExpandedKeys] = useState<React.Key[]>([]);
    const [isAllExpanded, setIsAllExpanded] = useState(true);
	const [showFilter, setShowFilter] = useState(false);
	const [searchValue, setSearchValue] = useState("");
	const [showInactive, setShowInactive] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
	const [isAdding, setIsAdding] = useState(false);
    const [isFirstLoad, setIsInitialLoad] = useState(true);

	// 2. 데이터 조회
	const { data: orgResponse, isFetching } = useQuery({
		queryKey: ["organizations", "tree", showInactive],
		queryFn: () => getOrganizationsApi("tree", showInactive ? undefined : true),
	});

    // --- [재귀 탐색] 유틸리티 (로직 유실 방지) ---
    const getAllKeys = (items: Organization[]): React.Key[] => {
        const keys: React.Key[] = ["root"];
        const collect = (list: Organization[]) => {
            for (const item of list) {
                keys.push(String(item.id));
                if (item.children) collect(item.children);
            }
        };
        collect(items);
        return keys;
    };

    const findOrgInTree = (items: Organization[], idStr: string): Organization | null => {
        for (const item of items) {
            if (String(item.id) === idStr) return item;
            if (item.children && item.children.length > 0) {
                const found = findOrgInTree(item.children, idStr);
                if (found) return found;
            }
        }
        return null;
    };

    useEffect(() => {
        if (orgResponse?.data && isFirstLoad) {
            setExpandedKeys(getAllKeys(orgResponse.data));
            setIsInitialLoad(false);
        }
    }, [orgResponse?.data, isFirstLoad]);

	const selectedOrg = useMemo(() => {
		if (selectedKey === null || selectedKey === "root" || !orgResponse?.data) return null;
		return findOrgInTree(orgResponse.data, String(selectedKey));
	}, [selectedKey, orgResponse]);

    // [GUIDE] 시스템 노드(ID 0) 여부 판단
    const isSystemNode = selectedKey === "0";

	// 3. 트리 토글 로직
	const toggleExpandAll = () => {
		if (isAllExpanded) {
			setExpandedKeys(["root"]);
            setIsAllExpanded(false);
		} else {
            if (orgResponse?.data) {
                setExpandedKeys(getAllKeys(orgResponse.data));
                setIsAllExpanded(true);
            }
        }
	};

	// 4. Mutation 로직 (parent_id 보정 포함)
	const saveMutation = useMutation({
		mutationFn: (values: CreateOrgParams | UpdateOrgParams) => {
            // 저장 시 parent_id를 숫자로 변환하여 백엔드 규격 준수
            const payload = {
                ...values,
                parent_id: values.parent_id !== null ? Number(values.parent_id) : null
            };
			if (isAdding) return createOrganizationApi(payload as CreateOrgParams);
			return updateOrganizationApi(Number(selectedKey), payload as UpdateOrgParams);
		},
		onSuccess: () => {
			message.success(t("common.save_success"));
			setIsEditing(false);
			setIsAdding(false);
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || t("common.save_failure")),
	});

	const deleteMutation = useMutation({
		mutationFn: (id: number) => deleteOrganizationApi(id),
		onSuccess: () => {
			message.success(t("common.delete_success"));
			setSelectedKey(null);
			queryClient.invalidateQueries({ queryKey: ["organizations"] });
		},
		onError: (err: any) => message.error(err.response?.data?.message || t("common.delete_failure")),
	});

	// 5. 트리 데이터 가공
	const treeData = useMemo(() => {
		const filterTree = (items: Organization[]): any[] => {
			return items
				.map((item) => {
					const children = item.children ? filterTree(item.children) : [];
					const isMatched = item.name.toLowerCase().includes(searchValue.toLowerCase());
					if (!isMatched && children.length === 0) return null;
					return {
						key: String(item.id),
						title: item.is_active ? item.name : <span style={{ color: token.colorTextDisabled, textDecoration: "line-through" }}>{item.name}</span>,
						icon: <ClusterOutlined />,
						children,
					};
				})
				.filter(Boolean);
		};
		return [{ key: "root", title: t("user.root_org"), icon: <ApartmentOutlined />, children: filterTree(orgResponse?.data || []) }];
	}, [orgResponse, searchValue, token, t]);

	return (
		<PageContainer
			header={{ title: t("org.title") }}
			childrenContentStyle={{ padding: "0 24px 24px 24px", height: "calc(100vh - 140px)", overflow: "hidden" }}
		>
			<style>{`
                .ant-pro-card { height: 100% !important; display: flex !important; flex-direction: column !important; }
				.ant-pro-card-body { flex: 1 !important; display: flex !important; flex-direction: column !important; padding: 0 !important; overflow: hidden !important; }
                .ant-pro-card-header { 
                    padding: 0 20px !important; 
                    background: ${token.colorFillAlter} !important; 
                    border-bottom: 1px solid ${token.colorBorderSecondary} !important;
                    min-height: 56px !important;
                }
                .ant-pro-card-title { font-weight: 600 !important; }
                .ant-splitter-bar { background: ${token.colorBorderSecondary} !important; width: 1px !important; }
                .ant-splitter-bar:hover { background: ${token.colorPrimary} !important; }
			`}</style>

            <div style={{ 
                height: "100%", 
                background: token.colorBgContainer, 
                borderRadius: "12px", 
                border: `1px solid ${token.colorBorderSecondary}`, 
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
                boxShadow: "0 4px 12px rgba(0,0,0,0.05)"
            }}>
                <Splitter style={{ height: "100%", background: "transparent" }}>
                    {/* 좌측 패널: 트리 (15%~40% 조절 제한) */}
                    <Splitter.Panel defaultSize="30%" min="15%" max="40%">
                        <ProCard title={t("org.tree_title")} bordered={false} extra={
                            <Space size={4}>
                                <Tooltip title={isAllExpanded ? t("common.collapse_all") : t("common.expand_all")}>
                                    <Button type="text" size="small" icon={isAllExpanded ? <CompressOutlined /> : <ExpandOutlined />} onClick={toggleExpandAll} />
                                </Tooltip>
                                <Button type="text" size="small" icon={<FilterOutlined style={{ color: showFilter ? token.colorPrimary : undefined }} />} onClick={() => setShowFilter(!showFilter)} />
                                <Button type="text" size="small" icon={<ReloadOutlined />} onClick={() => queryClient.invalidateQueries({ queryKey: ["organizations"] })} loading={isFetching} />
                                
                                {/* [FIX] 시스템 노드 가이드 적용 */}
                                <Tooltip title={isSystemNode ? "시스템 전용 조직에는 하위 조직을 생성할 수 없습니다." : t("common.create")}>
                                    <Button 
                                        type="primary" 
                                        size="small" 
                                        icon={<PlusOutlined />} 
                                        disabled={isSystemNode}
                                        onClick={() => { 
                                            const currentIdStr = (selectedKey === "root" || selectedKey === null) ? null : String(selectedKey);
                                            setIsAdding(true); 
                                            setIsEditing(true); 
                                            form.resetFields();
                                            form.setFieldValue("parent_id", currentIdStr);
                                            form.setFieldValue("is_active", true);
                                            form.setFieldValue("sort_order", 10);
                                        }}
                                    >
                                        {t("common.create")}
                                    </Button>
                                </Tooltip>
                            </Space>
                        }>
                            <div style={{ flex: 1, overflowY: "auto", padding: "12px" }}>
                                <Tree showIcon blockNode showLine={{ showLeafIcon: false }} expandedKeys={expandedKeys} 
                                    onExpand={(keys) => { setExpandedKeys(keys); setIsAllExpanded(keys.length > 1); }} 
                                    treeData={treeData} selectedKeys={selectedKey !== null ? [selectedKey] : []}
                                    onSelect={(keys) => { if (keys.length > 0) { setSelectedKey(keys[0]); setIsEditing(false); setIsAdding(false); } }} />
                            </div>
                        </ProCard>
                    </Splitter.Panel>

                    <Splitter.Panel min="50%">
                        <ProCard
                            title={isAdding ? t("org.new_org") : t("org.detail_title")}
                            bordered={false}
                            // [FIX] Empty 중앙 배치를 위한 스타일 강제 적용
                            styles={{ body: { display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '100%' } }}
                            extra={
                                ((selectedKey !== null && selectedKey !== "root") || isAdding) ? (
                                    <Space size={8}>
                                        {!isEditing ? (
                                            <>
                                                <Popconfirm title={t("org.delete_confirm")} onConfirm={() => deleteMutation.mutate(Number(selectedKey))} disabled={selectedOrg?.children && selectedOrg.children.length > 0 || isSystemNode}>
                                                    <Button danger type="text" size="small" icon={<DeleteOutlined />} disabled={selectedOrg?.children && selectedOrg.children.length > 0 || isSystemNode}>{t("common.delete")}</Button>
                                                </Popconfirm>
                                                <Button type="primary" size="small" icon={<EditOutlined />} onClick={() => setIsEditing(true)}>{t("common.edit")}</Button>
                                            </>
                                        ) : (
                                            <>
                                                <Button size="small" icon={<CloseOutlined />} onClick={() => { setIsEditing(false); setIsAdding(false); }}>{t("common.cancel")}</Button>
                                                <Button type="primary" size="small" icon={<SaveOutlined />} loading={saveMutation.isPending} onClick={() => form.submit()}>{t("common.save")}</Button>
                                            </>
                                        )}
                                    </Space>
                                ) : <div style={{ height: 24 }} />
                            }
                        >
                            {selectedOrg || isAdding ? (
                                <div style={{ width: '100%', height: '100%', padding: "24px 32px", overflowY: "auto", alignSelf: 'flex-start' }}>
                                    <OrgFormCard 
                                        initialValues={isAdding ? { 
                                            parent_id: (selectedKey !== null && selectedKey !== "root") ? String(selectedKey) : null, 
                                            is_active: true, 
                                            sort_order: 10 
                                        } : { ...selectedOrg, parent_id: selectedOrg.parent_id !== null ? String(selectedOrg.parent_id) : null }}
                                        disabled={!isEditing} 
                                        onFinish={(values) => saveMutation.mutate(values)} 
                                        form={form} 
                                    />
                                </div>
                            ) : (
                                <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description={t("org.select_prompt")} />
                            )}
                        </ProCard>
                    </Splitter.Panel>
                </Splitter>
            </div>
		</PageContainer>
	);
};

export default OrganizationPage;
