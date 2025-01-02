-- Drop existing policies
DROP POLICY IF EXISTS "select_own_roles" ON user_roles;
DROP POLICY IF EXISTS "select_business_roles" ON user_roles;
DROP POLICY IF EXISTS "manage_team_members" ON user_roles;
DROP POLICY IF EXISTS "enable_read_business_profiles" ON business_profiles;
DROP POLICY IF EXISTS "enable_update_business_profiles" ON business_profiles;

-- Create simplified user_roles policies
CREATE POLICY "basic_user_role_access"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
  );

CREATE POLICY "owner_role_access"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Account Owners can manage team members
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    AND (
      -- Can only manage Team Member roles
      role = 'Team Member'
      OR
      -- Or view any role
      current_setting('role_access.operation', true) = 'SELECT'
    )
  )
  WITH CHECK (
    -- Account Owners can only add/modify Team Member roles
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = business_id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Create simplified business_profiles policies
CREATE POLICY "basic_business_profile_access"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can access businesses where they have a role
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      LIMIT 1
    )
    OR
    -- Or their pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

CREATE POLICY "owner_business_profile_access"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Account Owners can update their business
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    OR
    -- Users can update their pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  )
  WITH CHECK (
    -- Same conditions as USING clause
    EXISTS (
      SELECT 1
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_user_roles_lookup;
CREATE INDEX idx_user_roles_efficient_lookup 
ON user_roles(user_id, business_id, role);

DROP INDEX IF EXISTS idx_business_profiles_lookup;
CREATE INDEX idx_business_profiles_efficient_lookup
ON business_profiles(id, status);