import { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from './useBusinessProfile';
import type { TeamMember } from '../types/user';

export function useTeamMembers() {
  const [members, setMembers] = useState<TeamMember[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    if (businessProfile?.id) {
      fetchTeamMembers();
    }
  }, [businessProfile?.id]);

  async function fetchTeamMembers() {
    try {
      const { data, error } = await supabase
        .rpc('get_team_members', {
          p_business_id: businessProfile?.id
        });

      if (error) throw error;

      setMembers(data || []);
    } catch (err: any) {
      console.error('Error fetching team members:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return { members, loading, error, refetch: fetchTeamMembers };
}