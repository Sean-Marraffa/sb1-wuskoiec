/*
  # Fix user roles policies

  1. Changes
    - Drop all existing user roles policies
    - Create new simplified non-recursive policies
    - Drop materialized view and triggers that may cause issues
    - Add proper indexing
*/

-- Drop existing policies
DROP POLICY IF EXISTS "user_roles_select_own" ON user_roles;
DROP POLICY IF EXISTS "user_roles_select_business" ON user_roles;
DROP POLICY IF EXISTS "user_roles_insert_owner" ON user_roles;
DROP POLICY IF EXISTS "user_roles_delete_owner" ON user_roles;

-- Drop materialized view and related objects
DROP TRIGGER IF EXISTS refresh_user_role_lookup_trigger ON user_roles;
DROP FUNCTION IF EXISTS refresh_user_role_lookup();
DROP MATERIALIZED VIEW IF EXISTS user_role_lookup;

-- Create simple, non-recursive policies
CREATE POLICY "allow_select_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_select_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "allow_owner_insert"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow Account Owners to add Team Members
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role 
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

CREATE POLICY "allow_owner_delete"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only allow Account Owners to remove Team Members
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role 
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_business_id ON user_roles(business_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);