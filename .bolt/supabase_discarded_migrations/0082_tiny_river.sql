/*
  # Add team members support

  1. Changes
    - Add team member role support
    - Add functions to manage team members
    - Update RLS policies

  2. Security
    - Team members can only access their business data
    - Only Account Owners can manage team members
*/

-- Function to add team member
CREATE OR REPLACE FUNCTION add_team_member(
  team_member_id uuid,
  business_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the executing user is an Account Owner
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND business_id = add_team_member.business_id
    AND role = 'Account Owner'
  ) THEN
    RAISE EXCEPTION 'Only Account Owners can add team members';
  END IF;

  -- Add the team member role
  INSERT INTO user_roles (user_id, business_id, role)
  VALUES (team_member_id, business_id, 'Team Member');
END;
$$;

-- Function to remove team member
CREATE OR REPLACE FUNCTION remove_team_member(
  team_member_id uuid,
  business_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the executing user is an Account Owner
  IF NOT EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND business_id = remove_team_member.business_id
    AND role = 'Account Owner'
  ) THEN
    RAISE EXCEPTION 'Only Account Owners can remove team members';
  END IF;

  -- Remove the team member role
  DELETE FROM user_roles
  WHERE user_id = team_member_id
  AND business_id = remove_team_member.business_id
  AND role = 'Team Member';
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION add_team_member TO authenticated;
GRANT EXECUTE ON FUNCTION remove_team_member TO authenticated;

-- Update RLS policies for user_roles
DROP POLICY IF EXISTS "Users can create initial role" ON user_roles;
DROP POLICY IF EXISTS "Users can view their roles" ON user_roles;

-- Policy for viewing roles
CREATE POLICY "view_user_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can view roles for businesses they belong to
    business_id IN (
      SELECT business_id FROM user_roles
      WHERE user_id = auth.uid()
    )
  );

-- Policy for managing roles
CREATE POLICY "manage_user_roles"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Account Owners can manage roles
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND business_id = user_roles.business_id
      AND role = 'Account Owner'
    )
  )
  WITH CHECK (
    -- Account Owners can manage roles
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_id = auth.uid()
      AND business_id = user_roles.business_id
      AND role = 'Account Owner'
    )
  );

-- Add check constraint for valid roles
ALTER TABLE user_roles
ADD CONSTRAINT valid_roles 
CHECK (role IN ('Account Owner', 'Team Member'));