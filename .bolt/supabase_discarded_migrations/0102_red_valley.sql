-- Drop problematic policies
DROP POLICY IF EXISTS "basic_user_role_access" ON user_roles;
DROP POLICY IF EXISTS "owner_role_access" ON user_roles;

-- Create non-recursive policies
CREATE POLICY "allow_view_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_owner_manage_roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Direct check without recursion
    (user_id = auth.uid() AND role = 'Account Owner')
    OR
    (role = 'Team Member')
  )
  WITH CHECK (role = 'Team Member');

-- Add index to support the new policy pattern
CREATE INDEX IF NOT EXISTS idx_user_roles_owner_check 
ON user_roles(user_id, role);