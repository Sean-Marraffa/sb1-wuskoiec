-- Drop existing policies
DROP POLICY IF EXISTS "membership_view" ON business_memberships;
DROP POLICY IF EXISTS "membership_manage" ON business_memberships;

-- Create non-recursive policies using separate subqueries
CREATE POLICY "enable_membership_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see their own memberships
    user_id = auth.uid()
  );

CREATE POLICY "enable_owner_select"
  ON business_memberships
  FOR SELECT
  TO authenticated
  USING (
    -- Owners can see all memberships for their businesses
    business_id IN (
      SELECT DISTINCT business_id
      FROM business_memberships base
      WHERE base.user_id = auth.uid()
      AND base.role = 'Account Owner'
    )
  );

CREATE POLICY "enable_owner_manage"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Only owners can manage team members
    business_id IN (
      SELECT DISTINCT business_id
      FROM business_memberships base
      WHERE base.user_id = auth.uid()
      AND base.role = 'Account Owner'
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    -- Same conditions for inserts/updates
    business_id IN (
      SELECT DISTINCT business_id
      FROM business_memberships base
      WHERE base.user_id = auth.uid()
      AND base.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Drop old index if it exists
DROP INDEX IF EXISTS idx_business_memberships_role_lookup;

-- Create new indexes if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_business_memberships_user'
  ) THEN
    CREATE INDEX idx_business_memberships_user 
    ON business_memberships(user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes 
    WHERE indexname = 'idx_business_memberships_owner'
  ) THEN
    CREATE INDEX idx_business_memberships_owner 
    ON business_memberships(user_id, business_id) 
    WHERE role = 'Account Owner';
  END IF;
END $$;