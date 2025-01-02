-- Drop all policies and functions from migrations 0102-0105
DROP POLICY IF EXISTS "view_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_team_members" ON user_roles;
DROP POLICY IF EXISTS "delete_team_members" ON user_roles;
DROP POLICY IF EXISTS "allow_view_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_manage_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_role_access" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_team_management" ON user_roles;
DROP FUNCTION IF EXISTS delete_team_member(UUID, UUID);

-- Restore original policies from migration 0101
CREATE POLICY "basic_user_role_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
  );

CREATE POLICY "owner_role_access"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Account Owners can manage team members
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    AND (
      -- Can only manage Team Member roles
      role = 'Team Member'
      OR
      -- Or view any role
      current_setting('role_access.operation', true) = 'SELECT'
    )
  )
  WITH CHECK (
    -- Account Owners can only add/modify Team Member roles
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Drop and recreate index to ensure clean state
DROP INDEX IF EXISTS idx_user_roles_efficient_lookup;
DROP INDEX IF EXISTS idx_user_roles_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_check;

-- Create single efficient index
CREATE INDEX idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);