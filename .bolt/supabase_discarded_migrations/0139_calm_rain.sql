-- Drop existing policies
DROP POLICY IF EXISTS "basic_membership_access" ON business_memberships;
DROP POLICY IF EXISTS "owner_membership_access" ON business_memberships;
DROP POLICY IF EXISTS "owner_membership_management" ON business_memberships;

-- Create simplified policies without CTEs or recursion
CREATE POLICY "view_own_memberships"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "manage_team_members"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Only Account Owners can manage team members
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    -- Can only manage Team Member roles
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  );

-- Update reservation policies to use simpler queries
DROP POLICY IF EXISTS "enable_read_reservations" ON reservations;
DROP POLICY IF EXISTS "enable_write_reservations" ON reservations;

CREATE POLICY "reservation_access"
  ON reservations
  FOR ALL
  TO authenticated
  USING (
    -- Users can access reservations where they have a membership
    EXISTS (
      SELECT 1
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.business_id = reservations.business_id
      LIMIT 1
    )
    OR customer_id = auth.uid()
  )
  WITH CHECK (
    -- Only members can create/modify reservations
    EXISTS (
      SELECT 1
      FROM business_memberships bm
      WHERE bm.user_id = auth.uid()
      AND bm.business_id = reservations.business_id
      LIMIT 1
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_business_memberships_lookup;
DROP INDEX IF EXISTS idx_business_memberships_owner_lookup;

CREATE INDEX idx_memberships_user_role 
ON business_memberships(user_id, role);

CREATE INDEX idx_memberships_business_role 
ON business_memberships(business_id, role);