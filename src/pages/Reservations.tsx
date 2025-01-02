import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import { useLocation, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { ReservationForm } from '../components/reservations/ReservationForm';
import { ReservationTable } from '../components/reservations/ReservationTable';
import type { Reservation } from '../types/reservation';

export function Reservations() {
  const [reservations, setReservations] = useState<Reservation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const location = useLocation();
  const [showForm, setShowForm] = useState(location.search === '?action=new');
  const navigate = useNavigate();
  const [editingReservation, setEditingReservation] = useState<Reservation | null>(null);
  const [selectedItems, setSelectedItems] = useState<any[]>([]);
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    if (businessProfile) {
      fetchReservations();
    }
  }, [businessProfile]);

  async function fetchReservations() {
    try {
      const { data, error } = await supabase
        .from('reservations').select(`
          *,
          reservation_items(
            id,
            inventory_item_id,
            quantity,
            rate_type,
            rate_amount,
            subtotal,
            inventory_item:inventory_items(
              id,
              name,
              hourly_rate,
              daily_rate,
              weekly_rate,
              monthly_rate
            )
          )
        `)
        .eq('business_id', businessProfile?.id)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setReservations(data);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  const handleEdit = (reservation: Reservation) => {
    setEditingReservation(reservation);
    setShowForm(true);
    navigate('?action=edit');
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this reservation?')) return;

    try {
      const { error } = await supabase
        .from('reservations')
        .delete()
        .eq('id', id);

      if (error) throw error;
      await fetchReservations();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleSubmit = async (data: any) => {
    try {
      if (editingReservation) {
        // Prepare the update data
        const updateData = {
          customer_name: data.customer_name,
          customer_id: data.customer_id,
          customer_email: data.customer_email,
          customer_phone: data.customer_phone,
          start_date: data.start_date,
          end_date: data.end_date,
          total_price: data.total_price,
          discount_amount: data.discount_amount,
          discount_type: data.discount_type,
          status: data.status || editingReservation.status || 'draft'
        };

        // Update reservation details
        const { data: updatedReservation, error } = await supabase
          .from('reservations')
          .update(updateData)
          .eq('id', editingReservation.id) 
          .select(`
            *,
            reservation_items (
              id,
              inventory_item_id,
              quantity,
              rate_type,
              rate_amount,
              subtotal,
              inventory_item:inventory_items (
                id,
                name,
                hourly_rate,
                daily_rate,
                weekly_rate,
                monthly_rate
              )
            )
          `)
          .single();

        if (error) throw error;

        // Delete existing reservation items
        const { error: deleteError } = await supabase
          .from('reservation_items')
          .delete()
          .eq('reservation_id', editingReservation.id);

        if (deleteError) throw deleteError;

        // Insert updated items
        const { error: itemsError } = await supabase
          .from('reservation_items')
          .insert(
            data.items.map((item: any) => ({
              reservation_id: editingReservation.id,
              inventory_item_id: item.inventory_item_id,
              quantity: item.quantity,
              rate_type: item.rate_type,
              rate_amount: item.rate_amount,
              subtotal: item.subtotal
            }))
          );

        if (itemsError) throw itemsError;
        
        // Fetch all reservations to ensure data is fresh
        await fetchReservations();
      } else {
        // Create new reservation
        const { data: reservation, error: reservationError } = await supabase
          .from('reservations')
          .insert([{
            business_id: businessProfile?.id,
            customer_id: data.customer_id,
            customer_name: data.customer_name,
            customer_email: data.customer_email,
            customer_phone: data.customer_phone,
            start_date: data.start_date,
            end_date: data.end_date,
            total_price: data.total_price,
            discount_amount: data.discount_amount,
            discount_type: data.discount_type,
            status: data.status || 'draft'
          }])
          .select()
          .single();

        if (reservationError) throw reservationError;

        // Insert reservation items
        const { error: itemsError } = await supabase
          .from('reservation_items')
          .insert(
            data.items.map((item: any) => ({
              reservation_id: reservation.id,
              inventory_item_id: item.inventory_item_id,
              quantity: item.quantity,
              rate_type: item.rate_type,
              rate_amount: item.rate_amount,
              subtotal: item.subtotal
            }))
          );

        if (itemsError) throw itemsError;
        
        // Fetch all reservations to ensure data is fresh
        await fetchReservations();
      }

      setShowForm(false);
      setEditingReservation(null);
      navigate('/reservations');
    } catch (err: any) {
      setError(err.message);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-gray-900">Reservations</h1>
          <p className="mt-1 text-sm text-gray-500">Manage your equipment reservations</p>
        </div>
        {!showForm && !location.search && (
          <button
            onClick={() => {
              setShowForm(true);
              navigate('?action=new');
            }}
            className="hidden lg:inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <Plus className="h-5 w-5 mr-2" />
            Add Reservation
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
            {editingReservation ? 'Edit Reservation' : 'New Reservation'}
          </h2>
          <ReservationForm
            reservation={editingReservation || undefined}
            businessId={businessProfile?.id || ''}
            onSubmit={handleSubmit}
            onCancel={() => {
              setShowForm(false);
              setEditingReservation(null);
              navigate('/reservations');
            }}
          />
        </div>
      ) : (
        <div className="bg-white shadow rounded-lg">
          <ReservationTable
            reservations={reservations}
            loading={loading}
            businessId={businessProfile?.id || ''}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        </div>
      )}
    </div>
  );
}