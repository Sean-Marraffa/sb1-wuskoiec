import React, { useEffect, useState } from 'react';
import { Building2, Users } from 'lucide-react';
import { MetricCard } from '../components/MetricCard';
import { BusinessList } from '../components/business/BusinessList';
import { UsersList } from '../components/users/UsersList';
import { useBusinesses } from '../hooks/useBusinesses';
import { supabase } from '../lib/supabase';

export function PlatformDashboard() {
  const { businesses, loading: businessesLoading, refetch: refetchBusinesses } = useBusinesses();
  const [totalUsers, setTotalUsers] = useState<number | null>(null);
  const [activeView, setActiveView] = useState<'businesses' | 'users'>('businesses');
  const [loading, setLoading] = useState(true);

  const refreshData = async () => {
    await Promise.all([
      refetchBusinesses(),
      fetchTotalUsers()
    ]);
  };

  useEffect(() => {
    fetchTotalUsers();
  }, []);

  async function fetchTotalUsers() {
    try {
      const { data, error } = await supabase.rpc('get_total_users');
      if (error) throw error;
      setTotalUsers(data);
    } catch (err) {
      console.error('Error fetching total users:', err);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Platform Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Overview of all businesses on the platform
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
        <MetricCard
          title="Total Businesses"
          value={businesses?.length || 0}
          loading={businessesLoading}
          icon={Building2}
          isActive={activeView === 'businesses'}
          activeColor="indigo"
          onClick={() => setActiveView('businesses')}
        />
        
        <MetricCard
          title="Total Users"
          value={totalUsers}
          loading={loading}
          icon={Users}
          isActive={activeView === 'users'}
          activeColor="purple"
          onClick={() => setActiveView('users')}
        />
      </div>
      
      {activeView === 'businesses' ? (
        <BusinessList onDelete={refreshData} />
      ) : (
        <UsersList onDelete={refreshData} />
      )}
    </div>
  );
}