import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useDefaultBusiness } from './useDefaultBusiness';
import type { Reservation } from '../types/reservation';

export function useReservations(status: string) {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { defaultBusiness } = useDefaultBusiness();

  useEffect(() => {
    console.log('Default business:', defaultBusiness);
    if (defaultBusiness?.business_id) {
      fetchReservations();
    }
  }, [defaultBusiness?.business_id, status]);

  async function fetchReservations() {
    try {
      console.log('Fetching reservations for business:', defaultBusiness?.business_id, 'with status:', status);
      let query = supabase
        .from('reservations')
        .select(`
          *,
          reservation_items(
            id,
            inventory_item_id,
            quantity,
            rate_type,
            rate_amount,
            subtotal,
            inventory_item:inventory_items(
              id,
              name,
              hourly_rate,
              daily_rate,
              weekly_rate,
              monthly_rate
            )
          )
        `)
        .eq('business_id', defaultBusiness?.business_id)
        .order('created_at', { ascending: false });

      // Always filter by status
      query = query.eq('status', status);

      const { data, error } = await query;
      console.log('Reservations response:', { data, error });

      if (error) throw error;
      setReservations(data || []);
    } catch (err: any) {
      console.error('Error fetching reservations:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return { reservations, loading, error, refetch: fetchReservations };
}