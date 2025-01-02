import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { Business } from '../types/business';

export function useBusinesses() {
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    fetchBusinesses();
  }, []);

  async function fetchBusinesses() {
    try {
      const { data, error } = await supabase
        .from('businesses')
        .select(`
          *,
          subscription:business_subscriptions(
            status,
            plan:plan_id(
              name,
              interval
            )
          )
        `)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setBusinesses(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function deleteBusiness(id: string) {
    try {
      setDeleteLoading(true);
      const { error } = await supabase
        .from('businesses')
        .delete()
        .eq('id', id);

      if (error) throw error;
      
      // Update local state after successful deletion
      setBusinesses(businesses.filter(b => b.id !== id));
      return { error: null };
    } catch (err: any) {
      console.error('Error deleting business:', err);
      return { error: err.message };
    } finally {
      setDeleteLoading(false);
    }
  }

  return { 
    businesses, 
    loading, 
    error, 
    deleteLoading,
    deleteBusiness,
    refetch: fetchBusinesses 
  };
}