-- Drop existing policies
DROP POLICY IF EXISTS "select_own_role" ON user_roles;
DROP POLICY IF EXISTS "select_business_role" ON user_roles;
DROP POLICY IF EXISTS "owner_manage_role" ON user_roles;

-- Create non-recursive policies
CREATE POLICY "basic_role_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Users can see roles for businesses where they are an owner
    business_id IN (
      SELECT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "owner_role_management"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only owners can add team members
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
    )
    -- Can only add team members
    AND role = 'Team Member'
  );

CREATE POLICY "owner_role_deletion"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only owners can remove team members
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
    )
    -- Can only remove team members
    AND role = 'Team Member'
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_user_roles_composite;
CREATE INDEX idx_user_roles_lookup ON user_roles(user_id, business_id, role);
CREATE INDEX idx_user_roles_owner_lookup ON user_roles(business_id, role) WHERE role = 'Account Owner';