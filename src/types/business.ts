export interface DefaultBusiness {
  business_id: string;
  business_name: string;
  role: string;
}

export type BusinessStatus = 'pending_setup' | 'profile_created' | 'active' | 'churned' | 'withdrawn';
export type SubscriptionInterval = 'monthly' | 'yearly';

export interface BusinessStatusInfo {
  label: string;
  description: string;
  color: string;
}

export interface Business {
  id: string;
  name: string;
  type: string;
  contact_email: string;
  street_address_1: string;
  street_address_2: string | null;
  city: string;
  state_province: string;
  postal_code: string;
  country: string;
  status: BusinessStatus;
  status_updated_at: string;
  created_at: string;
  updated_at: string;
  subscription?: {
    plan: {
      name: string;
      interval: string;
    };
    status: string;
  };
}