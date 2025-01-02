import React from 'react';
import { ChevronDown } from 'lucide-react';

export type DateRange = 'today' | 'tomorrow' | 'next7days' | 'nextWeek' | 'nextMonth';

export const DATE_RANGE_LABELS: Record<DateRange, string> = {
  today: 'Today',
  tomorrow: 'Tomorrow',
  next7days: 'Next 7 days',
  nextWeek: 'Next week',
  nextMonth: 'Next month'
};

interface DateRangeSelectorProps {
  currentRange: DateRange;
  onChange: (range: DateRange) => void;
  show: boolean;
  onToggle: () => void;
}

export function DateRangeSelector({ 
  currentRange, 
  onChange, 
  show, 
  onToggle 
}: DateRangeSelectorProps) {
  return (
    <div className="relative">
      <button
        onClick={onToggle}
        className="inline-flex items-center px-2.5 py-1.5 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        {DATE_RANGE_LABELS[currentRange]}
        <ChevronDown className="w-4 h-4 ml-1" />
      </button>

      {show && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={onToggle}
          />
          <div className="absolute right-0 z-20 w-48 mt-2 bg-white rounded-md shadow-lg ring-1 ring-black ring-opacity-5">
            <div className="py-1">
              {Object.entries(DATE_RANGE_LABELS).map(([range, label]) => (
                <button
                  key={range}
                  onClick={() => {
                    onChange(range as DateRange);
                    onToggle();
                  }}
                  className={`block w-full px-4 py-2 text-sm text-left ${
                    currentRange === range
                      ? 'bg-gray-100 text-gray-900'
                      : 'text-gray-700 hover:bg-gray-50'
                  }`}
                >
                  {label}
                </button>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}