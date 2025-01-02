import React, { useState } from 'react';
import { Edit, Trash2 } from 'lucide-react';
import type { InventoryItem, PricingPeriod } from '../../types/inventory';

interface InventoryTableProps {
  items: InventoryItem[];
  loading: boolean;
  onEdit: (item: InventoryItem) => void;
  onDelete: (id: string) => void;
}

function formatRate(rate: number | null, period: PricingPeriod): string | null {
  if (!rate) return null;
  return `$${rate.toFixed(2)}/${period.slice(0, 1)}`;
}

export function InventoryTable({ items, loading, onEdit, onDelete }: InventoryTableProps) {
  if (loading) {
    return (
      <div className="animate-pulse space-y-4">
        <div className="h-10 bg-gray-200 rounded w-full" />
        <div className="h-10 bg-gray-200 rounded w-full" />
        <div className="h-10 bg-gray-200 rounded w-full" />
      </div>
    );
  }

  if (items.length === 0) {
    return (
      <div className="text-center py-6 text-gray-500">
        No inventory items found
      </div>
    );
  }

  return (
    <div>
      <div className="overflow-x-auto">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Name
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Category
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Description
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Quantity
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Rates
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {items.map((item) => (
              <tr key={item.id}>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {item.name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {item.category?.name || '-'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {item.description || '-'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {item.quantity}
                </td>
                <td className="px-6 py-4 text-sm text-gray-500">
                  <div className="space-y-1">
                    {formatRate(item.hourly_rate, 'hourly') && (
                      <div>{formatRate(item.hourly_rate, 'hourly')}</div>
                    )}
                    {formatRate(item.daily_rate, 'daily') && (
                      <div>{formatRate(item.daily_rate, 'daily')}</div>
                    )}
                    {formatRate(item.weekly_rate, 'weekly') && (
                      <div>{formatRate(item.weekly_rate, 'weekly')}</div>
                    )}
                    {formatRate(item.monthly_rate, 'monthly') && (
                      <div>{formatRate(item.monthly_rate, 'monthly')}</div>
                    )}
                    {!item.hourly_rate && !item.daily_rate && !item.weekly_rate && !item.monthly_rate && (
                      <div>-</div>
                    )}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  <div className="flex space-x-2">
                    <button
                      onClick={() => onEdit(item)}
                      className="text-indigo-600 hover:text-indigo-900"
                    >
                      <Edit className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => onDelete(item.id)}
                      className="text-red-600 hover:text-red-900"
                    >
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}