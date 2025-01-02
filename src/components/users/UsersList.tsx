import React, { useState } from 'react';
import { UsersTable } from './UsersTable';
import { useUsers } from '../../hooks/useUsers';
import { ConfirmationModal } from '../ConfirmationModal';
import type { User } from '../../types/user';

export function UsersList({ onDelete }: UsersListProps) {
  const { users, loading, error, deleteLoading, deleteUser } = useUsers();
  const [deleteModal, setDeleteModal] = useState<{
    isOpen: boolean;
    user: User | null;
  }>({
    isOpen: false,
    user: null
  });

  const handleDeleteClick = (user: User) => {
    setDeleteModal({
      isOpen: true,
      user
    });
  };

  const handleConfirmDelete = async () => {
    if (!deleteModal.user) return;

    const { error: deleteError } = await deleteUser(deleteModal.user.id); 

    if (deleteError) {
      console.error('Failed to delete user:', deleteError);
      return;
    }
    
    setDeleteModal({ isOpen: false, user: null });
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
        <UsersTable 
          users={users} 
          loading={loading} 
          onDelete={handleDeleteClick}
        />
      </div>

      <ConfirmationModal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, user: null })}
        onConfirm={handleConfirmDelete}
        title="Delete User"
        message={`Are you sure you want to delete ${deleteModal.user?.email}? This action cannot be undone.`}
        confirmText={deleteLoading ? 'Deleting...' : 'Delete'}
        isLoading={deleteLoading}
      />
    </>
  );
}