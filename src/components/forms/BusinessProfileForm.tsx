import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../contexts/AuthContext';

interface BusinessProfileForm {
  name: string;
  type: string;
  contactEmail: string;
  streetAddress1: string;
  streetAddress2: string;
  city: string;
  stateProvince: string;
  postalCode: string;
  country: string;
}

export function BusinessProfileForm() {
  const [form, setForm] = useState<BusinessProfileForm>({
    name: '',
    type: '',
    contactEmail: '',
    streetAddress1: '',
    streetAddress2: '',
    city: '',
    stateProvince: '',
    postalCode: '',
    country: ''
  });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const { user } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    setError('');
    setLoading(true);

    try {
      // Get the pending business ID from user metadata
      const pendingBusinessId = user.user_metadata?.pending_business_id;
      if (!pendingBusinessId) {
        throw new Error('No pending business profile found');
      }

      // Update the business profile
      const { error: updateError } = await supabase
        .from('businesses')
        .update({
          name: form.name,
          type: form.type,
          contact_email: form.contactEmail,
          street_address_1: form.streetAddress1,
          street_address_2: form.streetAddress2,
          city: form.city,
          state_province: form.stateProvince,
          postal_code: form.postalCode,
          country: form.country,
          status: 'profile_created',
          status_updated_at: new Date().toISOString()
        }).eq('id', pendingBusinessId);

      if (updateError) throw updateError;

      // Update user metadata
      const { error: userError } = await supabase.auth.updateUser({
        data: {
          needs_business_profile: false,
          has_billing: false
        }
      });

      if (userError) {
        console.error('Error updating user metadata:', userError);
        setError(userError.message);
        setLoading(false);
        return;
      }

      // Create user role if it doesn't exist
      // Check if role already exists
      const { data: existingRole } = await supabase
        .from('business_users')
        .select('id')
        .eq('user_id', user.id)
        .eq('business_id', pendingBusinessId)
        .single();

      if (!existingRole) {
        const { error: roleError } = await supabase
          .from('business_users')
          .insert({
            user_id: user.id,
            business_id: pendingBusinessId,
            role: 'Account Owner'
          });

        if (roleError) {
          console.error('Error creating user role:', roleError);
          setError(roleError.message);
          setLoading(false);
          return;
        }
      }

      // Continue to billing
      navigate('/billing');
    } catch (err: any) {
      console.error('Error updating business profile:', err);
      setError(err.message || 'An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="p-3 text-sm text-red-600 bg-red-50 rounded-md">
          {error}
        </div>
      )}

      <div className="space-y-6">
        <h3 className="text-lg font-medium text-gray-900 border-b pb-2">
          Business Information
        </h3>
        
        <div>
          <label htmlFor="name" className="block text-sm font-medium text-gray-700">
            Business Name
          </label>
          <input
            type="text"
            id="name"
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label htmlFor="type" className="block text-sm font-medium text-gray-700">
            Business Type
          </label>
          <select
            id="type"
            required
            value={form.type}
            onChange={(e) => setForm({ ...form, type: e.target.value })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          >
            <option value="">Select a type</option>
            <option value="Event Venue">Event Venue</option>
            <option value="Equipment Rental">Equipment Rental</option>
            <option value="Studio Space">Studio Space</option>
            <option value="Other">Other</option>
          </select>
        </div>

        <div>
          <label htmlFor="contactEmail" className="block text-sm font-medium text-gray-700">
            Business Contact Email
          </label>
          <input
            type="email"
            id="contactEmail"
            required
            value={form.contactEmail}
            onChange={(e) => setForm({ ...form, contactEmail: e.target.value })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>
      </div>

      <div className="space-y-6">
        <h3 className="text-lg font-medium text-gray-900 border-b pb-2">
          Address Information
        </h3>
        
        <div>
          <label htmlFor="streetAddress1" className="block text-sm font-medium text-gray-700">
            Street Address 1
          </label>
          <input
            type="text"
            id="streetAddress1"
            required
            value={form.streetAddress1}
            onChange={(e) => setForm({ ...form, streetAddress1: e.target.value })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <div>
          <label htmlFor="streetAddress2" className="block text-sm font-medium text-gray-700">
            Street Address 2 (Optional)
          </label>
          <input
            type="text"
            id="streetAddress2"
            value={form.streetAddress2}
            onChange={(e) => setForm({ ...form, streetAddress2: e.target.value })}
            className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="city" className="block text-sm font-medium text-gray-700">
              City
            </label>
            <input
              type="text"
              id="city"
              required
              value={form.city}
              onChange={(e) => setForm({ ...form, city: e.target.value })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label htmlFor="stateProvince" className="block text-sm font-medium text-gray-700">
              State/Province
            </label>
            <input
              type="text"
              id="stateProvince"
              required
              value={form.stateProvince}
              onChange={(e) => setForm({ ...form, stateProvince: e.target.value })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="postalCode" className="block text-sm font-medium text-gray-700">
              Postal Code
            </label>
            <input
              type="text"
              id="postalCode"
              required
              value={form.postalCode}
              onChange={(e) => setForm({ ...form, postalCode: e.target.value })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label htmlFor="country" className="block text-sm font-medium text-gray-700">
              Country
            </label>
            <input
              type="text"
              id="country"
              required
              value={form.country}
              onChange={(e) => setForm({ ...form, country: e.target.value })}
              className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
            />
          </div>
        </div>
      </div>

      <button
        type="submit"
        disabled={loading}
        className="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
      >
        {loading ? 'Creating profile...' : 'Continue'}
      </button>
    </form>
  );
}