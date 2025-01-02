/*
  # Fix Reservation Relationships

  1. Changes
    - Add foreign key constraints for reservation items
    - Add indexes for better query performance
    - Update RLS policies for proper access control

  2. Security
    - Add RLS policies for reservation items
    - Maintain existing business access policies
*/

-- Add proper foreign key constraints
ALTER TABLE reservation_items
DROP CONSTRAINT IF EXISTS reservation_items_reservation_id_fkey,
ADD CONSTRAINT reservation_items_reservation_id_fkey
  FOREIGN KEY (reservation_id)
  REFERENCES reservations(id)
  ON DELETE CASCADE;

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_reservation_items_reservation_id 
ON reservation_items(reservation_id);

CREATE INDEX IF NOT EXISTS idx_reservation_items_inventory_item_id 
ON reservation_items(inventory_item_id);

-- Update RLS policies for reservation items
DROP POLICY IF EXISTS "Users can view their business reservation items" ON reservation_items;
DROP POLICY IF EXISTS "Account owners can manage reservation items" ON reservation_items;

CREATE POLICY "enable_read_for_business_users"
  ON reservation_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN user_roles ur ON ur.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND ur.user_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = reservation_items.reservation_id
      AND r.customer_id = auth.uid()
    )
  );

CREATE POLICY "enable_write_for_business_owners"
  ON reservation_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN user_roles ur ON ur.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM reservations r
      JOIN user_roles ur ON ur.business_id = r.business_id
      WHERE r.id = reservation_items.reservation_id
      AND ur.user_id = auth.uid()
      AND ur.role = 'Account Owner'
    )
  );