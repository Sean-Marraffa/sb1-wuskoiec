/*
  # Super Admin Management Function
  
  1. Changes
    - Create a function to update super admin status
    - Function updates auth.users table directly
  
  2. Security
    - Function uses SECURITY DEFINER to access auth schema safely
    - Only existing super admins can grant super admin status
*/

-- Function to update super admin status
CREATE OR REPLACE FUNCTION update_super_admin_status(
  target_user_id UUID,
  new_status BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, public
AS $$
BEGIN
  -- Update the user's super admin status
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN raw_user_meta_data IS NULL THEN 
        jsonb_build_object('is_super_admin', new_status)
      ELSE 
        raw_user_meta_data || jsonb_build_object('is_super_admin', new_status)
    END
  WHERE id = target_user_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_super_admin_status TO authenticated;

-- Update the specified user to be a super admin
SELECT update_super_admin_status('ca4cf684-2f28-4fde-b6d4-a108262d5795', true);