import React, { useState, useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Building2 } from 'lucide-react';
import { supabase } from '../lib/supabase';

interface TeamInvite {
  id: string;
  email: string;
  status: string;
  expires_at: string;
  business_id: string;
  business: {
    name: string;
  };
}

export function AcceptInvitePage() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [verifying, setVerifying] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [invite, setInvite] = useState<TeamInvite | null>(null);
  const [formData, setFormData] = useState({
    fullName: '',
    email: '', 
    password: '',
    confirmPassword: ''
  });
  const [existingUser, setExistingUser] = useState(false);

  const token = searchParams.get('token');

  useEffect(() => {
    if (token) {
      verifyInvite(token);
    }
  }, [token]);

  async function verifyInvite(token: string) {
    try {
      setVerifying(true);
      
      if (!token) {
        throw new Error('No token provided');
      }

      const { data, error } = await supabase
        .from('team_invites')
        .select(`
          id, 
          email, 
          status, 
          expires_at,
          business_id,
          business:businesses (
            name
          )
        `)
        .eq('invite_token', token)
        .eq('status', 'pending')
        .gt('expires_at', new Date().toISOString())
        .single();

      if (error) {
        if (error.code === 'PGRST116') {
          const { data: expiredInvite } = await supabase
            .from('team_invites')
            .select('status, expires_at')
            .eq('invite_token', token)
            .single();

          if (expiredInvite) {
            if (expiredInvite.status !== 'pending') {
              throw new Error('This invite has already been used');
            }
            if (new Date(expiredInvite.expires_at) <= new Date()) {
              throw new Error('This invite has expired');
            }
          }
          throw new Error('Invalid or expired invite');
        }
        throw error;
      }

      if (!data || !data.business) {
        throw new Error('Invalid invite or business not found');
      }
      
      // Check if user exists using admin function
      const { data: userExists, error: userCheckError } = await supabase
        .rpc('check_user_exists', { p_email: data.email });

      if (userCheckError) throw userCheckError;
      
      setExistingUser(userExists);

      setInvite(data);
      setFormData(prev => ({ ...prev, email: data.email }));
    } catch (err: any) {
      console.error('Error verifying invite:', err);
      setError(err.message || 'This invite link is invalid or has expired');
    } finally {
      setVerifying(false);
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!invite) return;

    if (!existingUser && formData.password !== formData.confirmPassword) {
      setError('Passwords do not match');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      if (existingUser) {
        // For existing users, sign in and accept invite
        const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
          email: invite.email,
          password: formData.password
        });

        if (signInError) throw signInError;

        // Accept invite using the RPC function
        const { data: acceptData, error: acceptError } = await supabase
          .rpc('accept_team_invite', {
            p_invite_token: token
          });

        if (acceptError) throw acceptError;
        if (!acceptData.success) throw new Error(acceptData.error);

        navigate('/dashboard');
      } else {
        // For new users, create account with invite token
        const { data: authData, error: signUpError } = await supabase.auth.signUp({
          email: invite.email,
          password: formData.password,
          options: {
            data: {
              full_name: formData.fullName,
              needs_business_profile: false,
              invite_token: token
            }
          }
        });

        if (signUpError) throw signUpError;
        if (!authData.user) throw new Error('Failed to create account');

        navigate('/dashboard');
      }
    } catch (err: any) {
      console.error('Error accepting invite:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
        <div className="max-w-md w-full space-y-8 text-center">
          <div className="flex justify-center">
            <Building2 className="h-12 w-12 text-red-600" />
          </div>
          <h2 className="mt-6 text-3xl font-extrabold text-gray-900">
            Invalid Invite
          </h2>
          <p className="mt-2 text-sm text-gray-600">{error}</p>
        </div>
      </div>
    );
  }

  if (verifying) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
      </div>
    );
  }

  if (!invite) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center text-gray-500">
          No valid invitation found
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <div className="flex justify-center">
            <Building2 className="h-12 w-12 text-indigo-600" />
          </div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            Accept Team Invitation
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600 mb-4">
            You've been invited by {invite.business.name} to join BookingVibe
          </p>
          {existingUser && (
            <div className="bg-blue-50 border border-blue-200 rounded-md p-4">
              <p className="text-sm text-blue-700">
                An account with this email already exists. Please sign in to accept the invitation.
              </p>
            </div>
          )}
        </div>

        <form className="mt-8 space-y-6" onSubmit={handleSubmit}>
          <div className="rounded-md shadow-sm -space-y-px">
            {!existingUser && <div>
              <label htmlFor="fullName" className="sr-only">
                Full Name
              </label>
              <input
                id="fullName"
                type="text"
                required
                value={formData.fullName}
                onChange={(e) => setFormData({ ...formData, fullName: e.target.value })}
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-t-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Full Name"
              />
            </div>}
            <div>
              <label htmlFor="email" className="sr-only">
                Email address
              </label>
              <input
                id="email"
                type="email"
                required
                disabled
                value={formData.email}
                className={`appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm bg-gray-50 ${existingUser ? 'rounded-t-md' : ''}`}
              />
            </div>
            <div>
              <label htmlFor="password" className="sr-only">
                Password
              </label>
              <input
                id="password"
                type="password"
                required
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                className={`appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm ${existingUser ? 'rounded-b-md' : ''}`}
                placeholder={existingUser ? 'Enter your password' : 'Create a password'}
              />
            </div>
            {!existingUser && <div>
              <label htmlFor="confirmPassword" className="sr-only">
                Confirm Password
              </label>
              <input
                id="confirmPassword"
                type="password"
                required
                value={formData.confirmPassword}
                onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
                className="appearance-none rounded-none relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 rounded-b-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 focus:z-10 sm:text-sm"
                placeholder="Confirm Password"
              />
            </div>}
          </div>

          <div>
            <button
              type="submit"
              disabled={loading}
              className="group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
            >
              {loading ? 'Processing...' : (existingUser ? 'Sign In & Accept' : 'Create Account & Accept')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}