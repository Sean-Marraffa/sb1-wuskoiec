-- Drop existing policies and functions
DROP POLICY IF EXISTS "enable_role_access" ON user_roles;
DROP POLICY IF EXISTS "enable_owner_team_management" ON user_roles;
DROP FUNCTION IF EXISTS delete_team_member(UUID, UUID);

-- Create simple, non-recursive policies
CREATE POLICY "view_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view their own role
    user_id = auth.uid()
    OR
    -- Users can view roles in businesses where they are an owner
    business_id IN (
      SELECT business_id 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "manage_team_members"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only Account Owners can add team members
    EXISTS (
      SELECT 1 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND business_id = user_roles.business_id 
      AND role = 'Account Owner'
    )
    -- Can only add team member roles
    AND role = 'Team Member'
  );

CREATE POLICY "delete_team_members"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    -- Only Account Owners can delete team members
    EXISTS (
      SELECT 1 
      FROM user_roles 
      WHERE user_id = auth.uid() 
      AND business_id = user_roles.business_id 
      AND role = 'Account Owner'
    )
    -- Can only delete team member roles
    AND role = 'Team Member'
  );

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);