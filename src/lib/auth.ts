import { AuthError } from '@supabase/supabase-js';

export function getErrorMessage(error: AuthError | null | Error): string {
  if (!error) return '';
  
  // Handle specific Supabase error messages
  switch (error.message) {
    case 'Invalid login credentials':
      return 'Invalid email or password';
    case 'Password is too short':
      return 'Password must be at least 6 characters';
    case 'User already registered':
      return 'An account with this email already exists';
    case 'No user returned':
      return 'Unable to create account. Please try again';
    default:
      return error.message || 'An unexpected error occurred';
  }
}