-- Create materialized view for caching owner status
CREATE MATERIALIZED VIEW business_membership_roles AS
SELECT DISTINCT
  business_id,
  user_id,
  role
FROM business_memberships;

-- Create unique index for fast lookups
CREATE UNIQUE INDEX idx_business_membership_roles 
ON business_membership_roles(business_id, user_id, role);

-- Drop existing policies
DROP POLICY IF EXISTS "basic_select" ON business_memberships;
DROP POLICY IF EXISTS "owner_select" ON business_memberships;
DROP POLICY IF EXISTS "owner_manage" ON business_memberships;

-- Create non-recursive policies using materialized view
CREATE POLICY "membership_read"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own memberships
    user_id = auth.uid()
    OR
    -- Owners can see all memberships for their business
    EXISTS (
      SELECT 1 
      FROM business_membership_roles roles
      WHERE roles.user_id = auth.uid()
      AND roles.business_id = business_memberships.business_id
      AND roles.role = 'Account Owner'
      LIMIT 1
    )
  );

CREATE POLICY "membership_write"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Only owners can manage team members
    EXISTS (
      SELECT 1 
      FROM business_membership_roles roles
      WHERE roles.user_id = auth.uid()
      AND roles.business_id = business_memberships.business_id
      AND roles.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    EXISTS (
      SELECT 1 
      FROM business_membership_roles roles
      WHERE roles.user_id = auth.uid()
      AND roles.business_id = business_memberships.business_id
      AND roles.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_membership_roles()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY business_membership_roles;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to refresh view
CREATE TRIGGER refresh_membership_roles_trigger
AFTER INSERT OR UPDATE OR DELETE ON business_memberships
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_membership_roles();

-- Drop old indexes
DROP INDEX IF EXISTS idx_memberships_access_v1;
DROP INDEX IF EXISTS idx_memberships_owner_v1;

-- Create new optimized indexes
CREATE INDEX idx_memberships_user_v2 
ON business_memberships(user_id);

CREATE INDEX idx_memberships_business_v2 
ON business_memberships(business_id, role);