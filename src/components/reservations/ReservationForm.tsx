import React, { useState, useEffect } from 'react';
import { useForm, FormProvider } from 'react-hook-form';
import { supabase } from '../../lib/supabase';
import type { Reservation, ReservationItem } from '../../types/reservation';
import type { InventoryItem } from '../../types/inventory';
import { ReservationItems } from './ReservationItems';
import { ReservationDiscount } from './ReservationDiscount';

interface ReservationFormProps {
  reservation?: Partial<Reservation>;
  businessId: string;
  onSubmit: (data: any) => Promise<void>;
  onCancel: () => void;
}

interface ReservationFormData {
  customer_id: string;
  customer_name: string;
  customer_email: string;
  customer_phone: string;
  start_date: string;
  end_date: string;
  discount_type: string;
  discount_amount: number;
}

export function ReservationForm({
  reservation,
  businessId,
  onSubmit,
  onCancel
}: ReservationFormProps) {
  const methods = useForm<ReservationFormData>({
    defaultValues: {
      customer_id: '',
      customer_name: reservation?.customer_name || '',
      customer_email: reservation?.customer_email || '',
      customer_phone: reservation?.customer_phone || '',
      start_date: reservation?.start_date ? new Date(reservation.start_date).toISOString().split('T')[0] : '',
      end_date: reservation?.end_date ? new Date(reservation.end_date).toISOString().split('T')[0] : '',
      discount_type: reservation?.discount_type || 'fixed',
      discount_amount: reservation?.discount_amount || 0
    }
  });

  const [customers, setCustomers] = useState<Customer[]>([]);
  const [items, setItems] = useState<InventoryItem[]>([]);
  const [selectedItems, setSelectedItems] = useState<ReservationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isEditingCustomer, setIsEditingCustomer] = useState(false);
  const [isNewCustomer, setIsNewCustomer] = useState(true);
  const [statusSettings, setStatusSettings] = useState<Array<{
    status_key: string;
    label: string;
  }>>([]);
  const [status, setStatus] = useState(reservation?.status || 'draft');

  const { register, watch, setValue, formState: { errors, isSubmitting } } = methods;

  // Initialize selected items from reservation
  useEffect(() => {
    // Initialize customer data when editing
    if (reservation?.customer_id) {
      const customer = customers.find(c => c.id === reservation.customer_id);
      if (customer) {
        setValue('customer_id', customer.id);
        setValue('customer_name', customer.name);
        setValue('customer_email', customer.email || '');
        setValue('customer_phone', customer.phone || '');
        setIsNewCustomer(false);
      }
    }
  }, [reservation, customers, setValue]);

  useEffect(() => {
    if (reservation?.reservation_items) {
      setSelectedItems(reservation.reservation_items.map(item => ({
        ...item,
        id: crypto.randomUUID(),
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })));
    }
  }, [reservation]);

  const discountType = watch('discount_type');
  const discountAmount = watch('discount_amount');

  useEffect(() => {
    if (businessId) {
      fetchCustomers();
      fetchInventoryItems();
      fetchStatusSettings();
      handleCustomerChange('new');
    }
  }, [businessId]);

  async function fetchStatusSettings() {
    try {
      const { data, error } = await supabase
        .from('reservation_status_settings')
        .select('status_key, label')
        .eq('business_id', businessId);

      if (error) throw error;

      // If no custom settings, use defaults
      if (!data || data.length === 0) {
        setStatusSettings([
          { status_key: 'draft', label: 'Proposal' },
          { status_key: 'reserved', label: 'Reserved' },
          { status_key: 'in_use', label: 'Checked Out' },
          { status_key: 'closed', label: 'Checked In' }
        ]);
      } else {
        setStatusSettings(data);
      }
    } catch (err) {
      console.error('Error fetching status settings:', err);
    }
  }

  async function fetchCustomers() {
    try {
      const { data, error } = await supabase
        .from('customers')
        .select('id, name, email, phone')
        .eq('business_id', businessId)
        .order('name');

      if (error) throw error;
      setCustomers(data || []);
    } catch (err) {
      console.error('Error fetching customers:', err);
    }
  }

  const handleCustomerChange = (customerId: string) => {
    if (customerId === 'new') {
      setIsNewCustomer(true);
      setIsEditingCustomer(false);
      setValue('customer_id', 'new');
      setValue('customer_name', '');
      setValue('customer_email', '');
      setValue('customer_phone', '');
    } else {
      setIsNewCustomer(false);
      setIsEditingCustomer(false);
      setValue('customer_id', customerId);
      const customer = customers.find(c => c.id === customerId);
      if (customer) {
        setValue('customer_name', customer.name);
        setValue('customer_email', customer.email || '');
        setValue('customer_phone', customer.phone || '');
      }
    }
  };

  const handleUpdateCustomer = async () => {
    const customerId = watch('customer_id');
    if (!customerId || isNewCustomer) return;

    try {
      const { error } = await supabase
        .from('customers')
        .update({
          name: watch('customer_name'),
          email: watch('customer_email') || null,
          phone: watch('customer_phone') || null
        })
        .eq('id', customerId);

      if (error) throw error;
      await fetchCustomers();
      setIsEditingCustomer(false);
    } catch (err) {
      console.error('Error updating customer:', err);
      alert('Failed to update customer details');
    }
  };

  async function fetchInventoryItems() {
    try {
      const { data, error } = await supabase
        .from('inventory_items')
        .select('*')
        .eq('business_id', businessId)
        .gt('quantity', 0);

      if (error) throw error;
      setItems(data);
    } catch (err) {
      console.error('Error fetching inventory items:', err);
    } finally {
      setLoading(false);
    }
  }

  const calculateTotal = () => {
    const subtotal = selectedItems.reduce((sum, item) => sum + item.subtotal, 0);
    if (!discountAmount) return subtotal;

    if (discountType === 'percentage') {
      return subtotal * (1 - Number(discountAmount) / 100);
    }
    return subtotal - Number(discountAmount);
  };

  const getStatusLabel = (key: string) => {
    const setting = statusSettings.find(s => s.status_key === key);
    return setting?.label || key;
  };

  const handleFormSubmit = async (formData: any) => {
    if (selectedItems.length === 0) {
      alert('Please add at least one item to the reservation');
      return;
    }

    let customerId = watch('customer_id');
    
    // Create new customer if needed
    if (isNewCustomer) {
      try {
        const { data: newCustomer, error: customerError } = await supabase
          .from('customers')
          .insert([{
            business_id: businessId,
            name: formData.customer_name,
            email: formData.customer_email || null,
            phone: formData.customer_phone || null
          }])
          .select()
          .single();

        if (customerError) throw customerError;
        customerId = newCustomer.id;
      } catch (err) {
        console.error('Error creating customer:', err);
        alert('Failed to create customer');
        return;
      }
    }

    const total = calculateTotal();
    await onSubmit({
      ...formData,
      customer_id: customerId,
      total_price: total,
      status: status, // Use the status from the dropdown
      items: selectedItems
    });
  };

  if (loading) {
    return <div>Loading...</div>;
  }

  return (
    <FormProvider {...methods}>
      <form onSubmit={methods.handleSubmit(handleFormSubmit)} className="space-y-6">
        {/* Status Dropdown */}
        <div className="flex justify-end mb-4">
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setValue('status', e.target.value);
            }}
            className="block w-48 rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          >
            {statusSettings.map(setting => (
              <option key={setting.status_key} value={setting.status_key}>
                {setting.label}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div>
            <label htmlFor="customer_id" className="block text-sm font-medium text-gray-700">
              Customer
            </label>
            <select
              id="customer_id"
              {...register('customer_id')}
              onChange={(e) => handleCustomerChange(e.target.value)}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            >
              <option value="new">New Customer</option>
              <optgroup label="Existing Customers">
              {customers.map((customer) => (
                <option key={customer.id} value={customer.id}>
                  {customer.name}
                </option>
              ))}
              </optgroup>
            </select>
            {errors.customer_name && (
              <p className="mt-1 text-sm text-red-600">{errors.customer_name.message}</p>
            )}
          </div>
        </div>

        {/* Customer Information */}
        <div className="space-y-6 bg-gray-50 p-4 rounded-lg">
          <div className="flex justify-between items-center">
            <h3 className="text-lg font-medium text-gray-900">
              {isNewCustomer ? 'New Customer Information' : 'Customer Details'}
            </h3>
            {!isNewCustomer && (
              <button
                type="button"
                onClick={() => {
                  if (isEditingCustomer) {
                    handleUpdateCustomer();
                  } else {
                    setIsEditingCustomer(true);
                  }
                }}
                className="inline-flex items-center px-3 py-1.5 border border-transparent text-sm font-medium rounded-md text-indigo-700 bg-indigo-100 hover:bg-indigo-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                {isEditingCustomer ? 'Save Changes' : 'Edit Customer'}
              </button>
            )}
          </div>
          
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-3">
            <div>
              <label htmlFor="customer_name" className="block text-sm font-medium text-gray-700">
                Name
              </label>
              <input
                type="text"
                id="customer_name"
                {...register('customer_name', { 
                  required: isNewCustomer ? 'Customer name is required' : false 
                })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                readOnly={!isNewCustomer && !isEditingCustomer}
              />
            </div>

            <div>
              <label htmlFor="customer_email" className="block text-sm font-medium text-gray-700">
                Email
              </label>
              <input
                type="email"
                id="customer_email"
                {...register('customer_email')}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                readOnly={!isNewCustomer && !isEditingCustomer}
              />
            </div>

            <div>
              <label htmlFor="customer_phone" className="block text-sm font-medium text-gray-700">
                Phone
              </label>
              <input
                type="tel"
                id="customer_phone"
                {...register('customer_phone')}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                readOnly={!isNewCustomer && !isEditingCustomer}
              />
            </div>
          </div>
        </div>

        {/* Dates */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
          <div>
            <label htmlFor="start_date" className="block text-sm font-medium text-gray-700">
              Start Date
            </label>
            <input
              type="date"
              id="start_date"
              {...register('start_date', { required: 'Start date is required' })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
            {errors.start_date && (
              <p className="mt-1 text-sm text-red-600">{errors.start_date.message}</p>
            )}
          </div>

          <div>
            <label htmlFor="end_date" className="block text-sm font-medium text-gray-700">
              End Date
            </label>
            <input
              type="date"
              id="end_date"
              {...register('end_date', { required: 'End date is required' })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
            {errors.end_date && (
              <p className="mt-1 text-sm text-red-600">{errors.end_date.message}</p>
            )}
          </div>
        </div>

        <ReservationItems
          selectedItems={selectedItems}
          onItemsChange={setSelectedItems}
        />

        <ReservationDiscount />

        <div className="border-t border-gray-200 pt-4">
          <div className="flex justify-between text-lg font-medium">
            <span>Total:</span>
            <span>${calculateTotal().toFixed(2)}</span>
          </div>
        </div>

        <div className="flex justify-end space-x-3">
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isSubmitting}
            className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {isSubmitting ? 'Saving...' : 'Save'}
          </button>
        </div>
      </form>
    </FormProvider>
  );
}