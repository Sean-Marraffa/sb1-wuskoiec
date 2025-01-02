-- Drop all existing policies
DROP POLICY IF EXISTS "users_can_view_own_memberships" ON business_memberships;
DROP POLICY IF EXISTS "owners_can_manage_memberships" ON business_memberships;

-- Create simple, direct policies for business_memberships
CREATE POLICY "enable_membership_select"
  ON business_memberships
  FOR SELECT 
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "enable_owner_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "enable_owner_insert"
  ON business_memberships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "enable_owner_delete"
  ON business_memberships
  FOR DELETE
  TO authenticated
  USING (
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_business_memberships_role;
CREATE INDEX idx_business_memberships_efficient ON business_memberships(user_id, business_id, role);
CREATE INDEX idx_business_memberships_owner ON business_memberships(user_id, business_id) WHERE role = 'Account Owner';