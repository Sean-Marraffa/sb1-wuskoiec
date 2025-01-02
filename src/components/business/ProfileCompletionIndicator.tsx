import React from 'react';
import { CheckCircle, XCircle } from 'lucide-react';
import { useProfileCompletion } from '../../hooks/useProfileCompletion';

interface ProfileCompletionIndicatorProps {
  businessId: string;
  percentage: number;
}

const FIELD_LABELS: Record<string, string> = {
  name: 'Business Name',
  type: 'Business Type',
  contact_email: 'Contact Email',
  street_address_1: 'Street Address',
  city: 'City',
  state_province: 'State/Province',
  postal_code: 'Postal Code',
  country: 'Country'
};

export function ProfileCompletionIndicator({ businessId, percentage }: ProfileCompletionIndicatorProps) {
  const { fields, loading } = useProfileCompletion(businessId);

  if (loading) {
    return <div className="animate-pulse h-2 bg-gray-200 rounded"></div>;
  }

  return (
    <div className="space-y-2">
      <div className="relative pt-1">
        <div className="flex mb-2 items-center justify-between">
          <div>
            <span className="text-xs font-semibold inline-block text-indigo-600">
              Profile Completion
            </span>
          </div>
          <div className="text-right">
            <span className="text-xs font-semibold inline-block text-indigo-600">
              {percentage}%
            </span>
          </div>
        </div>
        <div className="overflow-hidden h-2 text-xs flex rounded bg-indigo-100">
          <div
            style={{ width: `${percentage}%` }}
            className="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-indigo-500 transition-all duration-500"
          ></div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow p-4 mt-4">
        <h4 className="text-sm font-medium text-gray-900 mb-3">Required Fields</h4>
        <div className="space-y-2">
          {fields.map((field) => (
            <div key={field.field_name} className="flex items-center justify-between text-sm">
              <span className="text-gray-600">{FIELD_LABELS[field.field_name]}</span>
              {field.is_complete ? (
                <CheckCircle className="h-4 w-4 text-green-500" />
              ) : (
                <XCircle className="h-4 w-4 text-red-500" />
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}