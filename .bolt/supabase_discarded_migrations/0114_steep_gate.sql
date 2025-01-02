-- Drop all existing policies
DROP POLICY IF EXISTS "select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "select_business_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_team_members" ON user_roles;

-- Create simple, non-recursive policies using subqueries
CREATE POLICY "allow_read_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_read_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Cache owner check in a subquery to prevent recursion
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be managing a Team Member role
    role = 'Team Member'
    AND
    -- Cache owner check in a subquery to prevent recursion
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

-- Create efficient indexes
DROP INDEX IF EXISTS idx_user_roles_user_id;
DROP INDEX IF EXISTS idx_user_roles_business_role;

CREATE INDEX idx_user_roles_user_lookup ON user_roles(user_id);
CREATE INDEX idx_user_roles_owner_lookup ON user_roles(user_id, business_id) WHERE role = 'Account Owner';
CREATE INDEX idx_user_roles_team_lookup ON user_roles(business_id, role) WHERE role = 'Team Member';