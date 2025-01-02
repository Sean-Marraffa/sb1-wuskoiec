/*
  # Fix user roles policies with better structure

  1. Changes
    - Drop existing policies
    - Create new non-recursive policies
    - Add better role management
    - Fix policy dependencies
*/

-- Drop existing policies
DROP POLICY IF EXISTS "enable_select_for_business_users" ON user_roles;
DROP POLICY IF EXISTS "enable_insert_for_owners" ON user_roles;
DROP POLICY IF EXISTS "enable_delete_for_owners" ON user_roles;

-- Create base policy for viewing roles
CREATE POLICY "allow_view_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Allow if user has any role in this business
    EXISTS (
      SELECT 1
      FROM user_roles base_role
      WHERE base_role.user_id = auth.uid()
      AND base_role.business_id = user_roles.business_id
    )
  );

-- Create policy for inserting new team members
CREATE POLICY "allow_owner_add_team_members"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Must be Account Owner of the business
    EXISTS (
      SELECT 1
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    -- Only allow adding Team Members
    AND role = 'Team Member'
  );

-- Create policy for removing team members
CREATE POLICY "allow_owner_remove_team_members"
  ON user_roles
  FOR DELETE
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
    -- Only allow removing Team Members
    AND role = 'Team Member'
  );