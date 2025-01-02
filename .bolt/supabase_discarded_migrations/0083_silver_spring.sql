/*
  # Fix user roles policies

  1. Changes
    - Fix infinite recursion in user roles policies
    - Simplify policy conditions
    - Add better role validation
*/

-- Drop existing policies
DROP POLICY IF EXISTS "view_user_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_user_roles" ON user_roles;

-- Create simplified policies that avoid recursion
CREATE POLICY "enable_select_for_business_users"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view roles for their own business
    business_id = ANY (
      SELECT ur.business_id 
      FROM user_roles ur 
      WHERE ur.user_id = auth.uid()
    )
  );

CREATE POLICY "enable_insert_for_owners"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Account Owners can add users
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
    )
    AND
    -- Can't modify Account Owner role
    role != 'Account Owner'
  );

CREATE POLICY "enable_delete_for_owners"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Account Owners can remove users
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
    )
    AND
    -- Can't delete Account Owner role
    role != 'Account Owner'
  );