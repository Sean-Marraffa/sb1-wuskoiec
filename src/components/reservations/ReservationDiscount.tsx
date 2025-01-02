import React from 'react';
import { useFormContext } from 'react-hook-form';

export function ReservationDiscount() {
  const { register, watch, formState: { errors } } = useFormContext();
  const discountType = watch('discount_type');

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Discount</h3>
      
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label htmlFor="discount_type" className="block text-sm font-medium text-gray-700">
            Discount Type
          </label>
          <select
            id="discount_type"
            {...register('discount_type')}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          >
            <option value="fixed">Fixed Amount</option>
            <option value="percentage">Percentage</option>
          </select>
        </div>

        <div>
          <label htmlFor="discount_amount" className="block text-sm font-medium text-gray-700">
            {discountType === 'percentage' ? 'Discount Percentage' : 'Discount Amount'}
          </label>
          <div className="mt-1 relative rounded-md shadow-sm">
            <input
              type="number"
              id="discount_amount"
              min="0"
              step={discountType === 'percentage' ? '1' : '0.01'}
              max={discountType === 'percentage' ? '100' : undefined}
              {...register('discount_amount', {
                min: { value: 0, message: 'Discount must be positive' },
                max: discountType === 'percentage' 
                  ? { value: 100, message: 'Percentage cannot exceed 100%' }
                  : undefined
              })}
              className="block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
            {discountType === 'percentage' && (
              <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                <span className="text-gray-500 sm:text-sm">%</span>
              </div>
            )}
          </div>
          {errors.discount_amount && (
            <p className="mt-1 text-sm text-red-600">{errors.discount_amount.message}</p>
          )}
        </div>
      </div>
    </div>
  );
}