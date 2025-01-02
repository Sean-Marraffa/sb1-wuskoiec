-- Drop existing policies
DROP POLICY IF EXISTS "allow_read_business_profiles" ON business_profiles;
DROP POLICY IF EXISTS "allow_update_business_profiles" ON business_profiles;

-- Create simplified policies
CREATE POLICY "enable_read_business_profiles"
  ON business_profiles
  FOR SELECT
  TO authenticated
  USING (
    -- Allow if user has a direct role for this business
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      LIMIT 1
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

CREATE POLICY "enable_update_business_profiles"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow if user is Account Owner
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  )
  WITH CHECK (
    -- Same conditions as USING clause
    EXISTS (
      SELECT 1 
      FROM user_roles ur
      WHERE ur.user_id = auth.uid()
      AND ur.business_id = id
      AND ur.role = 'Account Owner'
      LIMIT 1
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

-- Create optimized indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_business_lookup 
ON user_roles(user_id, business_id, role);

CREATE INDEX IF NOT EXISTS idx_business_profiles_lookup
ON business_profiles(id)
WHERE status != 'withdrawn';