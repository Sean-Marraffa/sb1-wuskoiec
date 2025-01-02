import { supabase } from '../lib/supabase';
import type { UserCreateData } from '../types/user';

export async function createTeamMember(
  businessId: string,
  userData: UserCreateData
) {
  try {
    // Call the RPC function to create team member
    const { data, error } = await supabase.rpc('create_team_member', {
      p_business_id: businessId,
      p_email: userData.email,
      p_password: userData.password,
      p_full_name: userData.name
    });

    if (error) {
      throw error;
    }

    if (!data.success) {
      throw new Error(data.error);
    }

    return { success: true, userId: data.user_id };
  } catch (error: any) {
    console.error('Error creating team member:', error);
    return { 
      success: false, 
      error: error.message || error.msg || 'Failed to create team member'
    };
  }
}