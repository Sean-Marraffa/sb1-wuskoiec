-- Drop all existing policies
DROP POLICY IF EXISTS "allow_read_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_read_business_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_manage_team_members" ON user_roles;

-- Drop existing indexes first
DROP INDEX IF EXISTS idx_user_roles_user_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;
DROP INDEX IF EXISTS idx_user_roles_team_lookup;
DROP INDEX IF EXISTS idx_user_roles_lookup;

-- Create simple, non-recursive policies
CREATE POLICY "enable_select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always see their own roles
    user_id = auth.uid()
  );

CREATE POLICY "enable_owner_access"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Cache owner check in a subquery to prevent recursion
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    -- Only allow managing Team Member roles for non-SELECT operations
    AND (
      CASE 
        WHEN current_setting('statement.operation', true) = 'SELECT' THEN true
        ELSE role = 'Team Member'
      END
    )
  )
  WITH CHECK (
    -- Cache owner check in a subquery to prevent recursion
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    -- Only allow adding/modifying Team Member roles
    AND role = 'Team Member'
  );

-- Create new optimized indexes
CREATE INDEX idx_user_roles_efficient ON user_roles(user_id, business_id, role);
CREATE INDEX idx_user_roles_owner_efficient ON user_roles(user_id, business_id) WHERE role = 'Account Owner';
CREATE INDEX idx_user_roles_team_efficient ON user_roles(business_id, role) WHERE role = 'Team Member';