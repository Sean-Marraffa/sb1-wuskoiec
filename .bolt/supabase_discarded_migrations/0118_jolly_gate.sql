-- Drop all existing policies
DROP POLICY IF EXISTS "allow_select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_select_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_insert_team_members" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_delete_team_members" ON user_roles;

-- Create simplified non-recursive policies
CREATE POLICY "enable_select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "enable_select_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Cache owner check in a CTE
    EXISTS (
      WITH owner_roles AS (
        SELECT business_id
        FROM user_roles
        WHERE user_id = auth.uid()
        AND role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = user_roles.business_id
    )
  );

CREATE POLICY "enable_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be a Team Member role
    role = 'Team Member'
    AND
    -- Cache owner check in a CTE
    EXISTS (
      WITH owner_roles AS (
        SELECT business_id
        FROM user_roles
        WHERE user_id = auth.uid()
        AND role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = user_roles.business_id
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    EXISTS (
      WITH owner_roles AS (
        SELECT business_id
        FROM user_roles
        WHERE user_id = auth.uid()
        AND role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = user_roles.business_id
    )
  );

-- Create optimized indexes
DROP INDEX IF EXISTS idx_user_roles_lookup;
DROP INDEX IF EXISTS idx_user_roles_owner;

CREATE INDEX idx_user_roles_efficient ON user_roles(user_id, business_id, role);
CREATE INDEX idx_user_roles_owner_efficient ON user_roles(user_id, business_id) WHERE role = 'Account Owner';