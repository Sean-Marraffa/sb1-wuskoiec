import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import type { User } from '../types/user';

export function useUsers() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    try {
      const { data, error } = await supabase.rpc('get_user_details');
      if (error) throw error;
      setUsers(data || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  async function deleteUser(id: string) {
    try {
      setDeleteLoading(true);
      const { error } = await supabase.rpc('delete_user', { user_id: id });

      if (error) throw error;
      
      // Update local state after successful deletion
      setUsers(users.filter(u => u.id !== id));
      return { error: null };
    } catch (err: any) {
      console.error('Error deleting user:', err);
      return { error: err.message };
    } finally {
      setDeleteLoading(false);
    }
  }

  return { 
    users, 
    loading, 
    error, 
    deleteLoading,
    deleteUser,
    refetch: fetchUsers 
  };
}