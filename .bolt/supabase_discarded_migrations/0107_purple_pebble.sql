-- Drop all existing policies
DROP POLICY IF EXISTS "basic_user_role_access" ON user_roles;
DROP POLICY IF EXISTS "owner_role_access" ON user_roles;

-- Create simple, non-recursive policies
CREATE POLICY "view_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "view_business_roles"
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

CREATE POLICY "manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Ensure we have the right index
DROP INDEX IF EXISTS idx_user_roles_lookup;
CREATE INDEX idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);