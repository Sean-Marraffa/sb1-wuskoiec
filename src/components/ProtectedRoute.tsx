import { useState, useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useIsSuperAdmin } from '../hooks/useIsSuperAdmin';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { supabase } from '../lib/supabase';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  const { isSuperAdmin } = useIsSuperAdmin();
  const { businessProfile, loading: loadingProfile } = useBusinessProfile();
  const [userRole, setUserRole] = useState<string | null>(null);
  const location = useLocation();

  useEffect(() => {
    if (user && !user.user_metadata?.needs_business_profile) {
      checkUserRole();
    }
  }, [user]);

  async function checkUserRole() {
    try {
      const { data } = await supabase
        .from('business_users')
        .select('role')
        .eq('user_id', user?.id)
        .single();

      setUserRole(data?.role);
    } catch (err) {
      console.error('Error checking user role:', err);
    }
  }

  // Prevent super admins from accessing business profile setup
  if (isSuperAdmin && location.pathname === '/setup-business') {
    return <Navigate to="/platform" />;
  }

  if (loading || loadingProfile) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" />;
  }

  // Handle onboarding flow
  const isTeamMember = userRole === 'Team Member';
  const isAccountOwner = userRole === 'Account Owner';

  if (!isSuperAdmin && isAccountOwner) {
    // Step 1: Business Profile Setup
    if (user.user_metadata?.needs_business_profile && location.pathname !== '/onboarding') {
      return <Navigate to="/onboarding" />;
    }
    
    // Step 2: Billing Setup
    if (!user.user_metadata?.needs_business_profile && 
        !user.user_metadata?.has_billing &&
        location.pathname !== '/onboarding') {
      return <Navigate to="/onboarding" />;
    }
    
    // Prevent accessing setup pages if already completed
    if (!user.user_metadata?.needs_business_profile && user.user_metadata?.has_billing) {
      if (location.pathname === '/onboarding') {
        return <Navigate to="/dashboard" />;
      }
    }
  }

  return <>{children}</>;
}