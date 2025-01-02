export interface Category {
  id: string;
  business_id: string;
  name: string;
  description: string | null;
  created_at: string;
  updated_at: string;
}

export interface InventoryItem {
  id: string;
  business_id: string;
  category_id: string | null;
  name: string;
  description: string | null;
  quantity: number;
  hourly_rate: number | null;
  daily_rate: number | null;
  weekly_rate: number | null;
  monthly_rate: number | null;
  created_at: string;
  updated_at: string;
}

export type PricingPeriod = 'hourly' | 'daily' | 'weekly' | 'monthly';