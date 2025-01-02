-- Drop all existing policies
DROP POLICY IF EXISTS "allow_select_own_role" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_select_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_manage_team_members" ON user_roles;

-- Create simple, flat policies
CREATE POLICY "user_roles_select_own"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_roles_select_business"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );

CREATE POLICY "user_roles_manage_team"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be managing a team member role
    role = 'Team Member'
    AND
    -- Must be an owner of the business
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
CREATE INDEX IF NOT EXISTS idx_user_roles_owner_lookup 
ON user_roles(user_id, business_id) 
WHERE role = 'Account Owner';

CREATE INDEX IF NOT EXISTS idx_user_roles_team_lookup
ON user_roles(business_id, role) 
WHERE role = 'Team Member';