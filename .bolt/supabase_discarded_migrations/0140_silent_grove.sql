-- Drop all existing policies
DROP POLICY IF EXISTS "view_own_memberships" ON business_memberships;
DROP POLICY IF EXISTS "manage_team_members" ON business_memberships;
DROP POLICY IF EXISTS "reservation_access" ON reservations;

-- Create materialized view for owner lookup
CREATE MATERIALIZED VIEW business_owners AS
SELECT DISTINCT business_id, user_id
FROM business_memberships
WHERE role = 'Account Owner';

-- Create unique index for efficient lookups
CREATE UNIQUE INDEX idx_business_owners 
ON business_owners(business_id, user_id);

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_business_owners()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY business_owners;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to refresh view
CREATE TRIGGER refresh_business_owners_trigger
AFTER INSERT OR UPDATE OR DELETE ON business_memberships
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_business_owners();

-- Simple membership policies
CREATE POLICY "membership_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own memberships
    user_id = auth.uid()
    OR
    -- Owners can see all memberships for their business
    business_id IN (
      SELECT business_id 
      FROM business_owners 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "membership_insert"
  ON business_memberships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Only owners can add members
    business_id IN (
      SELECT business_id 
      FROM business_owners 
      WHERE user_id = auth.uid()
    )
    -- Can only add team members
    AND role = 'Team Member'
  );

CREATE POLICY "membership_delete"
  ON business_memberships
  FOR DELETE
  TO authenticated
  USING (
    -- Only owners can remove members
    business_id IN (
      SELECT business_id 
      FROM business_owners 
      WHERE user_id = auth.uid()
    )
    -- Can only remove team members
    AND role = 'Team Member'
  );

-- Simple reservation policies
CREATE POLICY "reservation_select"
  ON reservations
  FOR SELECT
  TO authenticated
  USING (
    -- Members can view reservations
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
    OR customer_id = auth.uid()
  );

CREATE POLICY "reservation_modify"
  ON reservations
  FOR ALL
  TO authenticated
  USING (
    -- Members can modify reservations
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_memberships_user_role;
DROP INDEX IF EXISTS idx_memberships_business_role;

CREATE INDEX idx_memberships_lookup 
ON business_memberships(user_id, business_id, role);

CREATE INDEX idx_reservations_lookup 
ON reservations(business_id, customer_id);