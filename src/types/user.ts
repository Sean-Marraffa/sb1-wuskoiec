export interface UserCreateData {
  name: string;
  email: string;
  password: string;
}

export interface User {
  id: string;
  email: string;
  full_name: string;
  created_at: string;
  business_name: string | null;
}

export interface AuditLog {
  id: string;
  action: string;
  business_id: string;
  performed_by: string;
  target_user_id?: string;
  details: Record<string, any>;
  created_at: string;
}

export interface TeamMember {
  user_id: string;
  email: string;
  full_name: string;
  created_at: string;
}