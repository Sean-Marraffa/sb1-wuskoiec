-- First drop the dependent policies
DROP POLICY IF EXISTS "membership_select" ON business_memberships;
DROP POLICY IF EXISTS "membership_insert" ON business_memberships;
DROP POLICY IF EXISTS "membership_delete" ON business_memberships;

-- Now we can safely drop the materialized view and related objects
DROP TRIGGER IF EXISTS refresh_business_owners_trigger ON business_memberships;
DROP FUNCTION IF EXISTS refresh_business_owners();
DROP MATERIALIZED VIEW IF EXISTS business_owners;

-- Update business_profiles policies
DROP POLICY IF EXISTS "enable_read_business_profiles" ON business_profiles;
DROP POLICY IF EXISTS "enable_update_business_profiles" ON business_profiles;

-- Create new policies for business_profiles
CREATE POLICY "super_admin_access"
  ON business_profiles
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "member_access"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM business_memberships bm
      WHERE bm.business_id = id
      AND bm.user_id = auth.uid()
      LIMIT 1
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

CREATE POLICY "owner_access"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM business_memberships bm
      WHERE bm.business_id = id
      AND bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
      LIMIT 1
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM business_memberships bm
      WHERE bm.business_id = id
      AND bm.user_id = auth.uid()
      AND bm.role = 'Account Owner'
      LIMIT 1
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

-- Create new policies for business_memberships
CREATE POLICY "membership_view"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  );

CREATE POLICY "membership_manage"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
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

-- Create efficient indexes
CREATE INDEX IF NOT EXISTS idx_business_memberships_role_lookup 
ON business_memberships(business_id, user_id, role);