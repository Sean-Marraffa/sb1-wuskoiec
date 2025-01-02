/*
  # Add total users function
  
  1. Changes
    - Add function to count total users
  
  2. Security
    - Function is security definer
    - Only accessible to authenticated users
*/

CREATE OR REPLACE FUNCTION get_total_users()
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
GRANT EXECUTE ON FUNCTION get_total_users() TO authenticated;