/*
  # Update RLS policies and business count function
  
  1. Changes
    - Drop and recreate all business profile policies with unique names
    - Drop and recreate user role policies with unique names
    - Recreate get_total_businesses function
  
  2. Security
    - Maintain RLS for all tables
    - Update policies for super admin access
    - Update policies for business profile management
*/

DO $$ 
BEGIN
  -- Drop all existing policies if they exist
  DROP POLICY IF EXISTS "bp_super_admin_view" ON business_profiles;
  DROP POLICY IF EXISTS "bp_setup_insert" ON business_profiles;
  DROP POLICY IF EXISTS "bp_user_view" ON business_profiles;
  DROP POLICY IF EXISTS "bp_owner_manage" ON business_profiles;
  DROP POLICY IF EXISTS "ur_setup_insert" ON user_roles;
  
  -- Also drop any old policy names that might exist
  DROP POLICY IF EXISTS "business_profiles_super_admin" ON business_profiles;
  DROP POLICY IF EXISTS "business_profiles_setup" ON business_profiles;
  DROP POLICY IF EXISTS "business_profiles_view" ON business_profiles;
  DROP POLICY IF EXISTS "business_profiles_manage" ON business_profiles;
  DROP POLICY IF EXISTS "user_roles_super_admin" ON user_roles;
  DROP POLICY IF EXISTS "user_roles_setup" ON user_roles;
END $$;

-- Recreate all policies with new names to avoid conflicts
CREATE POLICY "bp_super_admin_access_19"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "bp_setup_insert_19"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
    AND NOT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean
  );

CREATE POLICY "bp_user_view_19"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "bp_owner_manage_19"
  ON business_profiles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );

CREATE POLICY "ur_setup_insert_19"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
    AND NOT (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean
  );

-- Recreate the business count function
DO $$ 
BEGIN
  DROP FUNCTION IF EXISTS get_total_businesses();
END $$;

CREATE OR REPLACE FUNCTION get_total_businesses()
RETURNS INTEGER
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::integer
  FROM business_profiles;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_total_businesses() TO authenticated;