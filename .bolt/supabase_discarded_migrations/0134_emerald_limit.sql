-- Drop existing function
DROP FUNCTION IF EXISTS get_user_details();

-- Create improved function using business_memberships
CREATE OR REPLACE FUNCTION get_user_details()
RETURNS TABLE (
  id uuid,
  email varchar,
  full_name varchar,
  created_at timestamptz,
  business_name varchar
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.id,
    au.email::varchar,
    COALESCE(up.full_name, au.raw_user_meta_data->>'full_name', 'No name')::varchar as full_name,
    au.created_at,
    bp.name::varchar as business_name
  FROM auth.users au
  LEFT JOIN user_profiles up ON up.id = au.id
  LEFT JOIN business_memberships bm ON bm.user_id = au.id
  LEFT JOIN business_profiles bp ON bp.id = bm.business_id
  WHERE 
    au.deleted_at IS NULL
    AND NOT COALESCE((au.raw_user_meta_data->>'is_super_admin')::boolean, false)
  ORDER BY au.created_at DESC;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_user_details TO authenticated;