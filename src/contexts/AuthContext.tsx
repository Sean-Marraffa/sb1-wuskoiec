import React, { createContext, useContext, useEffect, useState } from 'react';
import { AuthError, User } from '@supabase/supabase-js';
import { useNavigate, useLocation } from 'react-router-dom';
import { supabase } from '../lib/supabase';

interface AuthResponse {
  error: AuthError | null;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<AuthResponse>;
  signUp: (email: string, password: string, fullName: string) => Promise<AuthResponse>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isSuperAdmin, setIsSuperAdmin] = useState<boolean>(false);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const location = useLocation();
  const [session, setSession] = useState(null);

  useEffect(() => {
    let mounted = true;
    
    async function checkSession() {
      try {
        const { data: { session }, error } = await supabase.auth.getSession();
        if (error) throw error;
        if (!mounted) return;

        setSession(session);
        
        const currentUser = session?.user ?? null;
        setUser(currentUser);
        
        if (currentUser) {
          const isSuperAdmin = currentUser.user_metadata?.is_super_admin ?? false;
          setIsSuperAdmin(isSuperAdmin);
          
          // Handle routing based on user type
          if (isSuperAdmin && location.pathname === '/dashboard') {
            navigate('/platform', { replace: true });
          }
        }
      } catch (error) {
        console.error('Error checking auth session:', error);
      } finally {
        setLoading(false);
      }
    };

    checkSession();

    // Listen for auth changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (!mounted) return;
      
      setSession(session);
      const currentUser = session?.user ?? null;
      setUser(currentUser);
      
      if (event === 'SIGNED_OUT') {
        setUser(null);
        setSession(null);
        setIsSuperAdmin(false);
        navigate('/login');
        return;
      }
      
      if (currentUser) {
        const isSuperAdmin = currentUser.user_metadata?.is_super_admin ?? false;
        setIsSuperAdmin(isSuperAdmin);
        
        // Handle routing based on user type
        if (isSuperAdmin && location.pathname === '/dashboard') {
          navigate('/platform', { replace: true });
        }
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, [navigate, location.pathname]);

  const signIn = async (email: string, password: string): Promise<AuthResponse> => {
    try {
      const { error, data } = await supabase.auth.signInWithPassword({ 
        email, 
        password
      });
      
      if (error) return { error };
      if (!data.user) return { error: new Error('No user returned') as AuthError };
      
      return { error: null };
    } catch (error) {
      return { error: error as AuthError };
    }
  };

  const signUp = async (email: string, password: string, fullName: string): Promise<AuthResponse> => {
    try {
      const { error, data } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
            needs_business_profile: true
          },
          emailRedirectTo: `${window.location.origin}/dashboard`
        }
      });
      
      if (error) return { error };
      
      // If user is created but not confirmed, we still want to allow them to proceed
      // since email confirmation is disabled in Supabase
      if (!data.user && !data.session) {
        return { error: new Error('Failed to create account') as AuthError };
      }
      
      return { error: null };
    } catch (error) {
      return { error: error as AuthError };
    }
  };

  const signOut = async () => {
    try {
      setLoading(true);
      const { error } = await supabase.auth.signOut();
      if (error) throw error;
      
      // Clear local state
      setUser(null);
      setSession(null);
      setIsSuperAdmin(false);
      
      // Navigate after state is cleared
      navigate('/login');
    } catch (error) {
      console.error('Error during sign out:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const value = {
    user,
    loading,
    signIn,
    signUp,
    signOut
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}