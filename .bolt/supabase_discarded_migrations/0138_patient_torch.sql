-- Drop existing policies
DROP POLICY IF EXISTS "enable_membership_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_insert" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_delete" ON business_memberships;

-- Create simple, non-recursive policies
CREATE POLICY "basic_membership_access"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own memberships
    user_id = auth.uid()
  );

CREATE POLICY "owner_membership_access"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Cache owner check in a CTE to prevent recursion
    EXISTS (
      WITH owner_roles AS (
        SELECT DISTINCT bm.business_id
        FROM business_memberships bm
        WHERE bm.user_id = auth.uid()
        AND bm.role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = business_memberships.business_id
    )
  );

CREATE POLICY "owner_membership_management"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Must be managing a Team Member role
    role = 'Team Member'
    AND
    -- Cache owner check in a CTE to prevent recursion
    EXISTS (
      WITH owner_roles AS (
        SELECT DISTINCT bm.business_id
        FROM business_memberships bm
        WHERE bm.user_id = auth.uid()
        AND bm.role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = business_memberships.business_id
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    EXISTS (
      WITH owner_roles AS (
        SELECT DISTINCT bm.business_id
        FROM business_memberships bm
        WHERE bm.user_id = auth.uid()
        AND bm.role = 'Account Owner'
      )
      SELECT 1 FROM owner_roles WHERE business_id = business_memberships.business_id
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_business_memberships_efficient;
DROP INDEX IF EXISTS idx_business_memberships_owner;

CREATE INDEX idx_business_memberships_lookup 
ON business_memberships(user_id, business_id, role);

CREATE INDEX idx_business_memberships_owner_lookup 
ON business_memberships(user_id, business_id) 
WHERE role = 'Account Owner';