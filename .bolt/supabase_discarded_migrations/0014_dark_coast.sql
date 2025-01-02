/*
  # Fix business profile RLS policies

  1. Changes
    - Simplify RLS policies to focus on core requirements
    - Fix business profile creation policy
    - Add policy for user role creation during setup

  2. Security
    - Maintain proper access control
    - Ensure data isolation between businesses
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Super admin full access" ON business_profiles;
DROP POLICY IF EXISTS "Users can create initial business profile" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can update their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can delete their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Initial role creation" ON user_roles;

-- Create simplified policies for business_profiles
CREATE POLICY "Users can create business profiles during setup"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- User must need a business profile
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
  );

CREATE POLICY "Users can view their business profiles"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
    )
    OR
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  );

CREATE POLICY "Account owners can update their business profiles"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );

CREATE POLICY "Account owners can delete their business profiles"
  ON business_profiles
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );

-- Create policy for user_roles during setup
CREATE POLICY "Users can create initial role"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be for the authenticated user
    user_id = auth.uid()
    AND
    -- Must be during business profile setup
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
  );