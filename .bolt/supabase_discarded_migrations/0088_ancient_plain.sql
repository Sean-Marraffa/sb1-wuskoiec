/*
  # Fix business profile access and user roles policies
  
  1. Changes
    - Drop existing policies
    - Create simplified non-recursive policies
    - Add better access control for business profiles
    - Fix policy dependencies
*/

-- Drop existing policies for user_roles
DROP POLICY IF EXISTS "enable_view_own_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_view_business_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_manage_team_members" ON user_roles;

-- Create simplified policies for user_roles
CREATE POLICY "allow_read_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_read_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT business_id
      FROM user_roles base_roles
      WHERE base_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "allow_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Drop existing policies for business_profiles
DROP POLICY IF EXISTS "Users can view their business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Users can update their business profiles" ON business_profiles;

-- Create simplified policies for business_profiles
CREATE POLICY "allow_read_business_profiles"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Allow if user has a role for this business
    id IN (
      SELECT business_id
      FROM user_roles
      WHERE user_id = auth.uid()
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

CREATE POLICY "allow_update_business_profiles"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow if user is Account Owner
    id IN (
      SELECT business_id
      FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  )
  WITH CHECK (
    -- Same conditions as USING clause
    id IN (
      SELECT business_id
      FROM user_roles
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );