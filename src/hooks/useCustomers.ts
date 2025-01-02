import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useDefaultBusiness } from './useDefaultBusiness';
import type { Customer } from '../types/customer';

export function useCustomers() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { defaultBusiness } = useDefaultBusiness();

  useEffect(() => {
    if (defaultBusiness?.business_id) {
      fetchCustomers();
    }
  }, [defaultBusiness?.business_id]);

  async function fetchCustomers() {
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('*')
        .eq('business_id', defaultBusiness?.business_id)
        .order('name');

      if (error) throw error;
      setCustomers(data || []);
    } catch (err: any) {
      console.error('Error fetching customers:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  const addCustomer = async (data: Partial<Customer>) => {
    try {
      const { error } = await supabase
        .from('customers')
        .insert([{ ...data, business_id: defaultBusiness?.business_id }]);

      if (error) throw error;
      await fetchCustomers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const updateCustomer = async (id: string, data: Partial<Customer>) => {
    try {
      const { error } = await supabase
        .from('customers')
        .update(data)
        .eq('id', id)
        .eq('business_id', defaultBusiness?.business_id);

      if (error) throw error;
      await fetchCustomers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const deleteCustomer = async (id: string) => {
    try {
      const { error } = await supabase
        .from('customers')
        .delete()
        .eq('id', id)
        .eq('business_id', defaultBusiness?.business_id);

      if (error) throw error;
      await fetchCustomers();
    } catch (err: any) {
      setError(err.message);
    }
  };

  return {
    customers,
    loading,
    error,
    addCustomer,
    updateCustomer,
    deleteCustomer,
    refetch: fetchCustomers
  };
}