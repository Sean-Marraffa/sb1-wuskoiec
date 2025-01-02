import React, { useState } from 'react';
import { BusinessSettingsForm } from '../components/forms/BusinessSettingsForm';
import { CategoryManager } from '../components/settings/CategoryManager';
import { ReservationStatusSettings } from '../components/settings/ReservationStatusSettings';
import { TeamMembersSection } from '../components/settings/TeamMembersSection';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { supabase } from '../lib/supabase';
import type { Category } from '../types/inventory';

export function Settings() {
  const { businessProfile, loading, error, updateBusinessProfile } = useBusinessProfile();
  const [updateError, setUpdateError] = useState<string | null>(null);
  const [updateSuccess, setUpdateSuccess] = useState(false);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loadingCategories, setLoadingCategories] = useState(true);

  React.useEffect(() => {
    if (businessProfile) {
      fetchCategories();
    }
  }, [businessProfile]);

  async function fetchCategories() {
    try {
      const { data, error } = await supabase
        .from('inventory_categories')
        .select('*')
        .eq('business_id', businessProfile?.id)
        .order('name');

      if (error) throw error;
      setCategories(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoadingCategories(false);
    }
  }

  const handleAddCategory = async (data: Partial<Category>) => {
    try {
      const { error } = await supabase
        .from('inventory_categories')
        .insert([{ ...data, business_id: businessProfile?.id }]);

      if (error) throw error;
      await fetchCategories();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleUpdateCategory = async (id: string, data: Partial<Category>) => {
    try {
      const { error } = await supabase
        .from('inventory_categories')
        .update(data)
        .eq('id', id);

      if (error) throw error;
      await fetchCategories();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleDeleteCategory = async (id: string) => {
    try {
      const { error } = await supabase
        .from('inventory_categories')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await fetchCategories();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleSubmit = async (data: any) => {
    setUpdateError(null);
    setUpdateSuccess(false);

    const { error } = await updateBusinessProfile(data);
    
    if (error) {
      setUpdateError(error);
      return { error };
    }

    setUpdateSuccess(true);
    return { error: null };
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-8 bg-gray-200 rounded w-1/4"></div>
        <div className="h-4 bg-gray-200 rounded w-1/2"></div>
        <div className="h-64 bg-gray-200 rounded"></div>
      </div>
    );
  }

  if (error || !businessProfile) {
    return (
      <div className="bg-red-50 p-4 rounded-md">
        <p className="text-sm text-red-600">
          {error || 'Failed to load business profile'}
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
        <p className="mt-1 text-sm text-gray-500">
          Update your business information and preferences
        </p>
      </div>

      {updateError && (
        <div className="bg-red-50 p-4 rounded-md">
          <p className="text-sm text-red-600">{updateError}</p>
        </div>
      )}

      {updateSuccess && (
        <div className="bg-green-50 p-4 rounded-md">
          <p className="text-sm text-green-600">
            Business information updated successfully
          </p>
        </div>
      )}

      <div className="bg-white shadow rounded-lg">
        <div className="divide-y divide-gray-200">
          {/* Business Information Section */}
          <div className="p-6">
            <h2 className="text-2xl font-semibold text-gray-900 mb-8">General</h2>
            <BusinessSettingsForm 
              business={businessProfile}
              onSubmit={handleSubmit}
            />
          </div>

          {/* Inventory Settings Section */}
          <div className="p-6">
            <h2 className="text-2xl font-semibold text-gray-900 mb-8">Inventory Settings</h2>
            <CategoryManager
              categories={categories}
              loading={loadingCategories}
              onAdd={handleAddCategory}
              onUpdate={handleUpdateCategory}
              onDelete={handleDeleteCategory}
            />
          </div>
          
          {/* Reservation Status Settings Section */}
          <div className="p-6">
            <h2 className="text-2xl font-semibold text-gray-900 mb-8">Reservation Settings</h2>
            <ReservationStatusSettings />
          </div>

          {/* Users Section */}
          <div className="p-6">
            <TeamMembersSection />
          </div>
        </div>
      </div>
    </div>
  );
}