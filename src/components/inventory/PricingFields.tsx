import React from 'react';
import { useFormContext } from 'react-hook-form';

export function PricingFields() {
  const { register, formState: { errors } } = useFormContext();

  const rates = [
    { id: 'hourly_rate', label: 'Hourly Rate' },
    { id: 'daily_rate', label: 'Daily Rate' },
    { id: 'weekly_rate', label: 'Weekly Rate' },
    { id: 'monthly_rate', label: 'Monthly Rate' },
  ];

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Pricing</h3>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {rates.map(({ id, label }) => (
          <div key={id}>
            <label htmlFor={id} className="block text-sm font-medium text-gray-700">
              {label} ($)
            </label>
            <input
              type="number"
              id={id}
              step="0.01"
              min="0"
              {...register(id, {
                setValueAs: (v: string) => v === '' ? null : parseFloat(v),
                min: { value: 0, message: 'Rate must be positive' }
              })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
            {errors[id] && (
              <p className="mt-1 text-sm text-red-600">{errors[id].message}</p>
            )}
          </div>
        ))}
      </div>
      <p className="text-sm text-gray-500">
        Leave rates empty if not applicable
      </p>
    </div>
  );
}