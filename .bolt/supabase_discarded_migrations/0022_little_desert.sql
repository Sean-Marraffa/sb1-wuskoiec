/*
  # Fix user count function

  Updates the get_total_users function to use the profiles table instead of auth.users
  to ensure proper RLS and access control.
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_total_users();

-- Create new function using profiles table
CREATE OR REPLACE FUNCTION get_total_users()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::integer
  FROM profiles
  WHERE is_super_admin IS NOT TRUE;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_total_users() TO authenticated;