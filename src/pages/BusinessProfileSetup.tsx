import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2 } from 'lucide-react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { SignOutButton } from '../components/SignOutButton';

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

export function BusinessProfileSetup() {
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

  // Debug user metadata
  React.useEffect(() => {
    if (user) {
      console.log('User metadata:', user.user_metadata);
      console.log('Needs business profile:', user.user_metadata?.needs_business_profile);
    }
  }, [user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    setError('');
    setLoading(true);
    
    // Verify user metadata before proceeding
    if (!user.user_metadata?.needs_business_profile) {
      setError('User is not authorized to create a business profile');
      setLoading(false);
      return;
    }

    try {
      // Create business profile
      const { data: business, error: businessError } = await supabase
        .from('businesses').insert({
          name: form.name,
          type: form.type,
          contact_email: form.contactEmail,
          street_address_1: form.streetAddress1,
          street_address_2: form.streetAddress2,
          city: form.city,
          state_province: form.stateProvince,
          postal_code: form.postalCode,
          country: form.country
        }).select().single();

      if (businessError) throw businessError;
      if (!business) throw new Error('Failed to create business profile');

      // Create user role
      const { error: roleError } = await supabase
        .from('user_roles').insert({
          user_id: user.id,
          business_id: business.id,
          role: 'Account Owner'
        });

      if (roleError) throw roleError;

      // Update user metadata only after successful creation
      const { error: updateError } = await supabase.auth.updateUser({
        data: { needs_business_profile: false }
      });

      if (updateError) throw updateError;

      navigate('/billing');
    } catch (err: any) {
      console.error('Error creating business profile:', err);
      setError(
        err.message === 'new row violates row-level security policy for table "business_profiles"'
          ? 'Not authorized to create a business profile'
          : err.message
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="absolute top-0 right-0 m-4">
        <SignOutButton className="bg-white shadow-sm rounded-md" />
      </div>
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="flex justify-center">
          <Building2 className="h-12 w-12 text-indigo-600" />
        </div>
        <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
          Create Your Business Profile
        </h2>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          {error && (
            <div className="mb-4 p-3 text-sm text-red-600 bg-red-50 rounded-md">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Business Information Section */}
            <div className="space-y-6">
              <h3 className="text-lg font-medium text-gray-900 border-b pb-2">
                Business Information
              </h3>
              
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                Business Name
              </label>
              <input
                id="name"
                type="text"
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
                id="contactEmail"
                type="email"
                required
                value={form.contactEmail}
                onChange={(e) => setForm({ ...form, contactEmail: e.target.value })}
                className="mt-1 block w-full rounded-md border border-gray-300 px-3 py-2 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
              />
            </div>
            </div>

            {/* Address Information Section */}
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
              className="w-full flex justify-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Creating...' : 'Create Business Profile'}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}