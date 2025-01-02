-- Drop existing policies
DROP POLICY IF EXISTS "basic_role_access" ON user_roles;
DROP POLICY IF EXISTS "owner_role_management" ON user_roles;
DROP POLICY IF EXISTS "owner_role_deletion" ON user_roles;

-- Create optimized non-recursive policies
CREATE POLICY "user_role_read_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can always see their own roles
    user_id = auth.uid()
  );

CREATE POLICY "owner_role_read_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Owners can see all roles in their business
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "owner_role_insert"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only owners can add team members
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    -- Can only add team members
    AND role = 'Team Member'
  );

CREATE POLICY "owner_role_delete"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only owners can remove team members
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    -- Can only remove team members
    AND role = 'Team Member'
  );

-- Optimize indexes for the new query patterns
DROP INDEX IF EXISTS idx_user_roles_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;

-- Create targeted indexes
CREATE INDEX idx_user_roles_user_lookup ON user_roles(user_id);
CREATE INDEX idx_user_roles_owner_lookup ON user_roles(user_id, business_id) WHERE role = 'Account Owner';
CREATE INDEX idx_user_roles_team_lookup ON user_roles(business_id, role) WHERE role = 'Team Member';