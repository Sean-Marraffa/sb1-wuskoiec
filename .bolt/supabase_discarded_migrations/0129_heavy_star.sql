-- Drop existing policies
DROP POLICY IF EXISTS "role_select_v4" ON user_roles;
DROP POLICY IF EXISTS "owner_select_v4" ON user_roles;
DROP POLICY IF EXISTS "owner_manage_v4" ON user_roles;

-- Create non-recursive policies using CTEs
CREATE POLICY "user_role_select_v5"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own roles
    user_id = auth.uid()
    OR
    -- Users can see roles in businesses where they are an owner
    EXISTS (
      WITH owner_businesses AS (
        SELECT DISTINCT business_id
        FROM user_roles base
        WHERE base.user_id = auth.uid()
        AND base.role = 'Account Owner'
      )
      SELECT 1 
      FROM owner_businesses 
      WHERE business_id = user_roles.business_id
    )
  );

CREATE POLICY "user_role_manage_v5"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    -- Must be a Team Member role
    role = 'Team Member'
    AND
    -- Must be an owner of the business
    EXISTS (
      WITH owner_businesses AS (
        SELECT DISTINCT business_id
        FROM user_roles base
        WHERE base.user_id = auth.uid()
        AND base.role = 'Account Owner'
      )
      SELECT 1 
      FROM owner_businesses 
      WHERE business_id = user_roles.business_id
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    EXISTS (
      WITH owner_businesses AS (
        SELECT DISTINCT business_id
        FROM user_roles base
        WHERE base.user_id = auth.uid()
        AND base.role = 'Account Owner'
      )
      SELECT 1 
      FROM owner_businesses 
      WHERE business_id = user_roles.business_id
    )
  );

-- Drop old indexes
DROP INDEX IF EXISTS idx_user_roles_user_lookup_v4;
DROP INDEX IF EXISTS idx_user_roles_owner_lookup_v4;
DROP INDEX IF EXISTS idx_user_roles_team_lookup_v4;

-- Create optimized indexes for CTE queries
CREATE INDEX idx_user_roles_lookup_v5 ON user_roles(user_id, role, business_id);
CREATE INDEX idx_user_roles_owner_v5 ON user_roles(user_id, business_id) WHERE role = 'Account Owner';