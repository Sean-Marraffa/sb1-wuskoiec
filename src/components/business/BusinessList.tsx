import React, { useState } from 'react';
import { BusinessTable } from './BusinessTable';
import { useBusinesses } from '../../hooks/useBusinesses';
import { ConfirmationModal } from '../ConfirmationModal';
import type { Business } from '../../types/business';

export function BusinessList({ onDelete }: BusinessListProps) {
  const { businesses, loading, error, deleteLoading, deleteBusiness } = useBusinesses();
  const [deleteModal, setDeleteModal] = useState<{
    isOpen: boolean;
    business: Business | null;
  }>({
    isOpen: false,
    business: null
  });

  const handleDeleteClick = (business: Business) => {
    setDeleteModal({
      isOpen: true,
      business
    });
  };

  const handleConfirmDelete = async () => {
    if (!deleteModal.business) return;

    const { error: deleteError } = await deleteBusiness(deleteModal.business.id); 

    if (deleteError) {
      // Handle error (you could add a toast notification here)
      console.error('Failed to delete business:', deleteError);
      return;
    }
    
    setDeleteModal({ isOpen: false, business: null });
    if (onDelete) {
      await onDelete();
    }
  };

  if (error) {
    return (
      <div className="bg-red-50 p-4 rounded-md">
        <p className="text-sm text-red-600">{error}</p>
      </div>
    );
  }

  return (
    <>
      <div className="bg-white shadow rounded-lg">
        <BusinessTable 
          businesses={businesses} 
          loading={loading} 
          onDelete={handleDeleteClick}
        />
      </div>

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, business: null })}
        onConfirm={handleConfirmDelete}
        title="Delete Business"
        message={`Are you sure you want to delete ${deleteModal.business?.name}? This action cannot be undone.`}
        confirmText={deleteLoading ? 'Deleting...' : 'Delete'}
        isLoading={deleteLoading}
      />
    </>
  );
}