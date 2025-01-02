-- Drop all existing policies
DROP POLICY IF EXISTS "view_own_role" ON user_roles;
DROP POLICY IF EXISTS "view_business_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_team_members" ON user_roles;

-- Create flat, non-recursive policies
CREATE POLICY "select_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "select_team_members"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Only allow selecting team members if you're an owner
    role = 'Team Member' AND
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "insert_team_members"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only allow inserting team members if you're an owner
    role = 'Team Member' AND
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "delete_team_members"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only allow deleting team members if you're an owner
    role = 'Team Member' AND
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

-- Optimize indexes for these specific queries
DROP INDEX IF EXISTS idx_user_roles_lookup;
CREATE INDEX idx_user_roles_user_lookup ON user_roles(user_id);
CREATE INDEX idx_user_roles_owner_lookup ON user_roles(business_id, role) WHERE role = 'Account Owner';
CREATE INDEX idx_user_roles_team_lookup ON user_roles(business_id, role) WHERE role = 'Team Member';