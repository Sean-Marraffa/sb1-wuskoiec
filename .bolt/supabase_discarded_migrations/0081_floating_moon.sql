-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their business subscriptions" ON business_subscriptions;
DROP POLICY IF EXISTS "Users can create business subscriptions" ON business_subscriptions;

-- Create policies for business_subscriptions
CREATE POLICY "Users can view their business subscriptions"
  ON business_subscriptions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = business_subscriptions.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create business subscriptions"
  ON business_subscriptions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow if user has owner role for this business
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = business_subscriptions.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
    OR
    -- Allow if this is the user's pending business
    business_id = (auth.jwt() -> 'user_metadata' ->> 'pending_business_id')::uuid
  );

-- Add super admin policies
CREATE POLICY "Super admins can manage subscriptions"
  ON business_subscriptions
  TO authenticated
  USING ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true)
  WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'is_super_admin')::boolean = true);