-- Drop all existing policies
DROP POLICY IF EXISTS "enable_select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_access" ON user_roles;

-- Create non-recursive policies
CREATE POLICY "allow_select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always see their own roles
    user_id = auth.uid()
  );

CREATE POLICY "allow_owner_select_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Use a separate subquery to check ownership
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_owner_insert_team_members"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow adding team members
    role = 'Team Member'
    AND
    -- Check ownership in subquery
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_owner_delete_team_members"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only allow deleting team members
    role = 'Team Member'
    AND
    -- Check ownership in subquery
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

-- Create optimized indexes
DROP INDEX IF EXISTS idx_user_roles_efficient;
DROP INDEX IF EXISTS idx_user_roles_owner_efficient;
DROP INDEX IF EXISTS idx_user_roles_team_efficient;

CREATE INDEX idx_user_roles_lookup ON user_roles(user_id, business_id, role);
CREATE INDEX idx_user_roles_owner ON user_roles(user_id, business_id) WHERE role = 'Account Owner';