-- Drop existing policies
DROP POLICY IF EXISTS "user_role_read_access" ON user_roles;
DROP POLICY IF EXISTS "owner_role_read_access" ON user_roles;
DROP POLICY IF EXISTS "owner_role_insert" ON user_roles;
DROP POLICY IF EXISTS "owner_role_delete" ON user_roles;

-- Drop indexes that might not be optimal
DROP INDEX IF EXISTS idx_user_roles_user_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;
DROP INDEX IF EXISTS idx_user_roles_team_lookup;

-- Create simple non-recursive policies
CREATE POLICY "select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "select_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles base_role
      WHERE base_role.user_id = auth.uid()
      AND base_role.business_id = user_roles.business_id
      LIMIT 1
    )
  );

CREATE POLICY "manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = user_roles.business_id
      AND owner_role.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = user_roles.business_id
      AND owner_role.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Create optimized indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);