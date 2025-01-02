-- Drop existing policies
DROP POLICY IF EXISTS "membership_read" ON business_memberships;
DROP POLICY IF EXISTS "membership_write" ON business_memberships;

-- Create policies including super admin access
CREATE POLICY "super_admin_access"
  ON business_memberships
  FOR ALL
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);

CREATE POLICY "member_access"
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

CREATE POLICY "owner_manage"
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

-- Create function to refresh roles
CREATE OR REPLACE FUNCTION refresh_membership_roles()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY business_membership_roles;
  RETURN NULL;
END;
$$;