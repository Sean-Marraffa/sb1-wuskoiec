import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from './useBusinessProfile';

interface StatusSetting {
  status_key: string;
  label: string;
}

const DEFAULT_SETTINGS: StatusSetting[] = [
  { status_key: 'draft', label: 'Proposal' },
  { status_key: 'reserved', label: 'Reserved' },
  { status_key: 'in_use', label: 'Checked Out' },
  { status_key: 'closed', label: 'Checked In' }
];

export function useReservationStatusSettings() {
  const [statusSettings, setStatusSettings] = useState<StatusSetting[]>(DEFAULT_SETTINGS);
  const [loading, setLoading] = useState(true);
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    if (businessProfile?.id) {
      fetchStatusSettings();
    }
  }, [businessProfile?.id]);

  async function fetchStatusSettings() {
    try {
      const { data, error } = await supabase
        .from('reservation_status_settings')
        .select('status_key, label')
        .eq('business_id', businessProfile?.id);

      if (error) throw error;

      // If no custom settings, use defaults
      if (!data || data.length === 0) {
        setStatusSettings(DEFAULT_SETTINGS);
      } else {
        setStatusSettings(data);
      }
    } catch (err) {
      console.error('Error fetching status settings:', err);
      // Fallback to defaults on error
      setStatusSettings(DEFAULT_SETTINGS);
    } finally {
      setLoading(false);
    }
  }

  return { statusSettings, loading };
}