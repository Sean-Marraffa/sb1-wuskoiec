/*
  # Fix user listing function

  1. Changes
    - Add function to get user details including email and profile info
    - Include business profile information for each user
    - Exclude super admin users from results
*/

-- Function to get user details including email and business info
CREATE OR REPLACE FUNCTION get_user_details()
RETURNS TABLE (
  id uuid,
  email text,
  full_name text,
  created_at timestamptz,
  business_name text
)
SECURITY DEFINER
SET search_path = auth, public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.id,
    au.email,
    COALESCE(p.full_name, au.raw_user_meta_data->>'full_name', 'No name') as full_name,
    au.created_at,
    bp.name as business_name
  FROM auth.users au
  LEFT JOIN profiles p ON p.id = au.id
  LEFT JOIN user_roles ur ON ur.user_id = au.id
  LEFT JOIN business_profiles bp ON bp.id = ur.business_id
  WHERE 
    au.deleted_at IS NULL
    AND NOT COALESCE((au.raw_user_meta_data->>'is_super_admin')::boolean, false)
  ORDER BY au.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_details() TO authenticated;