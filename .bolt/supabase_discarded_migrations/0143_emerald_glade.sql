-- Drop existing policies for reservation_items
DROP POLICY IF EXISTS "Users can view their business reservation items" ON reservation_items;
DROP POLICY IF EXISTS "Account owners can manage reservation items" ON reservation_items;

-- Create simple policies for reservation items
CREATE POLICY "reservation_items_select"
  ON reservation_items
  FOR SELECT
  TO authenticated
  USING (
    -- Members can view items for reservations in their business
    EXISTS (
      SELECT 1 
      FROM reservations r
      JOIN business_memberships bm ON bm.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND bm.user_id = auth.uid()
      LIMIT 1
    )
    OR
    -- Customers can view their own reservation items
    EXISTS (
      SELECT 1 
      FROM reservations r
      WHERE r.id = reservation_items.reservation_id
      AND r.customer_id = auth.uid()
      LIMIT 1
    )
  );

CREATE POLICY "reservation_items_modify"
  ON reservation_items
  FOR ALL
  TO authenticated
  USING (
    -- Members can modify items for reservations in their business
    EXISTS (
      SELECT 1 
      FROM reservations r
      JOIN business_memberships bm ON bm.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND bm.user_id = auth.uid()
      LIMIT 1
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 
      FROM reservations r
      JOIN business_memberships bm ON bm.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND bm.user_id = auth.uid()
      LIMIT 1
    )
  );

-- Optimize indexes
CREATE INDEX IF NOT EXISTS idx_reservation_items_reservation
ON reservation_items(reservation_id);

CREATE INDEX IF NOT EXISTS idx_reservation_items_inventory
ON reservation_items(inventory_item_id);