-- Drop all existing policies
DROP POLICY IF EXISTS "user_roles_select_own" ON user_roles;
DROP POLICY IF EXISTS "user_roles_select_business" ON user_roles;
DROP POLICY IF EXISTS "user_roles_manage_team" ON user_roles;

-- Drop existing indexes
DROP INDEX IF EXISTS idx_user_roles_owner_lookup;
DROP INDEX IF EXISTS idx_user_roles_team_lookup;

-- Create simple, non-recursive policies
CREATE POLICY "select_own_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "select_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = user_roles.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  );

CREATE POLICY "manage_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM user_roles owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = user_roles.business_id
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
      AND owner.business_id = user_roles.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Create efficient indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_business_role ON user_roles(business_id, role);

-- Add foreign key reference to auth.users
ALTER TABLE user_roles
DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey,
ADD CONSTRAINT user_roles_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES auth.users(id)
  ON DELETE CASCADE;