import React, { useState } from 'react';
import { useReservationSchedule } from '../../hooks/useReservationSchedule';
import { DateRangeSelector, type DateRange } from './DateRangeSelector';
import { formatDate } from '../../utils/dates';

export function ReservationSchedule() {
  const [showInRangeSelector, setShowInRangeSelector] = useState(false);
  const [showOutRangeSelector, setShowOutRangeSelector] = useState(false);
  const { 
    returningToday: checkingIn, 
    departingToday: checkingOut, 
    loading,
    checkInRange,
    checkOutRange,
    setCheckInRange,
    setCheckOutRange
  } = useReservationSchedule();

  const ScheduleSection = ({ 
    title, 
    reservations, 
    range, 
    onRangeChange,
    showRangeSelector,
    onToggleSelector
  }: { 
    title: string;
    reservations: any[];
    range: DateRange;
    onRangeChange: (range: DateRange) => void;
    showRangeSelector: boolean;
    onToggleSelector: () => void;
  }) => (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-lg font-medium text-gray-900">{title}</h3>
        <DateRangeSelector
          currentRange={range}
          onChange={onRangeChange}
          show={showRangeSelector}
          onToggle={onToggleSelector}
        />
      </div>
      {loading ? (
        <div className="space-y-3">
          <div className="h-16 bg-gray-100 rounded animate-pulse" />
          <div className="h-16 bg-gray-100 rounded animate-pulse" />
        </div>
      ) : reservations.length === 0 ? (
        <p className="text-gray-500">No reservations scheduled</p>
      ) : (
        <div className="space-y-3">
          {reservations.map((reservation) => (
            <div
              key={reservation.id}
              className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50"
            >
              <div className="flex justify-between items-start">
                <div>
                  <h4 className="font-medium text-gray-900">{reservation.customer_name}</h4>
                  <p className="text-sm text-gray-500">
                    {formatDate(reservation.start_date)} - {formatDate(reservation.end_date)}
                  </p>
                </div>
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                  ${reservation.total_price.toFixed(2)}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      <ScheduleSection
        title="Checking Out"
        reservations={checkingOut}
        range={checkOutRange}
        onRangeChange={setCheckOutRange}
        showRangeSelector={showOutRangeSelector}
        onToggleSelector={() => setShowOutRangeSelector(!showOutRangeSelector)}
      />
      <ScheduleSection
        title="Checking In"
        reservations={checkingIn}
        range={checkInRange}
        onRangeChange={setCheckInRange}
        showRangeSelector={showInRangeSelector}
        onToggleSelector={() => setShowInRangeSelector(!showInRangeSelector)}
      />
    </div>
  );
}