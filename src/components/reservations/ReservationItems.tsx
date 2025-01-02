import React, { useEffect, useState } from 'react';
import { Plus, Trash2 } from 'lucide-react';
import { useFormContext } from 'react-hook-form';
import { useInventoryAvailability } from '../../hooks/useInventoryAvailability';
import { useInventory } from '../../hooks/useInventory';
import { useBusinessProfile } from '../../hooks/useBusinessProfile';
import type { InventoryItem } from '../../types/inventory';
import type { ReservationItem, RateType } from '../../types/reservation';

interface ReservationItemsProps {
  selectedItems: ReservationItem[];
  onItemsChange: (items: ReservationItem[]) => void;
}

function calculateItemTotal(
  quantity: number,
  rateAmount: number,
  rateType: RateType,
  startDate: string,
  endDate: string
): number {
  const duration = startDate && endDate ? calculateDuration(startDate, endDate, rateType) : 0;
  const subtotal = quantity * rateAmount;
  return duration > 0 ? subtotal * duration : 0;
}

function calculateDuration(startDate: string, endDate: string, rateType: RateType): number {
  if (!startDate || !endDate) return 0;
  
  const start = new Date(startDate);
  const end = new Date(endDate);
  const diffTime = Math.abs(end.getTime() - start.getTime());
  
  switch (rateType) {
    case 'hourly':
      return Math.ceil(diffTime / (1000 * 60 * 60));
    case 'daily':
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    case 'weekly':
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 7));
    case 'monthly':
      return Math.ceil(diffTime / (1000 * 60 * 60 * 24 * 30));
    default:
      return 0;
  }
}

