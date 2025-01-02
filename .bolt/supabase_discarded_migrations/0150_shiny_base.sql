-- Drop all existing policies
DROP POLICY IF EXISTS "enable_super_admin" ON business_memberships;
DROP POLICY IF EXISTS "enable_member_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_select" ON business_memberships;
DROP POLICY IF EXISTS "enable_owner_manage" ON business_memberships;

-- Create single comprehensive policy with all access rules
CREATE POLICY "business_membership_access"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING (
    -- Super admins have full access
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    -- Users can see their own memberships
    user_id = auth.uid()
    OR
    -- Account owners can see/manage memberships for their business
    (
      business_id IN (
        SELECT business_id 
        FROM business_memberships 
        WHERE user_id = auth.uid() 
        AND role = 'Account Owner'
      )
      AND (
        -- For non-SELECT operations, can only manage team members
        current_setting('statement.operation') = 'SELECT'
        OR role = 'Team Member'
      )
    )
  )
  WITH CHECK (
    -- Super admins can modify anything
    (auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true
    OR
    -- Account owners can only add/modify team members
    (
      business_id IN (
        SELECT business_id 
        FROM business_memberships 
        WHERE user_id = auth.uid() 
        AND role = 'Account Owner'
      )
      AND role = 'Team Member'
    )
  );

-- Create efficient indexes
DROP INDEX IF EXISTS idx_memberships_lookup_v3;
DROP INDEX IF EXISTS idx_memberships_owner_v3;

CREATE INDEX idx_memberships_lookup_v4 
ON business_memberships(user_id, business_id, role);

CREATE INDEX idx_memberships_owner_v4 
ON business_memberships(user_id, business_id) 
WHERE role = 'Account Owner';