import { supabase } from '../lib/supabase';
import type { Business, SubscriptionInterval } from '../types/business';

export async function updateBusinessStatus(
  businessId: string, 
  status: Business['status']
): Promise<{ error: Error | null }> {
  try {
    const { error } = await supabase
      .from('businesses')
      .update({ 
        status,
        status_updated_at: new Date().toISOString()
      })
      .eq('id', businessId);

    if (error) throw error;
    return { error: null };
  } catch (err) {
    console.error('Error updating business status:', err);
    return { error: err as Error };
  }
}

export async function createSubscription(
  businessId: string,
  interval: SubscriptionInterval,
  price: number
): Promise<{ error: Error | null }> {
  try {
    // Get the plan ID for the selected interval
    const { data: plans, error: planError } = await supabase
      .from('billing_plans')
      .select('id')
      .eq('interval', interval)
      .eq('price', price)
      .single();

    if (planError) throw planError;
    if (!plans) throw new Error('Plan not found');

    // Create the subscription
    const { error } = await supabase
      .from('business_subscriptions')
      .insert({
        business_id: businessId,
        plan_id: plans.id,
        status: 'active',
        current_period_start: new Date().toISOString(),
        current_period_end: new Date(
          Date.now() + (interval === 'yearly' ? 365 : 30) * 24 * 60 * 60 * 1000
        ).toISOString()
      });

    if (error) throw error;
    return { error: null };
  } catch (err) {
    console.error('Error creating subscription:', err);
    return { error: err as Error };
  }
}