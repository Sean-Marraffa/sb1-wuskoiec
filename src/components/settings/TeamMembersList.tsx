import React from 'react';
import { Trash2 } from 'lucide-react';
import { useTeamMembers } from '../../hooks/useTeamMembers';
import { useBusinessProfile } from '../../hooks/useBusinessProfile';
import { supabase } from '../../lib/supabase';

export function TeamMembersList() {
  const { members, loading, refetch } = useTeamMembers();
  const { businessProfile } = useBusinessProfile();
  const [error, setError] = React.useState<string | null>(null);

  const handleRemove = async (userId: string) => {
    if (!businessProfile?.id) return;
    if (!confirm('Are you sure you want to remove this team member?')) return;

    try {
      setError(null);
      const { data, error } = await supabase
        .rpc('remove_team_member', {
          p_business_id: businessProfile.id,
          p_user_id: userId
        });

      if (error) throw error;
      if (!data.success) throw new Error(data.error);

      await refetch();
    } catch (err: any) {
      console.error('Error removing team member:', err);
      setError(err.message);
    }
  };

  return (
    <div className="bg-white shadow rounded-lg">
      <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
        <h3 className="text-lg font-medium text-gray-900">Team Members</h3>
        <p className="mt-1 text-sm text-gray-500">
          Current members of your team
        </p>
        {error && (
          <div className="mt-2 p-2 text-sm text-red-600 bg-red-50 rounded">
            {error}
          </div>
        )}
      </div>
      
      <div className="divide-y divide-gray-200">
        {loading ? (
          <div className="p-4">
            <div className="animate-pulse space-y-4">
              <div className="h-4 bg-gray-200 rounded w-3/4"></div>
              <div className="h-4 bg-gray-200 rounded w-1/2"></div>
            </div>
          </div>
        ) : members.length === 0 ? (
          <div className="p-4 text-center text-sm text-gray-500">
            No team members yet
          </div>
        ) : (
          members.map((member) => (
            <div key={member.user_id} className="p-4">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-sm font-medium text-gray-900">
                    {member.full_name}
                  </h4>
                  <p className="text-sm text-gray-500">
                    {member.email}
                  </p>
                </div>
                <div className="flex items-center space-x-4">
                  <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Active
                  </span>
                  <button
                    onClick={() => handleRemove(member.user_id)}
                    className="text-red-600 hover:text-red-900"
                    title="Remove team member"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}