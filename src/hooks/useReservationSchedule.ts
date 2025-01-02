import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useBusinessProfile } from './useBusinessProfile';
import { DateRange } from '../components/reservations/DateRangeSelector';

function getDateRangeFilter(range: DateRange): { start: Date; end: Date } {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  today.setMinutes(0, 0, 0);

  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const nextWeek = new Date(today);
  nextWeek.setDate(nextWeek.getDate() + 7);

  const nextMonth = new Date(today);
  nextMonth.setMonth(nextMonth.getMonth() + 1);

  switch (range) {
    case 'today':
      return { start: today, end: tomorrow };
    case 'tomorrow':
      return { start: tomorrow, end: new Date(tomorrow.getTime() + 86400000) };
    case 'next7days':
      return { start: today, end: nextWeek };
    case 'nextWeek':
      return { start: nextWeek, end: new Date(nextWeek.getTime() + 7 * 86400000) };
    case 'nextMonth':
      return { start: today, end: nextMonth };
    default:
      return { start: today, end: tomorrow };
  }
}

export function useReservationSchedule() {
  const [returningToday, setReturningToday] = useState([]);
  const [departingToday, setDepartingToday] = useState([]);
  const [loading, setLoading] = useState(true);
  const { businessProfile } = useBusinessProfile();
  const [checkInRange, setCheckInRange] = useState<DateRange>('today');
  const [checkOutRange, setCheckOutRange] = useState<DateRange>('today');

  useEffect(() => {
    if (businessProfile?.id) {
      fetchSchedule();
      setLoading(true);
    }
  }, [businessProfile?.id, checkInRange, checkOutRange]);

  async function fetchSchedule() {
    if (!businessProfile?.id) return;

    try {
      const checkInDates = getDateRangeFilter(checkInRange);
      const checkOutDates = getDateRangeFilter(checkOutRange);

      // Helper to format date with timezone offset
      const formatDateWithOffset = (date: Date) => {
        const offset = date.getTimezoneOffset() * 60000;
        return new Date(date.getTime() - offset).toISOString().split('T')[0];
      };

      // Fetch reservations returning today
      const { data: returning } = await supabase
        .from('reservations')
        .select('*')
        .eq('business_id', businessProfile?.id)
        .gte('end_date', formatDateWithOffset(checkInDates.start))
        .lt('end_date', formatDateWithOffset(checkInDates.end))
        .eq('status', 'in_use')
        .order('end_date');

      // Fetch reservations departing today
      const { data: departing } = await supabase
        .from('reservations')
        .select('*')
        .eq('business_id', businessProfile?.id)
        .gte('start_date', formatDateWithOffset(checkOutDates.start))
        .lt('start_date', formatDateWithOffset(checkOutDates.end))
        .eq('status', 'reserved')
        .order('start_date');

      setReturningToday(returning || []);
      setDepartingToday(departing || []);
    } catch (err) {
      console.error('Error fetching reservation schedule:', err);
    } finally {
      setLoading(false);
    }
  }

  return { 
    returningToday, 
    departingToday, 
    loading,
    checkInRange,
    checkOutRange,
    setCheckInRange,
    setCheckOutRange
  };
}