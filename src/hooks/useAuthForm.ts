import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { getErrorMessage } from '../lib/auth';
import { supabase } from '../lib/supabase';

interface UseAuthFormReturn {
  email: string;
  password: string;
  fullName: string;
  error: string;
  loading: boolean;
  setEmail: (email: string) => void;
  setPassword: (password: string) => void;
  setFullName: (name: string) => void;
  handleSubmit: (e: React.FormEvent) => Promise<void>;
}

export function useAuthForm(isLogin: boolean): UseAuthFormReturn {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { signIn, signUp } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    let result = { error: null };

    try {
      if (isLogin) {
        result = await signIn(email, password);
        if (result.error) throw result.error;
        
        const { data: { user } } = await supabase.auth.getUser();
        
        const isSuperAdmin = user?.user_metadata?.is_super_admin ?? false;
        if (isSuperAdmin) {
          navigate('/platform');
        } else {
          navigate('/dashboard');
        }
      } else {
        result = await signUp(email, password, fullName);
        if (result.error) throw result.error;
        navigate('/onboarding');
      }
    } catch (err: any) {
      setError(getErrorMessage(err));
      result = { error: err };
    } finally {
      setLoading(false);
    }
    return result;
  };

  return {
    email,
    password,
    fullName,
    error,
    loading,
    setEmail,
    setPassword,
    setFullName,
    handleSubmit
  };
}