import React from 'react';
import { useFormContext } from 'react-hook-form';
import type { Category } from '../../types/inventory';

interface CategorySelectProps {
  categories: Category[];
}

export function CategorySelect({ categories }: CategorySelectProps) {
  const { register, formState: { errors } } = useFormContext();

  return (
    <div>
      <label htmlFor="category_id" className="block text-sm font-medium text-gray-700">
        Category (Optional)
      </label>
      <select
        id="category_id"
        {...register('category_id')}
        className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
      >
        <option value="">Select a category (optional)</option>
        {categories.map((category) => (
          <option key={category.id} value={category.id}>
            {category.name}
          </option>
        ))}
      </select>
      {errors.category_id && (
        <p className="mt-1 text-sm text-red-600">{errors.category_id.message}</p>
      )}
    </div>
  );
}