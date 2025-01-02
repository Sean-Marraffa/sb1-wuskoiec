import React from 'react';
import { HelpCircle } from 'lucide-react';
import type { BusinessStatus } from '../../types/business';

const STATUS_INFO = {
  pending_setup: {
    label: 'Pending Setup',
    description: 'Owner has signed up but hasn\'t created a business profile',
    color: 'bg-yellow-100 text-yellow-800'
  },
  profile_created: {
    label: 'Profile Created',
    description: 'Business profile created but not fully onboarded',
    color: 'bg-blue-100 text-blue-800'
  },
  active: {
    label: 'Active',
    description: 'Fully onboarded and operating business',
    color: 'bg-green-100 text-green-800'
  },
  churned: {
    label: 'Churned',
    description: 'Business canceled after being active',
    color: 'bg-red-100 text-red-800'
  },
  withdrawn: {
    label: 'Withdrawn',
    description: 'Business canceled during onboarding',
    color: 'bg-gray-100 text-gray-800'
  }
} as const;

interface BusinessStatusBadgeProps {
  status: BusinessStatus;
  showTooltip?: boolean;
}

export function BusinessStatusBadge({ status, showTooltip = true }: BusinessStatusBadgeProps) {
  const info = STATUS_INFO[status];
  
  return (
    <div className="relative group">
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${info.color}`}>
        {info.label}
        {showTooltip && (
          <HelpCircle className="ml-1 h-3 w-3 opacity-50" />
        )}
      </span>
      
      {showTooltip && (
        <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 hidden group-hover:block z-10">
          <div className="bg-gray-900 text-white text-sm rounded py-1 px-2 whitespace-nowrap">
            {info.description}
          </div>
        </div>
      )}
    </div>
  );
}