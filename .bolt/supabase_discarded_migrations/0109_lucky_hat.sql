-- Drop all existing policies
DROP POLICY IF EXISTS "select_own_role" ON user_roles;
DROP POLICY IF EXISTS "select_team_members" ON user_roles;
DROP POLICY IF EXISTS "insert_team_members" ON user_roles;
DROP POLICY IF EXISTS "delete_team_members" ON user_roles;

-- Create extremely simple, flat policies
CREATE POLICY "read_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "read_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  );

CREATE POLICY "write_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_user_roles_user_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;
DROP INDEX IF EXISTS idx_user_roles_team_lookup;

-- Create single composite index
CREATE INDEX idx_user_roles_access ON user_roles(user_id, business_id, role);