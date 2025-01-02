import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import type { Business } from '../types/business';
import { useCallback } from 'react';

export function useBusinessProfile() {
  const [businessProfile, setBusinessProfile] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { user } = useAuth();
  const [retryCount, setRetryCount] = useState(0);
  const MAX_RETRIES = 3;
  const RETRY_DELAY = 1000; // 1 second

  // Reset state when user changes
  useEffect(() => {
    if (!user) {
      setBusinessProfile(null);
      setError(null);
      setLoading(false);
      setRetryCount(0);
    }
  }, [user]);

  const fetchBusinessProfile = useCallback(async () => {
    if (!user) {
      setBusinessProfile(null);
      setLoading(false);
      return;
    }
    
    try {
      // Check if user needs business profile
      if (user.user_metadata?.needs_business_profile) {
        setBusinessProfile(null);
        setLoading(false);
        return;
      }

      const { data, error } = await supabase
        .rpc('get_default_business');

      if (error) throw error;

      if (!data || data.length === 0) {
        // No business found - this is a valid state
        setBusinessProfile(null);
        setLoading(false);
        return;
      }

      const { business_id } = data[0];

      const { data: profile, error: profileError } = await supabase
        .from('businesses')
        .select('*')
        .eq('id', business_id)
        .single();

      if (profileError) throw profileError;

      setBusinessProfile(profile);
      setError(null);
      setRetryCount(0);
    } catch (err: any) {
      console.error('Error in fetchBusinessProfile:', err);
      // Only set error for unexpected failures
      if (err.code !== '42P01') { // Ignore table not found errors
        setError(err.message);
      }
      
      // Retry logic
      if (retryCount < MAX_RETRIES) {
        setTimeout(() => {
          setRetryCount(prev => prev + 1);
          fetchBusinessProfile();
        }, RETRY_DELAY * Math.pow(2, retryCount));
      }
    } finally {
      setLoading(false);
    }
  }, [user, retryCount]);

  useEffect(() => {
    fetchBusinessProfile();
  }, [fetchBusinessProfile]);

  const updateBusinessProfile = async (updates: Partial<Business>) => {
    if (!businessProfile) {
      return { error: 'No business profile found' };
    }

    try {
      const { error } = await supabase
        .from('businesses')
        .update(updates)
        .eq('id', businessProfile.id);

      if (error) throw error;

      setBusinessProfile({ ...businessProfile, ...updates });
      return { error: null };
    } catch (err: any) {
      return { error: err.message };
    }
  };

  return { businessProfile, loading, error, updateBusinessProfile };
}