export function ReservationItems({
  selectedItems,
  onItemsChange
}: ReservationItemsProps) {
  const { watch } = useFormContext();
  const { checkAvailability } = useInventoryAvailability();
  const { items, loading: itemsLoading } = useInventory();
  const startDate = watch('start_date');
  const endDate = watch('end_date');
  const [availabilityErrors, setAvailabilityErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    if (startDate && endDate) {
      const updatedItems = selectedItems.map(item => {
        if (!item.rate_type || !item.rate_amount) return item;
        
        const total = calculateItemTotal(
          item.quantity,
          item.rate_amount,
          item.rate_type,
          startDate,
          endDate
        );
        
        return {
          ...item,
          subtotal: total
        };
      });
      onItemsChange(updatedItems);
    }
  }, [startDate, endDate]);

  const addItem = () => {
    onItemsChange([
      ...selectedItems,
      {
        id: crypto.randomUUID(),
        reservation_id: '',
        inventory_item_id: '',
        quantity: 1,
        rate_type: '',
        rate_amount: 0,
        subtotal: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }
    ]);
  };

  const removeItem = (index: number) => {
    onItemsChange(selectedItems.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, updates: Partial<ReservationItem>) => {
    const newItems = [...selectedItems];
    newItems[index] = { ...newItems[index], ...updates };
    
    // Recalculate total if we have all necessary values
    const item = newItems[index];
    if (item.rate_type && item.rate_amount) {
      const total = calculateItemTotal(
        item.quantity,
        item.rate_amount,
        item.rate_type,
        startDate,
        endDate
      );
      newItems[index].subtotal = total;
    }
    
    onItemsChange(newItems);
  };

  const handleItemChange = async (index: number, itemId: string) => {
    const item = items.find(i => i.id === itemId);
    if (!item) return;

    // Clear any previous errors
    setAvailabilityErrors(prev => ({
      ...prev,
      [index]: ''
    }));

    // Find the first available rate type
    let defaultRateType: RateType | undefined;
    if (item.daily_rate) defaultRateType = 'daily';
    else if (item.hourly_rate) defaultRateType = 'hourly';
    else if (item.weekly_rate) defaultRateType = 'weekly';
    else if (item.monthly_rate) defaultRateType = 'monthly';
    
    const updates = {
      inventory_item_id: itemId,
      inventory_item: item
    };

    updateItem(index, updates);
    
    // If we found a default rate type, set it after updating the item
    if (defaultRateType) {
      handleRateTypeChange(index, defaultRateType);
    }
  };

  const handleQuantityChange = async (index: number, quantity: number) => {
    const item = selectedItems[index];
    if (!item.inventory_item_id || !startDate || !endDate) return;

    // Check availability
    const availability = await checkAvailability({
      inventoryItemId: item.inventory_item_id,
      quantity,
      startDate,
      endDate
    });

    if (!availability.available) {
      setAvailabilityErrors(prev => ({
        ...prev,
        [index]: `Only ${availability.availableQuantity} available for this period`
      }));
    } else {
      setAvailabilityErrors(prev => ({
        ...prev,
        [index]: ''
      }));
    }

    updateItem(index, {
      quantity,
      subtotal: calculateItemTotal(
        quantity,
        item.rate_amount || 0,
        item.rate_type as RateType,
        startDate,
        endDate
      )
    });
  };

  const handleRateTypeChange = (index: number, rateType: RateType) => {
    const item = selectedItems[index];
    if (!item.inventory_item) return;
    
    // Get the rate safely
    const rateKey = `${rateType}_rate` as keyof InventoryItem;
    const rate = item.inventory_item[rateKey];
    if (rate === null || rate === undefined) return;
    
    const quantity = item.quantity || 1;
    const total = calculateItemTotal(quantity, rate, rateType, startDate, endDate);

    updateItem(index, {
      rate_type: rateType,
      rate_amount: rate,
      quantity: quantity,
      subtotal: total
    });
  };

  return (
    <div className="space-y-4">
      <div className="flex justify-between items-center">
        <h3 className="text-lg font-medium text-gray-900">Items</h3>
        <button
          type="button"
          onClick={addItem}
          className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-indigo-600 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
        >
          <Plus className="h-4 w-4 mr-1" />
          Add Item
        </button>
      </div>

      {selectedItems.length === 0 ? (
        <p className="text-sm text-gray-500">No items added yet</p>
      ) : (
        <div className="space-y-4">
          {selectedItems.map((item, index) => (
            <div key={item.id} className="flex items-start space-x-4 bg-gray-50 p-4 rounded-lg">
              <div className="flex-1 grid grid-cols-1 gap-4 sm:grid-cols-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Item
                  </label>
                  <select
                    disabled={itemsLoading}
                    value={item.inventory_item_id}
                    onChange={(e) => handleItemChange(index, e.target.value)}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                  >
                    <option value="">
                      {itemsLoading ? 'Loading items...' : 'Select an item'}
                    </option>
                    {items.map((inventoryItem) => (
                      <option key={inventoryItem.id} value={inventoryItem.id}>
                        {inventoryItem.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Quantity
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={item.quantity}
                    onChange={(e) => handleQuantityChange(index, parseInt(e.target.value))}
                    className={`mt-1 block w-full rounded-md border px-3 py-2 shadow-sm focus:outline-none focus:ring-1 ${
                      availabilityErrors[index]
                        ? 'border-red-300 focus:border-red-500 focus:ring-red-500'
                        : 'border-gray-300 focus:border-indigo-500 focus:ring-indigo-500'
                    }`}
                  />
                  {availabilityErrors[index] && (
                    <p className="mt-1 text-sm text-red-600">{availabilityErrors[index]}</p>
                  )}
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Rate Type
                  </label>
                  <select
                    value={item.rate_type}
                    onChange={(e) => handleRateTypeChange(index, e.target.value as RateType)}
                    className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                    required
                  >
                    <option value="">Select rate type</option>
                    {item.inventory_item?.hourly_rate && (
                      <option value="hourly">Hourly</option>
                    )}
                    {item.inventory_item?.daily_rate && (
                      <option value="daily">Daily</option>
                    )}
                    {item.inventory_item?.weekly_rate && (
                      <option value="weekly">Weekly</option>
                    )}
                    {item.inventory_item?.monthly_rate && (
                      <option value="monthly">Monthly</option>
                    )}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Subtotal
                  </label>
                  <div className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 bg-gray-50 text-gray-700">
                    ${item.rate_amount ? ((item.quantity || 0) * item.rate_amount).toFixed(2) : '0.00'}
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Duration
                  </label>
                  <div className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 bg-gray-50 text-gray-700" title="Number of rate periods">
                    {item.rate_type ? `${calculateDuration(startDate, endDate, item.rate_type)} ${item.rate_type}` : '-'}
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Total
                  </label>
                  <div className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 bg-gray-50 text-gray-700">
                    ${(item.subtotal || 0).toFixed(2)}
                  </div>
                </div>
              </div>

              <button
                type="button"
                onClick={() => removeItem(index)}
                className="text-red-600 hover:text-red-900"
              >
                <Trash2 className="h-5 w-5" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}