/*
  # Add Reservation Items Support
  
  1. New Tables
    - `reservation_items`
      - Links reservations to inventory items with quantities
      - Tracks pricing for each item
      
  2. Security
    - Enable RLS
    - Add policies for business owners and staff
*/

-- Create reservation items table
CREATE TABLE reservation_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid REFERENCES reservations(id) ON DELETE CASCADE NOT NULL,
  inventory_item_id uuid REFERENCES inventory_items(id) NOT NULL,
  quantity integer NOT NULL CHECK (quantity > 0),
  rate_type text NOT NULL CHECK (rate_type IN ('hourly', 'daily', 'weekly', 'monthly')),
  rate_amount decimal(10,2) NOT NULL,
  subtotal decimal(10,2) NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add discount fields to reservations
ALTER TABLE reservations
ADD COLUMN discount_amount decimal(10,2),
ADD COLUMN discount_type text CHECK (discount_type IN ('percentage', 'fixed'));

-- Enable RLS
ALTER TABLE reservation_items ENABLE ROW LEVEL SECURITY;

-- Update trigger
CREATE TRIGGER update_reservation_items_updated_at
  BEFORE UPDATE ON reservation_items
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies
CREATE POLICY "Users can view their business reservation items"
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
  );

CREATE POLICY "Account owners can manage reservation items"
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