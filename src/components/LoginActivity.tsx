import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface LoginActivity {
  id: string;
  ip_address: string;
  user_agent: string;
  status: 'success' | 'failed';
  created_at: string;
}

export function LoginActivity() {
  const [activities, setActivities] = useState<LoginActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchLoginActivity();
  }, []);

  async function fetchLoginActivity() {
    try {
      const { data, error } = await supabase
        .from('login_activity')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(10);

      if (error) throw error;
      setActivities(data || []);
    } catch (err: any) {
      console.error('Error fetching login activity:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-4 bg-gray-200 rounded w-1/4"></div>
        <div className="space-y-2">
          {[...Array(5)].map((_, i) => (
            <div key={i} className="h-8 bg-gray-200 rounded"></div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 p-4 rounded-md">
        <p className="text-sm text-red-600">{error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Recent Login Activity</h3>
      
      <div className="bg-white shadow overflow-hidden rounded-md">
        <ul className="divide-y divide-gray-200">
          {activities.length === 0 ? (
            <li className="px-6 py-4 text-sm text-gray-500">
              No login activity found
            </li>
          ) : (
            activities.map((activity) => (
              <li key={activity.id} className="px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex flex-col">
                    <div className="text-sm font-medium text-gray-900">
                      {new Date(activity.created_at).toLocaleString()}
                    </div>
                    <div className="text-sm text-gray-500">
                      IP: {activity.ip_address || 'Unknown'}
                    </div>
                  </div>
                  <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                    activity.status === 'success' 
                      ? 'bg-green-100 text-green-800'
                      : 'bg-red-100 text-red-800'
                  }`}>
                    {activity.status === 'success' ? 'Successful' : 'Failed'}
                  </span>
                </div>
                <div className="mt-1 text-xs text-gray-500 truncate">
                  {activity.user_agent || 'Unknown device'}
                </div>
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}