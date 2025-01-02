/*
  # Platform Metrics Function
  
  1. Changes
    - Create a secure function to count total accounts
    - Function checks auth.users table directly
  
  2. Security
    - Function uses SECURITY DEFINER to access auth schema safely
    - Access restricted to authenticated users
*/

-- Function to count total accounts
CREATE OR REPLACE FUNCTION get_total_accounts()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = auth, public
AS $$
  SELECT COUNT(*)::integer
  FROM auth.users
  WHERE deleted_at IS NULL;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_total_accounts() TO authenticated;