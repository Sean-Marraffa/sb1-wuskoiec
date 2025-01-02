-- Drop existing policies and views
DROP POLICY IF EXISTS "super_admin_access" ON business_memberships;
DROP POLICY IF EXISTS "member_access" ON business_memberships;
DROP POLICY IF EXISTS "owner_manage" ON business_memberships;
DROP MATERIALIZED VIEW IF EXISTS business_membership_roles;
DROP TRIGGER IF EXISTS refresh_membership_roles_trigger ON business_memberships;
DROP FUNCTION IF EXISTS refresh_membership_roles();

-- Create simple non-recursive policies
CREATE POLICY "enable_super_admin"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "enable_member_select"
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
      SELECT DISTINCT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

CREATE POLICY "enable_owner_manage"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  )
  WITH CHECK (
    role = 'Team Member'
    AND
    business_id IN (
      SELECT DISTINCT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
      AND role = 'Account Owner'
    )
  );

-- Create efficient indexes
CREATE INDEX IF NOT EXISTS idx_memberships_lookup_v3 
ON business_memberships(user_id, business_id, role);

CREATE INDEX IF NOT EXISTS idx_memberships_owner_v3 
ON business_memberships(user_id, business_id) 
WHERE role = 'Account Owner';