-- Drop existing policies
DROP POLICY IF EXISTS "read_own_role" ON user_roles;
DROP POLICY IF EXISTS "read_business_roles" ON user_roles;
DROP POLICY IF EXISTS "write_team_members" ON user_roles;

-- Create materialized view for role lookup
CREATE MATERIALIZED VIEW user_role_lookup AS
SELECT DISTINCT
  user_id,
  business_id,
  bool_or(role = 'Account Owner') as is_owner
FROM user_roles
GROUP BY user_id, business_id;

-- Create unique index for fast lookups
CREATE UNIQUE INDEX idx_user_role_lookup_key 
ON user_role_lookup(user_id, business_id);

-- Create function to refresh the materialized view
CREATE OR REPLACE FUNCTION refresh_user_role_lookup()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY user_role_lookup;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to refresh the view
CREATE TRIGGER refresh_user_role_lookup_trigger
AFTER INSERT OR UPDATE OR DELETE ON user_roles
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_user_role_lookup();

-- Create non-recursive policies using the materialized view
CREATE POLICY "enable_read_own_role"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "enable_read_business_roles"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_role_lookup url
      WHERE url.user_id = auth.uid()
      AND url.business_id = user_roles.business_id
      AND url.is_owner = true
    )
  );

CREATE POLICY "enable_write_team_members"
  ON user_roles
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM user_role_lookup url
      WHERE url.user_id = auth.uid()
      AND url.business_id = business_id
      AND url.is_owner = true
    )
    AND role = 'Team Member'
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM user_role_lookup url
      WHERE url.user_id = auth.uid()
      AND url.business_id = business_id
      AND url.is_owner = true
    )
    AND role = 'Team Member'
  );

-- Drop old indexes
DROP INDEX IF EXISTS idx_user_roles_access;

-- Create new optimized index
CREATE INDEX idx_user_roles_lookup 
ON user_roles(user_id, business_id, role);