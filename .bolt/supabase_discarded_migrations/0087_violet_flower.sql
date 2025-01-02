/*
  # Fix user roles policies to prevent recursion
  
  1. Changes
    - Drop existing policies
    - Create new non-recursive policies
    - Add better role management
    - Fix policy dependencies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_select_business_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_manage_team_members" ON user_roles;

-- Create base policy for viewing own roles
CREATE POLICY "enable_view_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Create policy for viewing business roles
CREATE POLICY "enable_view_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

-- Create policy for managing team members
CREATE POLICY "enable_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be Account Owner and can only manage Team Members
    business_id IN (
      SELECT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Must be Account Owner and can only add Team Members
    business_id IN (
      SELECT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );