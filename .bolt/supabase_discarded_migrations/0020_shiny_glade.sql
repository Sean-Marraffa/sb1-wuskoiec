/*
  # Update user count function

  Updates the get_total_users() function to exclude super admins from the count.
*/

CREATE OR REPLACE FUNCTION get_total_users()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = auth, public
AS $$
  SELECT COUNT(*)::integer
  FROM auth.users
  WHERE deleted_at IS NULL
  AND (raw_user_meta_data->>'is_super_admin')::boolean IS NOT TRUE;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_total_users() TO authenticated;