/*
  # Fix RLS policies for business profile creation

  1. Changes
    - Add super admin bypass for all operations
    - Simplify business profile creation policy
    - Fix user role creation policy
    - Add missing policies for super admins

  2. Security
    - Maintain proper access control
    - Allow super admins full access
    - Ensure proper business profile setup flow
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create business profiles during setup" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can update their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can delete their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Users can create initial role" ON user_roles;

-- Create comprehensive policies for business_profiles
CREATE POLICY "Super admin full access"
  ON business_profiles
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "Users can create business profiles during setup"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Either super admin or needs business profile
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
  );

CREATE POLICY "Users can view their business profiles"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Either super admin or has role for this business
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Account owners can manage their business profiles"
  ON business_profiles
  FOR ALL
  TO authenticated
  USING (
    -- Either super admin or account owner
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    -- Either super admin or account owner
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );

-- Create policies for user_roles
CREATE POLICY "Super admin full access for roles"
  ON user_roles
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "Users can create initial role"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be for the authenticated user
    user_id = auth.uid()
    AND
    -- Either super admin or needs business profile
    (
      (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
      OR
      (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
    )
  );