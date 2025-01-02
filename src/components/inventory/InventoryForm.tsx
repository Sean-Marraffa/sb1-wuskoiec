import React from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import type { InventoryItem, Category } from '../../types/inventory';
import { PricingFields } from './PricingFields';
import { CategorySelect } from './CategorySelect';

interface InventoryFormProps {
  item?: Partial<InventoryItem>;
  categories: Category[];
  onSubmit: (data: Partial<InventoryItem>) => Promise<void>;
  onCancel: () => void;
}

export function InventoryForm({ item, categories, onSubmit, onCancel }: InventoryFormProps) {
  const methods = useForm({
    defaultValues: {
      name: item?.name || '',
      description: item?.description || '',
      quantity: item?.quantity || 0,
      category_id: item?.category_id || null,
      hourly_rate: item?.hourly_rate || '',
      daily_rate: item?.daily_rate || '',
      weekly_rate: item?.weekly_rate || '',
      monthly_rate: item?.monthly_rate || '',
    }
  });

  const { register, formState: { errors, isSubmitting } } = methods;

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(onSubmit)} className="space-y-6">
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700">
            Name
          </label>
          <input
            type="text"
            id="name"
            {...register('name', { required: 'Name is required' })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
          {errors.name && (
            <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
          )}
        </div>

        <CategorySelect categories={categories} />

        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-700">
            Description
          </label>
          <textarea
            id="description"
            rows={3}
            {...register('description')}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label htmlFor="quantity" className="block text-sm font-medium text-gray-700">
            Quantity
          </label>
          <input
            type="number"
            id="quantity"
            min="0"
            {...register('quantity', {
              required: 'Quantity is required',
              min: { value: 0, message: 'Quantity must be positive' }
            })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
          {errors.quantity && (
            <p className="mt-1 text-sm text-red-600">{errors.quantity.message}</p>
          )}
        </div>

        <PricingFields />

        <div className="flex justify-end space-x-3">
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {isSubmitting ? 'Saving...' : (item ? 'Update' : 'Create')}
          </button>
        </div>
      </form>
    </FormProvider>
  );
}