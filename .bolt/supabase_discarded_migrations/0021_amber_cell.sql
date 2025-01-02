/*
  # Fix RLS policies for business setup

  Adjusts policies to properly handle the initial business profile and role creation flow.
  
  Changes:
  1. Updates business profile creation policy to be more permissive during setup
  2. Updates user role creation policy to allow initial role creation
  3. Ensures proper order of operations for setup flow
*/

-- Drop and recreate the business profile creation policy
DROP POLICY IF EXISTS "user_create_during_setup" ON business_profiles;

CREATE POLICY "user_create_during_setup"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow users who need to set up their profile
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
  );

-- Drop and recreate the user role creation policy
DROP POLICY IF EXISTS "create_initial_role" ON user_roles;

CREATE POLICY "create_initial_role"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be creating a role for themselves
    user_id = auth.uid()
    -- Must be in setup mode
    AND (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
    -- Must be creating an Account Owner role
    AND role = 'Account Owner'
    -- Must not already have any roles
    AND NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
    )
  );