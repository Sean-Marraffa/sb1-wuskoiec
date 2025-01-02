-- Drop existing policies
DROP POLICY IF EXISTS "allow_view_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_owner_manage_roles" ON user_roles;

-- Create improved policies for user roles
CREATE POLICY "enable_role_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Account Owners can see roles for their business
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
  );

CREATE POLICY "enable_owner_team_management"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Account Owners can manage team members
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    -- Only allow managing Team Member roles
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Account Owners can only add Team Members
    EXISTS (
      SELECT 1 
      FROM user_roles owner_role
      WHERE owner_role.user_id = auth.uid()
      AND owner_role.business_id = business_id
      AND owner_role.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Create function to handle team member deletion
CREATE OR REPLACE FUNCTION delete_team_member(
  team_member_id UUID,
  business_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  -- Check if the executing user is an Account Owner for this business
  IF NOT EXISTS (
    SELECT 1 
    FROM user_roles
    WHERE user_id = auth.uid()
    AND business_id = delete_team_member.business_id
    AND role = 'Account Owner'
  ) THEN
    RAISE EXCEPTION 'Only Account Owners can delete team members';
  END IF;

  -- Delete the user's role (this will cascade to delete the user)
  DELETE FROM user_roles
  WHERE user_id = team_member_id
  AND business_id = delete_team_member.business_id
  AND role = 'Team Member';
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_team_member TO authenticated;