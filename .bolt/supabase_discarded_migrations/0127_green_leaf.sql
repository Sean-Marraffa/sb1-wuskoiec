-- Drop all existing policies
DROP POLICY IF EXISTS "role_based_select" ON user_roles;
DROP POLICY IF EXISTS "owner_manage_team_members" ON user_roles;
DROP POLICY IF EXISTS "enable_select_own_role" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_select_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_manage_team_members" ON user_roles;
DROP POLICY IF EXISTS "user_role_access" ON user_roles;
DROP POLICY IF EXISTS "user_role_management" ON user_roles;
DROP POLICY IF EXISTS "select_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_roles" ON user_roles;

-- Create simple, non-recursive policies
CREATE POLICY "role_select_policy"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Users can see roles in businesses where they are an owner
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "team_member_policy"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be managing a team member role
    role = 'Team Member'
    AND
    -- Must be an owner of the business
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

-- Create optimized indexes
DROP INDEX IF EXISTS idx_user_roles_efficient;
DROP INDEX IF EXISTS idx_user_roles_owner_efficient;
DROP INDEX IF EXISTS idx_user_roles_team_efficient;
DROP INDEX IF EXISTS idx_user_roles_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner;
DROP INDEX IF EXISTS idx_user_roles_access;

-- Create new indexes with unique names
CREATE INDEX idx_user_roles_access_v3 
ON user_roles(user_id, business_id, role);

CREATE INDEX idx_user_roles_owner_v3 
ON user_roles(user_id, business_id) 
WHERE role = 'Account Owner';