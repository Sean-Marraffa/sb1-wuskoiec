/*
  # Fix business profile RLS policies

  1. Changes
    - Drop existing policies and recreate them with proper access control
    - Add policy for initial business profile creation
    - Add policy for super admin access
    - Add policy for user role creation

  2. Security
    - Enable RLS on business_profiles and user_roles tables
    - Add policies for CRUD operations with proper checks
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Enable full access for super admins" ON business_profiles;
DROP POLICY IF EXISTS "Users can create their first business profile" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their associated business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can update their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can delete their business profiles" ON business_profiles;

-- Create new policies for business_profiles
CREATE POLICY "Super admin full access"
  ON business_profiles
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  )
  WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  );

CREATE POLICY "Users can create initial business profile"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow creation if user doesn't have any existing roles
    NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
    )
    AND
    -- User needs business profile flag must be true
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
  )
  WITH CHECK (
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

-- Update user_roles policies
DROP POLICY IF EXISTS "Users can create their own roles" ON user_roles;

CREATE POLICY "Initial role creation"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be for the authenticated user
    user_id = auth.uid()
    AND
    -- User must need a business profile
    (auth.jwt() -> 'user_metadata' ->> 'needs_business_profile')::boolean = true
    AND
    -- Must be their first role
    NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
    )
  );