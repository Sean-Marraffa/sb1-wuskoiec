import React, { useState, useEffect } from 'react';
import { Send, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import { useBusinessProfile } from '../../hooks/useBusinessProfile';

interface TeamInvite {
  id: string;
  email: string;
  invite_token: string;
  status: string;
  created_at: string;
  expires_at: string;
}

export function TeamInvites() {
  const [email, setEmail] = useState('');
  const [invites, setInvites] = useState<TeamInvite[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { businessProfile } = useBusinessProfile();
  const [cancellingInvite, setCancellingInvite] = useState<string | null>(null);

  useEffect(() => {
    if (businessProfile?.id) {
      fetchInvites();
    }
  }, [businessProfile?.id]);

  async function fetchInvites() {
    try {
      const { data, error } = await supabase
        .from('team_invites')
        .select('*')
        .eq('business_id', businessProfile?.id)
        .eq('status', 'pending')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setInvites(data || []);
    } catch (err: any) {
      console.error('Error fetching invites:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!businessProfile?.id) return;

    try {
      setError(null);
      const { data, error } = await supabase
        .rpc('invite_team_member', {
          p_business_id: businessProfile.id,
          p_email: email
        });

      if (error) throw error;
      if (!data.success) throw new Error(data.error);

      await fetchInvites();
      setEmail('');
    } catch (err: any) {
      console.error('Error inviting team member:', err);
      setError(err.message);
    }
  };

  const handleCancelInvite = async (inviteId: string) => {
    if (!businessProfile?.id) return;
    if (!confirm('Are you sure you want to cancel this invite?')) return;

    try {
      setCancellingInvite(inviteId);
      setError(null);
      const { data, error } = await supabase
        .rpc('cancel_team_invite', {
          p_business_id: businessProfile.id,
          p_invite_id: inviteId
        });

      if (error) throw error;
      if (!data.success) throw new Error(data.error);

      await fetchInvites();
    } catch (err: any) {
      console.error('Error cancelling invite:', err);
      setError(err.message);
    } finally {
      setCancellingInvite(null);
    }
  };

  return (
    <div className="bg-white shadow rounded-lg">
      <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Invite Team Members</h3>
        <p className="mt-1 text-sm text-gray-500">
          Send invites to new team members
        </p>
      </div>

      <div className="p-4">
        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <div className="p-3 text-sm text-red-600 bg-red-50 rounded-md">
              {error}
            </div>
          )}

          <div>
            <label htmlFor="email" className="block text-sm font-medium text-gray-700">
              Email Address
            </label>
            <div className="mt-1 flex rounded-md shadow-sm">
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="flex-1 min-w-0 block w-full rounded-none rounded-l-md border border-gray-300 px-3 py-2 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                placeholder="colleague@example.com"
                required
              />
              <button
                type="submit"
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-r-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
          </div>
        </form>

        <div className="mt-6">
          <h4 className="text-sm font-medium text-gray-900">Pending Invites</h4>
          <div className="mt-2">
            {loading ? (
              <div className="animate-pulse space-y-4">
                <div className="h-4 bg-gray-200 rounded w-3/4"></div>
                <div className="h-4 bg-gray-200 rounded w-1/2"></div>
              </div>
            ) : invites.length === 0 ? (
              <p className="text-sm text-gray-500">No pending invites</p>
            ) : (
              <div className="space-y-2">
                {invites.map((invite) => (
                  <div
                    key={invite.id}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {invite.email}
                      </p>
                      <p className="text-xs text-gray-500">
                        Invite Token: {invite.invite_token}
                      </p>
                      <p className="text-xs text-gray-500">
                        Expires: {new Date(invite.expires_at).toLocaleDateString()}
                      </p>
                    </div>
                    <div className="flex items-center space-x-4">
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        Pending
                      </span>
                      <button
                        onClick={() => handleCancelInvite(invite.id)}
                        disabled={cancellingInvite === invite.id}
                        className="text-red-600 hover:text-red-900 disabled:opacity-50"
                        title="Cancel invite"
                      >
                        <Trash2 className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}