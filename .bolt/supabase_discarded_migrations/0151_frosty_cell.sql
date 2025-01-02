-- Drop existing policy
DROP POLICY IF EXISTS "business_membership_access" ON business_memberships;

-- Create separate policies for different operations
CREATE POLICY "allow_super_admin"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "allow_select_own"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "allow_select_as_owner"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT DISTINCT bm.business_id
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_insert_as_owner"
  ON business_memberships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT bm.business_id
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_update_as_owner"
  ON business_memberships
  FOR UPDATE
  TO authenticated
  USING (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT bm.business_id
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
    )
  )
  WITH CHECK (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT bm.business_id
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
    )
  );

CREATE POLICY "allow_delete_as_owner"
  ON business_memberships
  FOR DELETE
  TO authenticated
  USING (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT bm.business_id
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_memberships_lookup_v4;
DROP INDEX IF EXISTS idx_memberships_owner_v4;

CREATE INDEX idx_memberships_lookup_v5 
ON business_memberships(user_id, business_id, role);

CREATE INDEX idx_memberships_owner_v5 
ON business_memberships(user_id, business_id) 
WHERE role = 'Account Owner';