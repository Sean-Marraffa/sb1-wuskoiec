export type ReservationStatus = 'pending' | 'confirmed' | 'completed' | 'cancelled';
export type RateType = 'hourly' | 'daily' | 'weekly' | 'monthly';
export type DiscountType = 'percentage' | 'fixed';

export interface Reservation {
  id: string;
  business_id: string;
  customer_name: string;
  start_date: string;
  end_date: string;
  total_price: number;
  discount_amount?: number;
  discount_type?: DiscountType;
  status: ReservationStatus;
  reservation_items?: ReservationItem[];
  created_at: string;
  updated_at: string;
}

export interface ReservationItem {
  id: string;
  reservation_id: string;
  inventory_item_id: string;
  quantity: number;
  rate_type: RateType;
  rate_amount: number;
  subtotal: number;
  created_at: string;
  updated_at: string;
  inventory_item?: {
    name: string;
    hourly_rate: number | null;
    daily_rate: number | null;
    weekly_rate: number | null;
    monthly_rate: number | null;
  };
}