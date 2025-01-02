-- Drop existing policies for customers table
DROP POLICY IF EXISTS "Users can view their business customers" ON customers;
DROP POLICY IF EXISTS "Account owners can manage customers" ON customers;

-- Simple customer policies
CREATE POLICY "customer_select"
  ON customers
  FOR SELECT
  TO authenticated
  USING (
    -- Members can view customers
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "customer_modify"
  ON customers
  FOR ALL
  TO authenticated
  USING (
    -- Members can modify customers
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  );

-- Optimize indexes
DROP INDEX IF EXISTS idx_customers_business;
CREATE INDEX idx_customers_lookup 
ON customers(business_id);

CREATE INDEX idx_customers_email 
ON customers(business_id, email) 
WHERE email IS NOT NULL;

CREATE INDEX idx_customers_name 
ON customers(business_id, name);