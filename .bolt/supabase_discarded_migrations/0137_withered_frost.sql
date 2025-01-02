-- Drop existing policies
DROP POLICY IF EXISTS "Users can view their business reservations" ON reservations;
DROP POLICY IF EXISTS "Account owners can manage reservations" ON reservations;

-- Create comprehensive policies for reservations
CREATE POLICY "enable_read_reservations"
  ON reservations
  FOR SELECT
  TO authenticated
  USING (
    -- Users can see reservations for businesses where they have a membership
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
    )
    OR
    -- Customers can see their own reservations
    customer_id = auth.uid()
  );

CREATE POLICY "enable_write_reservations"
  ON reservations
  FOR ALL
  TO authenticated
  USING (
    -- Only business members can manage reservations
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    -- Only business members can manage reservations
    business_id IN (
      SELECT business_id
      FROM business_memberships
      WHERE user_id = auth.uid()
    )
  );

-- Create helpful indexes
CREATE INDEX IF NOT EXISTS idx_reservations_business_status 
ON reservations(business_id, status);

CREATE INDEX IF NOT EXISTS idx_reservations_customer 
ON reservations(customer_id);