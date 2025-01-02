/*
  # Fix user count function

  Updates the get_total_users function to properly handle user counting by:
  1. Using auth.users table instead of profiles
  2. Filtering out super admins and deleted users
  3. Properly handling null metadata
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_total_users();

-- Create new function
CREATE OR REPLACE FUNCTION get_total_users()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = auth, public
AS $$
  SELECT COUNT(*)::integer
  FROM auth.users
  WHERE deleted_at IS NULL
  AND (
    raw_user_meta_data IS NULL
    OR NOT COALESCE((raw_user_meta_data->>'is_super_admin')::boolean, false)
  );
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_total_users() TO authenticated;