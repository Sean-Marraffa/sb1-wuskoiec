/*
  # Fix user details function

  1. Changes
    - Fix return type mismatch in get_user_details function
    - Ensure consistent type handling for all columns
*/

-- Drop existing function
DROP FUNCTION IF EXISTS get_user_details();

-- Recreate function with correct type handling
CREATE OR REPLACE FUNCTION get_user_details()
RETURNS TABLE (
  id uuid,
  email varchar,
  full_name varchar,
  created_at timestamptz,
  business_name varchar
)
SECURITY DEFINER
SET search_path = auth, public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    au.id,
    au.email::varchar,
    COALESCE(p.full_name, au.raw_user_meta_data->>'full_name', 'No name')::varchar as full_name,
    au.created_at,
    bp.name::varchar as business_name
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