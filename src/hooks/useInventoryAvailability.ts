import { useState } from 'react';
import { supabase } from '../lib/supabase';
import type { ReservationItem } from '../types/reservation';

interface AvailabilityCheck {
  inventoryItemId: string;
  quantity: number;
  startDate: string;
  endDate: string;
}

export function useInventoryAvailability() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const checkAvailability = async ({ 
    inventoryItemId,
    quantity,
    startDate,
    endDate 
  }: AvailabilityCheck) => {
    setLoading(true);
    setError(null);

    try {
      // Get total inventory quantity
      const { data: inventoryItem, error: inventoryError } = await supabase
        .from('inventory_items')
        .select('quantity')
        .eq('id', inventoryItemId)
        .single();

      if (inventoryError) throw inventoryError;
      if (!inventoryItem) throw new Error('Item not found');

      // Get overlapping reservations using a simpler query
      const { data: reservations, error: reservationsError } = await supabase
        .from('reservations')
        .select(`
          id,
          start_date,
          end_date,
          reservation_items!inner(
            quantity,
            inventory_item_id
          )
        `)
        .eq('status', 'reserved')
        .eq('reservation_items.inventory_item_id', inventoryItemId)
        .gte('end_date', startDate)
        .lte('start_date', endDate);

      if (reservationsError) throw reservationsError;

      // Calculate total reserved quantity for overlapping reservations
      const reservedQuantity = reservations?.reduce((sum, reservation) => {
        const item = reservation.reservation_items[0];
        return sum + (item?.quantity || 0);
      }, 0) || 0;

      const availableQuantity = inventoryItem.quantity - reservedQuantity;

      return {
        available: availableQuantity >= quantity,
        availableQuantity,
        totalQuantity: inventoryItem.quantity,
        reservedQuantity
      };
    } catch (err: any) {
      setError(err.message);
      return {
        available: false,
        availableQuantity: 0,
        totalQuantity: 0,
        reservedQuantity: 0,
        error: err.message
      };
    } finally {
      setLoading(false);
    }
  };

  return { checkAvailability, loading, error };
}