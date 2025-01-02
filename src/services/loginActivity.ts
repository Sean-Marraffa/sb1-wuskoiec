import { supabase } from '../lib/supabase';

export async function recordLoginActivity(userId: string, success: boolean) {
  try {
    const { error } = await supabase
      .from('login_activity')
      .insert({
        user_id: userId,
        status: success ? 'success' : 'failed',
        ip_address: 'unknown', // We can't reliably get IP in browser
        user_agent: navigator.userAgent || 'unknown'
      });

    if (error) {
      console.error('Error recording login activity:', error);
    }
  } catch (err) {
    console.error('Failed to record login activity:', err);
  }
}