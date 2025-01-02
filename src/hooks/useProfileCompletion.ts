import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface CompletionField {
  field_name: string;
  is_complete: boolean;
}

export function useProfileCompletion(businessId: string) {
  const [fields, setFields] = useState<CompletionField[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (businessId) {
      fetchCompletionStatus();
    }
  }, [businessId]);

  async function fetchCompletionStatus() {
    try {
      const { data, error } = await supabase
        .from('business_profile_completion')
        .select('*')
        .eq('business_id', businessId)
        .order('field_name');

      if (error) throw error;
      setFields(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return {
    fields,
    loading,
    error,
    refetch: fetchCompletionStatus
  };
}