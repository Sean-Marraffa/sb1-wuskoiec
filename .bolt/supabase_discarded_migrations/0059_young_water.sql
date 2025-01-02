/*
  # Add user deletion function

  1. Changes
    - Add function to safely delete users
    - Add policy to allow super admins to delete users
    
  2. Security
    - Only super admins can execute the function
    - Cascading deletion of all user data
*/

-- Create function to delete users
CREATE OR REPLACE FUNCTION delete_user(user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if the executing user is a super admin
  IF NOT (SELECT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean) THEN
    RAISE EXCEPTION 'Only super admins can delete users';
  END IF;

  -- Delete user from auth.users (this will cascade to all related data)
  DELETE FROM auth.users WHERE id = user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user TO authenticated;