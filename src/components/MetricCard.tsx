import React from 'react';
import { LucideIcon } from 'lucide-react';

interface MetricCardProps {
  title: string;
  value: number | null;
  loading: boolean;
  icon: LucideIcon;
  isActive: boolean;
  activeColor: 'indigo' | 'purple';
  onClick: () => void;
}

export function MetricCard({
  title,
  value,
  loading,
  icon: Icon,
  isActive,
  activeColor,
  onClick
}: MetricCardProps) {
  const colors = {
    indigo: {
      active: 'bg-indigo-600',
      inactive: 'bg-indigo-500',
      ring: 'ring-indigo-500',
      text: {
        active: 'text-indigo-600',
        title: 'text-gray-500',
        value: 'text-gray-900'
      }
    },
    purple: {
      active: 'bg-purple-600',
      inactive: 'bg-purple-500',
      ring: 'ring-purple-500',
      text: {
        active: 'text-purple-600',
        title: 'text-gray-500',
        value: 'text-gray-900'
      }
    }
  };

  const colorSet = colors[activeColor];
  
  return (
    <button
      onClick={onClick}
      className={`bg-white overflow-hidden shadow rounded-lg transition-all w-full sm:h-auto ${
        isActive ? `ring-2 ${colorSet.ring}` : ''
      }`}
    >
      <div className="p-3 sm:p-5 flex sm:flex-col items-center">
        <div className={`rounded-lg p-2 sm:p-3 ${isActive ? colorSet.active : colorSet.inactive}`}>
          <Icon className="h-6 w-6 text-white" aria-hidden="true" />
        </div>
        <div className="text-left sm:text-center ml-3 sm:ml-0 sm:mt-3">
          <h3 className={`text-sm font-medium mb-2 ${
            isActive ? colorSet.text.active : colorSet.text.title
          }`}>
            {title}
          </h3>
          <div className={`text-xl sm:text-3xl font-semibold ${colorSet.text.value}`}>
            {loading ? (
              <div className="h-6 sm:h-9 w-12 sm:w-16 bg-gray-200 rounded animate-pulse sm:mx-auto" />
            ) : (
              value ?? 0
            )}
          </div>
        </div>
      </div>
    </button>
  );
}