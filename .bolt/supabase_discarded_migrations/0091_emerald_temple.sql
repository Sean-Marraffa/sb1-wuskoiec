/*
  # Fix user roles policies

  1. Changes
    - Drop all existing user roles policies
    - Create new simplified non-recursive policies
    - Use basic USING clauses without subqueries
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_select_own_role" ON user_roles;
DROP POLICY IF EXISTS "allow_select_business_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_insert" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_delete" ON user_roles;

-- Create basic policies without recursion
CREATE POLICY "select_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "select_business_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "owner_manage_role"
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

-- Ensure proper indexing
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_business_id ON user_roles(business_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);

-- Add composite index for common queries
CREATE INDEX IF NOT EXISTS idx_user_roles_composite 
ON user_roles(user_id, business_id, role);