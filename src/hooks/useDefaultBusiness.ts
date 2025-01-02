import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import type { DefaultBusiness } from '../types/business';

export function useDefaultBusiness() {
  const [defaultBusiness, setDefaultBusinessState] = useState<DefaultBusiness | null>(null);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    if (user) {
      fetchDefaultBusiness();
    }
  }, [user]);

  async function fetchDefaultBusiness() {
    try {
      setLoading(true);

      // Check if user needs business profile
      if (user?.user_metadata?.needs_business_profile) {
        setDefaultBusinessState(null);
        return;
      }
      
      const { data, error } = await supabase
        .rpc('get_default_business');

      if (error) {
        // Ignore table not found errors
        if (error.code !== '42P01') {
          throw error;
        }
        return;
      }

      if (data && data.length > 0) {
        setDefaultBusinessState(data[0]);
      } else {
        setDefaultBusinessState(null);
      }
    } catch (err) {
      console.error('Error fetching default business:', err);
      setDefaultBusinessState(null);
    } finally {
      setLoading(false);
    }
  }

  const setDefaultBusiness = async (businessId: string) => {
    try {
      const { error } = await supabase
        .rpc('set_default_business', { 
          target_id: businessId 
        });

      if (error) throw error;
      await fetchDefaultBusiness();
    } catch (err) {
      console.error('Error setting default business:', err);
      throw err;
    }
  };

  return {
    defaultBusiness,
    loading,
    setDefaultBusiness,
    refetch: fetchDefaultBusiness
  };
}