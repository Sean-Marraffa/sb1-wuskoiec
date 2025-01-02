import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Building2, CheckCircle2 } from 'lucide-react';

interface Plan {
  id: 'monthly' | 'yearly';
  name: string;
  price: string;
  description: string;
  features: string[];
  savings?: string;
}

const plans: Plan[] = [
  {
    id: 'monthly',
    name: 'Monthly Plan',
    price: '$25/month',
    description: 'Perfect for getting started',
    features: [
      'First month free',
      'No long-term commitment',
      'All features included',
      'Cancel anytime'
    ]
  },
  {
    id: 'yearly',
    name: 'Yearly Plan',
    price: '$20/month',
    description: 'Best value for your business',
    features: [
      'All features included',
      'Priority support',
      'Advanced analytics',
      'Bulk discounts'
    ],
    savings: 'Save $60/year!'
  }
];

export function BillingPage() {
  const [selectedPlan, setSelectedPlan] = useState<'monthly' | 'yearly'>('monthly');
  const [processing, setProcessing] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setProcessing(true);

    try {
      // Update user metadata to indicate billing is complete
      const { error } = await supabase.auth.updateUser({
        data: { has_billing: true }
      });

      if (error) throw error;
    
      // Navigate to dashboard after successful update
      navigate('/dashboard');
    } catch (err) {
      console.error('Error updating billing status:', err);
      setProcessing(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            <div className="flex items-center">
              <Building2 className="h-8 w-8 text-indigo-600" />
              <span className="ml-2 text-xl font-bold text-gray-900">BookingVibe</span>
            </div>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto py-12 px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-gray-900">Choose your plan</h1>
          <p className="mt-4 text-lg text-gray-600">
            Select the plan that best fits your business needs
          </p>
        </div>

        <div className="mt-12 space-y-4">
          {plans.map((plan) => (
            <div
              key={plan.id}
              className={`relative rounded-lg border p-6 cursor-pointer ${
                selectedPlan === plan.id
                  ? 'border-indigo-600 ring-2 ring-indigo-600'
                  : 'border-gray-300'
              }`}
              onClick={() => setSelectedPlan(plan.id)}
            >
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-lg font-medium text-gray-900">
                    {plan.name}
                    {plan.savings && (
                      <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        {plan.savings}
                      </span>
                    )}
                  </h3>
                  <p className="mt-1 text-sm text-gray-500">{plan.description}</p>
                  <p className="mt-2 text-lg font-medium text-gray-900">{plan.price}</p>
                </div>
                <div className={`h-6 w-6 rounded-full border ${
                  selectedPlan === plan.id
                    ? 'border-indigo-600 bg-indigo-600'
                    : 'border-gray-300'
                }`}>
                  {selectedPlan === plan.id && (
                    <CheckCircle2 className="h-6 w-6 text-white" />
                  )}
                </div>
              </div>
              <ul className="mt-4 space-y-2">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex items-center text-sm text-gray-500">
                    <CheckCircle2 className="h-4 w-4 text-green-500 mr-2" />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        <form onSubmit={handleSubmit} className="mt-12 space-y-6">
          <div className="bg-white rounded-lg shadow-sm p-6 space-y-4">
            <h3 className="text-lg font-medium text-gray-900">Payment Information</h3>
            <p className="text-sm text-gray-500">
              Note: This is a test environment. No actual payment will be processed.
            </p>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Card Number
                </label>
                <input
                  type="text"
                  disabled
                  value="**** **** **** ****"
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm bg-gray-50"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Expiration
                  </label>
                  <input
                    type="text"
                    disabled
                    value="**/**"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm bg-gray-50"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    CVV
                  </label>
                  <input
                    type="text"
                    disabled
                    value="***"
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm bg-gray-50"
                  />
                </div>
              </div>
            </div>
          </div>

          <button
            type="submit"
            disabled={processing}
            className="w-full flex justify-center py-3 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
          >
            {processing ? 'Processing...' : 'Confirm Plan'}
          </button>
        </form>
      </div>
    </div>
  );
}