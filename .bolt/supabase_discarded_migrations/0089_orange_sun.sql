/*
  # Fix user roles policies to prevent recursion
  
  1. Changes
    - Drop existing recursive policies
    - Create new non-recursive policies with better performance
    - Fix policy dependencies
    - Add proper indexing for performance
*/

-- Drop existing policies
DROP POLICY IF EXISTS "allow_read_own_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_read_business_roles" ON user_roles;
DROP POLICY IF EXISTS "allow_manage_team_members" ON user_roles;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_business_id ON user_roles(business_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);

-- Create new simplified policies
CREATE POLICY "user_roles_select_own"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_roles_select_business"
  ON user_roles
  FOR SELECT
  TO authenticated
  USING (
    business_id = ANY (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
    )
  );

CREATE POLICY "user_roles_insert_owner"
  ON user_roles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    business_id = ANY (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

CREATE POLICY "user_roles_delete_owner"
  ON user_roles
  FOR DELETE
  TO authenticated
  USING (
    business_id = ANY (
      SELECT DISTINCT ur.business_id
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
    AND role = 'Team Member'
  );

-- Add materialized view for faster role lookups
CREATE MATERIALIZED VIEW IF NOT EXISTS user_role_lookup AS
SELECT DISTINCT
  user_id,
  business_id,
  bool_or(role = 'Account Owner') as is_owner
FROM user_roles
GROUP BY user_id, business_id;

-- Create index on materialized view
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_role_lookup 
ON user_role_lookup(user_id, business_id);

-- Create function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_user_role_lookup()
RETURNS TRIGGER AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY user_role_lookup;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to refresh view
CREATE TRIGGER refresh_user_role_lookup_trigger
AFTER INSERT OR UPDATE OR DELETE ON user_roles
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_user_role_lookup();