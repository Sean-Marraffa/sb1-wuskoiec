import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Check } from 'lucide-react';
import { useBusinessProfile } from '../../hooks/useBusinessProfile';
import { supabase } from '../../lib/supabase';
import { updateBusinessStatus, createSubscription } from '../../services/businessService';

interface BillingPlan {
  id: string;
  name: string;
  features: Record<string, any>;
  is_active: boolean;
  monthly_price: number;
  yearly_price: number;
  monthly_pricing_id: string;
  yearly_pricing_id: string;
}

export function PlanSelectionForm() {
  const [selectedPlan, setSelectedPlan] = useState<BillingPlan | null>(null);
  const [selectedInterval, setSelectedInterval] = useState<'monthly' | 'yearly'>('monthly');
  const [plans, setPlans] = useState<BillingPlan[]>([]);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();
  const { businessProfile } = useBusinessProfile();

  useEffect(() => {
    fetchPlans();
  }, []);

  async function fetchPlans() {
    try {
      const { data: plansData, error: plansError } = await supabase
        .rpc('get_billing_plans_with_pricing');

      if (plansError) throw plansError;

      console.log('Fetched plans:', plansData);
      setPlans(plansData || []);
      if (plansData?.length > 0) {
        setSelectedPlan(plansData[0]);
      }

    } catch (err) {
      console.error('Error fetching plans:', err);
      setError('Failed to load pricing plans');
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedPlan || !businessProfile?.id) return;
    
    setProcessing(true);
    setError(null);

    try {
      const price = selectedInterval === 'monthly' 
        ? selectedPlan.monthly_price 
        : selectedPlan.yearly_price;
      
      const pricingId = selectedInterval === 'monthly'
        ? selectedPlan.monthly_pricing_id
        : selectedPlan.yearly_pricing_id;

      // Create business subscription
      const { error: subscriptionError } = await supabase
        .from('business_subscriptions')
        .insert({
          business_id: businessProfile.id,
          plan_id: selectedPlan.id,
          pricing_id: pricingId,
          status: 'active',
          current_period_start: new Date().toISOString(),
          current_period_end: new Date(
            Date.now() + (selectedInterval === 'yearly' ? 365 : 30) * 24 * 60 * 60 * 1000
          ).toISOString()
        });
      
      if (subscriptionError) throw subscriptionError;

      // Update user metadata to indicate billing is complete
      const { error } = await supabase.auth.updateUser({
        data: { 
          has_billing: true,
          selected_plan: selectedInterval,
          billing_price: price
        }
      });

      if (error) throw error;

      // Update business status to active
      const { error: statusError } = await updateBusinessStatus(businessProfile.id, 'active');
      if (statusError) throw statusError;
    
      // Navigate to dashboard after successful update
      navigate('/dashboard');
    } catch (err) {
      console.error('Error updating billing status:', err);
      setError(err instanceof Error ? err.message : 'An error occurred');
      setProcessing(false);
    }
  };

  const getMonthlyPrice = (plan: BillingPlan) => {
    return selectedInterval === 'monthly' ? plan.monthly_price : plan.yearly_price;
  };

  const calculateSavings = (plan: BillingPlan) => {
    if (!plan.monthly_price || !plan.yearly_price) return null;

    const monthlyCost = plan.monthly_price;
    const yearlyCost = plan.yearly_price;
    const savings = monthlyCost * 12 - yearlyCost * 12;
    const savingsPercentage = Math.round(((monthlyCost - yearlyCost) / monthlyCost) * 100);

    return {
      amount: savings,
      percentage: savingsPercentage
    };
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="max-w-lg mx-auto bg-red-50 p-4 rounded-lg">
          <p className="text-sm text-red-600">{error}</p>
        </div>
      )}

      <div className="space-y-8">
        {plans.map((plan) => {
          const savings = calculateSavings(plan);
          const monthlyPrice = getMonthlyPrice(plan);

          return (
            <div
              key={plan.id}
              className={`relative flex flex-col text-left p-8 rounded-lg border-2 transition-all ${
                selectedPlan?.id === plan.id
                  ? 'border-indigo-600 ring-2 ring-indigo-600 shadow-lg'
                  : 'border-gray-200 hover:border-indigo-200'
              }`}
              onClick={() => setSelectedPlan(plan)}
            >
              {selectedPlan?.id === plan.id && (
                <div className="absolute top-0 right-0 transform translate-x-1/4 -translate-y-1/4">
                  <div className="bg-indigo-600 text-white p-2 rounded-full">
                    <Check className="h-5 w-5" />
                  </div>
                </div>
              )}

              <div className="text-center">
                <h3 className="text-xl font-semibold text-gray-900">{plan.name}</h3>
                <div className="mt-4 space-y-4">
                  <div className="space-y-2">
                    <div className="flex justify-center space-x-4">
                      <button
                        type="button"
                        onClick={() => setSelectedInterval('monthly')}
                        className={`px-4 py-2 text-sm font-medium rounded-md ${
                          selectedInterval === 'monthly'
                            ? 'bg-indigo-600 text-white'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        Monthly
                      </button>
                      <button
                        type="button"
                        onClick={() => setSelectedInterval('yearly')}
                        className={`px-4 py-2 text-sm font-medium rounded-md ${
                          selectedInterval === 'yearly'
                            ? 'bg-indigo-600 text-white'
                            : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        }`}
                      >
                        Yearly
                      </button>
                    </div>

                    <div className="text-center">
                      <p className="text-4xl font-bold text-gray-900">
                        ${monthlyPrice}
                        <span className="text-lg font-normal text-gray-500">
                          /month{selectedInterval === 'yearly' ? ' when billed annually' : ''}
                        </span>
                      </p>
                      {selectedInterval === 'yearly' && savings && (
                        <div className="mt-2">
                          <p className="text-sm font-medium text-green-600">
                            Save {savings.percentage}% when billed annually
                          </p>
                          <p className="text-xs text-gray-500 mt-1">
                            ${monthlyPrice * 12} billed yearly
                          </p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              <ul className="mt-8 space-y-4 flex-1">
                {Object.entries(plan.features).map(([key, value]) => (
                  <li key={key} className="flex items-start">
                    <Check className="h-5 w-5 text-green-500 flex-shrink-0" />
                    <span className="ml-3 text-sm text-gray-700">{value}</span>
                  </li>
                ))}
              </ul>
            </div>
          );
        })}
      </div>

      <div className="max-w-lg mx-auto bg-gray-50 p-4 rounded-lg">
        <p className="text-sm text-gray-500">
          Note: This is a test environment. No actual payment will be processed.
        </p>
      </div>

      <button
        type="submit"
        disabled={processing || !selectedPlan}
        className="max-w-lg w-full mx-auto flex justify-center py-2.5 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50"
      >
        {processing ? 'Processing...' : 'Confirm Plan'}
      </button>
    </form>
  );
}