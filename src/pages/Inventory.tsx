import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { InventoryTable } from '../components/inventory/InventoryTable';
import { InventoryForm } from '../components/inventory/InventoryForm';
import type { InventoryItem, Category } from '../types/inventory';

export function Inventory() {
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [editingItem, setEditingItem] = useState<InventoryItem | null>(null);
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    if (businessProfile) {
      fetchInventory();
      fetchCategories();
    }
  }, [businessProfile]);

  async function fetchInventory() {
    try {
      const { data, error } = await supabase
        .from('inventory_items')
        .select(`
          *,
          category:category_id (
            id,
            name
          )
        `)
        .eq('business_id', businessProfile?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setItems(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

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
    }
  }

  const handleSubmit = async (data: Partial<InventoryItem>) => {
    try {
      if (editingItem) {
        const { error } = await supabase
          .from('inventory_items')
          .update(data)
          .eq('id', editingItem.id);

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('inventory_items')
          .insert([{ ...data, business_id: businessProfile?.id }]);

        if (error) throw error;
      }

      await fetchInventory();
      setShowForm(false);
      setEditingItem(null);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this item?')) return;

    try {
      const { error } = await supabase
        .from('inventory_items')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await fetchInventory();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleEdit = (item: InventoryItem) => {
    setEditingItem(item);
    setShowForm(true);
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-gray-900">Inventory</h1>
          <p className="mt-1 text-sm text-gray-500">Manage your equipment inventory</p>
        </div>
        {!showForm && !location.search && (
          <button
            onClick={() => {
              setEditingItem(null);
              setShowForm(true);
              navigate('?action=new');
            }}
            className="hidden lg:inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <Plus className="h-5 w-5 mr-2" />
            Add Item
          </button>
        )}
      </div>

      {error && (
        <div className="bg-red-50 p-4 rounded-md">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      {showForm ? (
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-medium text-gray-900 mb-6">
            {editingItem ? 'Edit Item' : 'Add New Item'}
          </h2>
          <InventoryForm
            item={editingItem || undefined}
            categories={categories}
            onSubmit={handleSubmit}
            onCancel={() => {
              setShowForm(false);
              setEditingItem(null);
            }}
          />
        </div>
      ) : (
        <div className="bg-white shadow rounded-lg">
          <InventoryTable
            items={items}
            loading={loading}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        </div>
      )}
    </div>
  );
}