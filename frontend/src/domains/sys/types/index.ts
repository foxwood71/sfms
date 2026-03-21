/**
 * 감사 로그(Audit Log) 관련 타입 정의
 */

export interface AuditLog {
	id: number;
	actor_user_id: number | null;
	action_type: string;
	target_domain: string;
	target_table: string;
	target_id: string;
	snapshot: Record<string, any>;
	client_ip: string | null;
	user_agent: string | null;
	description: string | null;
	created_at: string;
}

export interface AuditLogParams {
	start_date?: string;
	end_date?: string;
	actor_user_id?: number;
	target_domain?: string;
	action_type?: string;
	keyword?: string;
	page?: number;
	size?: number;
}

export interface AuditLogResponse {
	items: AuditLog[];
	total: number;
}
