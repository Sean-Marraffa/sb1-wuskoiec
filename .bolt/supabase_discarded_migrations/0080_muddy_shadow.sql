-- Drop existing trigger and function
DROP TRIGGER IF EXISTS before_business_profile_insert ON business_profiles;
DROP FUNCTION IF EXISTS update_pending_business_profile();

-- Update business profiles RLS to allow updating pending profiles
DROP POLICY IF EXISTS "Users can update their business profiles" ON business_profiles;

CREATE POLICY "Users can update their business profiles"
  ON business_profiles
  FOR UPDATE
  TO authenticated
  USING (
    -- Allow if user has owner role for this business
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
    OR
    -- Allow if this is the user's pending business
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  )
  WITH CHECK (
    -- Same conditions as USING clause
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
    OR
    id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );