-- Drop all existing policies
DROP POLICY IF EXISTS "role_select_policy" ON user_roles;
DROP POLICY IF EXISTS "team_member_policy" ON user_roles;
DROP POLICY IF EXISTS "basic_select_policy" ON user_roles;
DROP POLICY IF EXISTS "owner_select_policy" ON user_roles;
DROP POLICY IF EXISTS "owner_manage_policy" ON user_roles;

-- Create simple, non-recursive policies
CREATE POLICY "role_view_policy"
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

CREATE POLICY "role_manage_policy"
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
DROP INDEX IF EXISTS idx_user_roles_access_v3;
DROP INDEX IF EXISTS idx_user_roles_owner_v3;

CREATE INDEX idx_user_roles_lookup_v10 ON user_roles(user_id, business_id, role);
CREATE INDEX idx_user_roles_owner_v10 ON user_roles(user_id, business_id) WHERE role = 'Account Owner';