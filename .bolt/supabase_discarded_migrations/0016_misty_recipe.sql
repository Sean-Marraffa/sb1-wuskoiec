/*
  # Simplify RLS policies and fix auth flow

  1. Changes
    - Simplify business profile policies to focus on core flows
    - Add explicit super admin bypass
    - Fix user role creation policy
    - Remove redundant policies

  2. Security
    - Maintain proper access control
    - Ensure business profile setup works correctly
    - Allow proper role management
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Super admin full access" ON business_profiles;
DROP POLICY IF EXISTS "Users can create business profiles during setup" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can manage their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Super admin full access for roles" ON user_roles;
DROP POLICY IF EXISTS "Users can create initial role" ON user_roles;

-- Simple, focused policies for business_profiles
CREATE POLICY "business_profiles_super_admin"
  ON business_profiles
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "business_profiles_setup"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true);

CREATE POLICY "business_profiles_view"
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

CREATE POLICY "business_profiles_manage"
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

-- Simple policies for user_roles
CREATE POLICY "user_roles_super_admin"
  ON user_roles
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "user_roles_setup"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
  );