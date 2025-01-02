import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from './useBusinessProfile';
import type { InventoryItem } from '../types/inventory';

export function useInventory() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    if (businessProfile?.id) {
      fetchInventory();
      setError(null);
    }
  }, [businessProfile?.id]);

  async function fetchInventory() {
    if (!businessProfile?.id) return;
    
    try {
      const { data, error } = await supabase
        .from('inventory_items')
        .select(`
          *,
          category:category_id (
            id,
            name
          )
        `)
        .eq('business_id', businessProfile?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setItems(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return { items, loading, error, refetch: fetchInventory };
}