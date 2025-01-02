/*
  # Fix RLS policies for business profiles

  1. Changes
    - Drop existing policies for clean slate
    - Create comprehensive policies with proper JSON handling
    - Add explicit super admin access

  2. Security
    - Use proper JSONB casting and operators
    - Maintain strict access control
    - Allow super admins full access
*/

-- Drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can create business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their associated business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can update their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can delete their business profiles" ON business_profiles;

-- Create comprehensive policies
CREATE POLICY "Enable full access for super admins"
  ON business_profiles
  TO authenticated
  USING (
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  )
  WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
  );

CREATE POLICY "Users can create their own business profiles"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Users can view their associated business profiles"
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