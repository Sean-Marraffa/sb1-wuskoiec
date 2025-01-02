import React, { useState, useEffect } from 'react';
import { Edit, Trash2 } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { Reservation } from '../../types/reservation';
import { formatDate } from '../../utils/dates';

interface ReservationTableProps {
  reservations: Reservation[];
  loading: boolean;
  businessId: string;
  onEdit: (reservation: Reservation) => void;
  onDelete: (id: string) => void;
}

interface StatusSetting {
  status_key: string;
  label: string;
}

export function ReservationTable({ 
  reservations, 
  loading, 
  businessId,
  onEdit, 
  onDelete 
}: ReservationTableProps) {
  const [statusSettings, setStatusSettings] = useState<StatusSetting[]>([]);

  const defaultSettings = [
    { status_key: 'draft', label: 'Draft' },
    { status_key: 'reserved', label: 'Reserved' },
    { status_key: 'in_use', label: 'In Use' },
    { status_key: 'closed', label: 'Closed' }
  ];

  useEffect(() => {
    if (businessId) {
      fetchStatusSettings();
    } else {
      setStatusSettings(defaultSettings);
    }
  }, [businessId]);

  async function fetchStatusSettings() {
    try {
      const { data, error } = await supabase
        .from('reservation_status_settings')
        .select('status_key, label')
        .eq('business_id', businessId);

      if (error) throw error;

      if (!data || data.length === 0) {
        setStatusSettings(defaultSettings);
      } else {
        setStatusSettings(data);
      }
    } catch (err) {
      console.error('Error fetching status settings:', err);
      setStatusSettings(defaultSettings);
    }
  }

  const getStatusLabel = (status: string) => {
    const setting = statusSettings.find(s => s.status_key === status);
    return setting?.label || status;
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      case 'reserved':
        return 'bg-yellow-100 text-yellow-800';
      case 'in_use':
        return 'bg-green-100 text-green-800';
      case 'closed':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-10 bg-gray-200 rounded w-full" />
        <div className="h-10 bg-gray-200 rounded w-full" />
        <div className="h-10 bg-gray-200 rounded w-full" />
      </div>
    );
  }

  if (reservations.length === 0) {
    return (
      <div className="text-center py-6 text-gray-500">
        No reservations found
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full divide-y divide-gray-200">
        <thead className="bg-gray-50">
          <tr>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Reservation ID
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Customer Name
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Start Date
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              End Date
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Price
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {reservations.map((reservation) => (
            <tr key={reservation.id}>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {reservation.id.slice(0, 8)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                {reservation.customer_name}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {formatDate(reservation.start_date)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                {formatDate(reservation.end_date)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                ${reservation.total_price.toFixed(2)}
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full
                  ${getStatusColor(reservation.status)}`}>
                  {getStatusLabel(reservation.status)}
                </span>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                <div className="flex space-x-2">
                  <button
                    onClick={() => onEdit(reservation)}
                    className="text-indigo-600 hover:text-indigo-900"
                  >
                    <Edit className="h-5 w-5" />
                  </button>
                  <button
                    onClick={() => onDelete(reservation.id)}
                    className="text-red-600 hover:text-red-900"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}