/*
  # Update RLS policies for business profiles

  1. Changes
    - Drop and recreate business profiles policies with proper column access
    - Add policy for updating business profiles
    - Add policy for deleting business profiles

  2. Security
    - Only authenticated users can create business profiles
    - Account owners can update their own business profiles
    - Account owners can delete their own business profiles
*/

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Users can view their associated business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Account owners can update their business profiles" ON business_profiles;

-- Recreate policies with proper access control
CREATE POLICY "Users can create business profiles"
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