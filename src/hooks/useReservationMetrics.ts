import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useDefaultBusiness } from './useDefaultBusiness';

interface ReservationCounts {
  draft: number;
  reserved: number;
  in_use: number;
  closed: number;
}

export function useReservationMetrics() {
  const [counts, setCounts] = useState<ReservationCounts>({
    draft: 0,
    reserved: 0,
    in_use: 0,
    closed: 0
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { defaultBusiness } = useDefaultBusiness();
  const [retryCount, setRetryCount] = useState(0);
  const MAX_RETRIES = 3;
  const RETRY_DELAY = 1000;

  useEffect(() => {
    if (defaultBusiness?.business_id) {
      fetchReservationCounts();
    } else {
      setCounts({
        draft: 0,
        reserved: 0,
        in_use: 0,
        closed: 0
      });
    }
  }, [defaultBusiness?.business_id, retryCount]);

  async function fetchReservationCounts() {
    try {
      console.log('Fetching reservations for business:', defaultBusiness?.business_id);

      const { data, error } = await supabase
        .from('reservations')
        .select('status')
        .eq('business_id', defaultBusiness?.business_id);

      if (error) throw error;

      console.log('Reservation data:', data);

      const newCounts = {
        draft: 0,
        reserved: 0,
        in_use: 0,
        closed: 0
      };

      data?.forEach(reservation => {
        if (reservation.status in newCounts) {
          newCounts[reservation.status as keyof ReservationCounts]++;
        }
      });

      setCounts(newCounts);
      setRetryCount(0);
    } catch (err: any) {
      setError(err.message);
      console.error('Error fetching reservation counts:', err);
      
      // Retry on error
      if (retryCount < MAX_RETRIES) {
        setTimeout(() => {
          setRetryCount(prev => prev + 1);
        }, RETRY_DELAY * Math.pow(2, retryCount));
      }
    } finally {
      setLoading(false);
    }
  }

  return { counts, loading, error };
}