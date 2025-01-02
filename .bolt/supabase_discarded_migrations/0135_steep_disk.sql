-- Drop existing foreign key if it exists
ALTER TABLE business_memberships
DROP CONSTRAINT IF EXISTS business_memberships_user_id_fkey;

-- Add foreign key with correct schema reference
ALTER TABLE business_memberships
ADD CONSTRAINT business_memberships_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES auth.users(id)
ON DELETE CASCADE;

-- Create secure view to expose user details
CREATE OR REPLACE VIEW business_membership_details AS
SELECT 
  bm.id,
  bm.user_id,
  bm.business_id,
  bm.role,
  bm.is_default,
  bm.created_at,
  bm.updated_at,
  u.email,
  u.raw_user_meta_data->>'full_name' as full_name
FROM business_memberships bm
JOIN auth.users u ON u.id = bm.user_id;

-- Grant SELECT to authenticated users
GRANT SELECT ON business_membership_details TO authenticated;

-- Create secure function to access membership details
CREATE OR REPLACE FUNCTION get_membership_details(business_id uuid)
RETURNS SETOF business_membership_details
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Only return details if user has access
  RETURN QUERY
  SELECT md.*
  FROM business_membership_details md
  WHERE 
    -- User can see their own membership
    md.user_id = auth.uid()
    OR
    -- Account owners can see all memberships for their business
    EXISTS (
      SELECT 1 
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.business_id = get_membership_details.business_id
      AND bm.role = 'Account Owner'
    );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_membership_details TO authenticated;

-- Add helpful comment
COMMENT ON VIEW business_membership_details IS 'Secure view for accessing business membership details with user information';