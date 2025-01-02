-- Drop existing policies
DROP POLICY IF EXISTS "enable_select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_select_business_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_manage_team_members" ON user_roles;

-- Create simplified policies
CREATE POLICY "user_role_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Users can see roles for businesses they own
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "user_role_management"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Only owners can manage team members
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_user_roles_efficient;
DROP INDEX IF EXISTS idx_user_roles_owner_efficient;

CREATE INDEX idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);

CREATE INDEX idx_user_roles_owner_lookup 
ON user_roles(user_id, business_id) 
WHERE role = 'Account Owner';