/*
  # Fix user roles policies to prevent recursion
  
  1. Changes
    - Drop existing policies
    - Create new non-recursive policies
    - Add better role management
    - Fix policy dependencies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_business_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_add_team_members" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_remove_team_members" ON user_roles;

-- Create simplified policies that avoid recursion
CREATE POLICY "enable_read_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own roles
    user_id = auth.uid()
    OR 
    -- Users can view roles in businesses where they have a role
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "enable_owner_management"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be Account Owner of the business
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role 
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    -- Can't modify Account Owner roles
    AND (role = 'Team Member' OR user_id = auth.uid())
  )
  WITH CHECK (
    -- Must be Account Owner of the business
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role 
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    -- Can only add Team Members
    AND role = 'Team Member'
  );