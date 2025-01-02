import React, { useState, useEffect } from 'react';
import { FileText, Calendar, CheckCircle, Package, Plus } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { MetricCard } from '../components/MetricCard';
import { useReservationMetrics } from '../hooks/useReservationMetrics';
import { ReservationSchedule } from '../components/reservations/ReservationSchedule';
import { ReservationTable } from '../components/reservations/ReservationTable';
import { useBusinessProfile } from '../hooks/useBusinessProfile';
import { useReservationStatusSettings } from '../hooks/useReservationStatusSettings';
import { useReservations } from '../hooks/useReservations';

export function Dashboard() {
  const { counts, loading } = useReservationMetrics();
  const [selectedStatus, setSelectedStatus] = useState<string>('reserved');
  const navigate = useNavigate();
  const { businessProfile } = useBusinessProfile();
  const { reservations, loading: reservationsLoading } = useReservations(selectedStatus);
  const { statusSettings, loading: settingsLoading } = useReservationStatusSettings();

  const getStatusLabel = (status: string) => {
    return statusSettings.find(s => s.status_key === status)?.label || status;
  };

  const metrics = [
    {
      title: getStatusLabel('draft'),
      value: counts.draft,
      icon: FileText,
      color: 'indigo',
      status: 'draft'
    },
    {
      title: getStatusLabel('reserved'),
      value: counts.reserved,
      icon: Calendar,
      color: 'purple',
      status: 'reserved'
    },
    {
      title: getStatusLabel('in_use'),
      value: counts.in_use,
      icon: Package,
      color: 'indigo',
      status: 'in_use'
    },
    {
      title: getStatusLabel('closed'),
      value: counts.closed,
      icon: CheckCircle,
      color: 'purple',
      status: 'closed'
    }
  ];

  const handleEdit = (reservation: any) => {
    navigate(`/reservations?action=edit&id=${reservation.id}`);
  };

  const handleDelete = async (id: string) => {
    // Handle delete
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div className="flex-1">
          <h1 className="text-2xl font-semibold text-gray-900">Dashboard</h1>
          <p className="mt-1 text-sm text-gray-500">
            Overview of your rental business
          </p>
        </div>
        <div className="hidden lg:block">
          <button
            onClick={() => navigate('/reservations?action=new')}
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <Plus className="h-5 w-5 mr-2" />
            New Reservation
          </button>
        </div>
      </div>

      {/* Schedule Cards */}
      <ReservationSchedule />

      <div className="space-y-6">
        <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-2 sm:gap-4">
          {metrics.map((metric) => (
            <MetricCard
              key={metric.title}
              title={metric.title}
              value={metric.value}
              loading={loading}
              icon={metric.icon}
              isActive={selectedStatus === metric.status}
              activeColor={metric.color}
              onClick={() => setSelectedStatus(metric.status)}
            />
          ))}
        </div>

        {/* Filtered Reservations */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">
              {getStatusLabel(selectedStatus)}
            </h3>
          </div>
          <ReservationTable
            reservations={reservations}
            loading={reservationsLoading}
            businessId={businessProfile?.id || ''}
            onEdit={handleEdit}
            onDelete={handleDelete}
          />
        </div>
      </div>
    </div>
  );
}