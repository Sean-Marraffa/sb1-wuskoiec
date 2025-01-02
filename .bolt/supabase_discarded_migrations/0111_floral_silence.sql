-- Drop existing policies
DROP POLICY IF EXISTS "enable_read_own_role" ON user_roles;
DROP POLICY IF EXISTS "enable_read_business_roles" ON user_roles;
DROP POLICY IF EXISTS "enable_write_team_members" ON user_roles;

-- Drop materialized view and related objects
DROP TRIGGER IF EXISTS refresh_user_role_lookup_trigger ON user_roles;
DROP FUNCTION IF EXISTS refresh_user_role_lookup();
DROP MATERIALIZED VIEW IF EXISTS user_role_lookup;

-- Create simple policies without recursion
CREATE POLICY "allow_select_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_owner_select_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  );

CREATE POLICY "allow_owner_manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );