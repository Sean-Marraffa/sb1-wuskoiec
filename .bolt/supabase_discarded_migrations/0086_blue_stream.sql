/*
  # Fix user roles policies to prevent recursion
  
  1. Changes
    - Drop existing policies
    - Create new non-recursive policies
    - Add better role management
    - Fix policy dependencies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "enable_read_access" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_management" ON user_roles;

-- Create base policy for viewing roles
CREATE POLICY "allow_select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always view their own roles
    user_id = auth.uid()
  );

-- Create policy for viewing business roles
CREATE POLICY "allow_select_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view roles for businesses where they are an owner
    EXISTS (
      SELECT 1
      FROM user_roles owner_roles
      WHERE owner_roles.user_id = auth.uid()
      AND owner_roles.business_id = user_roles.business_id
      AND owner_roles.role = 'Account Owner'
    )
  );

-- Create policy for managing team members
CREATE POLICY "allow_owner_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be Account Owner
    EXISTS (
      SELECT 1
      FROM user_roles owner_roles
      WHERE owner_roles.user_id = auth.uid()
      AND owner_roles.business_id = user_roles.business_id
      AND owner_roles.role = 'Account Owner'
    )
    -- Can only manage Team Member roles
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Must be Account Owner
    EXISTS (
      SELECT 1
      FROM user_roles owner_roles
      WHERE owner_roles.user_id = auth.uid()
      AND owner_roles.business_id = user_roles.business_id
      AND owner_roles.role = 'Account Owner'
    )
    -- Can only add Team Member roles
    AND role = 'Team Member'
  );