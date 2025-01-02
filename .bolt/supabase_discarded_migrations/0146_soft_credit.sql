-- Drop existing policies
DROP POLICY IF EXISTS "enable_membership_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_manage" ON business_memberships;

-- Create simplified non-recursive policies
CREATE POLICY "basic_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "owner_select"
  ON business_memberships
  FOR SELECT
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
  );

CREATE POLICY "owner_manage"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Must be managing a Team Member role
    role = 'Team Member'
    AND
    -- Must be an owner of the business
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    role = 'Team Member'
    AND
    EXISTS (
      SELECT 1
      FROM business_memberships owner
      WHERE owner.user_id = auth.uid()
      AND owner.business_id = business_memberships.business_id
      AND owner.role = 'Account Owner'
      LIMIT 1
    )
  );

-- Drop existing indexes
DROP INDEX IF EXISTS idx_business_memberships_role_lookup;
DROP INDEX IF EXISTS idx_memberships_lookup;
DROP INDEX IF EXISTS idx_memberships_owner_lookup;

-- Create new indexes conditionally
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_memberships_access_v1'
  ) THEN
    CREATE INDEX idx_memberships_access_v1 
    ON business_memberships(user_id, business_id, role);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_memberships_owner_v1'
  ) THEN
    CREATE INDEX idx_memberships_owner_v1 
    ON business_memberships(business_id, role) 
    WHERE role = 'Account Owner';
  END IF;
END $$;