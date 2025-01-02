import { useEffect, useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { supabase } from '../lib/supabase';

export function useIsSuperAdmin() {
  const { user } = useAuth();
  const [isSuperAdmin, setIsSuperAdmin] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    async function checkSuperAdmin() {
      try {
        if (!user) {
          if (mounted) {
            setIsSuperAdmin(false);
            setLoading(false);
          }
          return;
        }

        // Use the user from context instead of making another request
        if (mounted) {
          setIsSuperAdmin(user.user_metadata?.is_super_admin ?? false);
          setLoading(false);
        }
      } catch (err) {
        if (mounted) {
          console.error('Error checking super admin status:', err);
          setIsSuperAdmin(false);
          setLoading(false);
        }
      }
    }

    checkSuperAdmin();
    
    return () => {
      mounted = false;
    };
  }, [user]);

  return { isSuperAdmin, loading };
}