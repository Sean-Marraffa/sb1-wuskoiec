-- Drop existing policies for inventory tables
DROP POLICY IF EXISTS "Users can view their business inventory" ON inventory_items;
DROP POLICY IF EXISTS "Account owners can manage inventory" ON inventory_items;
DROP POLICY IF EXISTS "Users can view their business categories" ON inventory_categories;
DROP POLICY IF EXISTS "Account owners can manage categories" ON inventory_categories;

-- Simple inventory item policies
CREATE POLICY "inventory_select"
  ON inventory_items
  FOR SELECT
  TO authenticated
  USING (
    -- Members can view inventory
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "inventory_modify"
  ON inventory_items
  FOR ALL
  TO authenticated
  USING (
    -- Members can modify inventory
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

-- Simple category policies
CREATE POLICY "category_select"
  ON inventory_categories
  FOR SELECT
  TO authenticated
  USING (
    -- Members can view categories
    business_id IN (
      SELECT business_id 
      FROM business_memberships 
      WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "category_modify"
  ON inventory_categories
  FOR ALL
  TO authenticated
  USING (
    -- Members can modify categories
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
CREATE INDEX IF NOT EXISTS idx_inventory_business 
ON inventory_items(business_id);

CREATE INDEX IF NOT EXISTS idx_inventory_category 
ON inventory_items(category_id);

CREATE INDEX IF NOT EXISTS idx_categories_business 
ON inventory_categories(business_id);