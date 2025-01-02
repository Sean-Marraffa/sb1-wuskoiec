/*
  # Create inventory management tables

  1. New Tables
    - `inventory_items`
      - `id` (uuid, primary key)
      - `business_id` (uuid, foreign key)
      - `name` (text)
      - `description` (text)
      - `quantity` (integer)
      - `price` (decimal)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Security
    - Enable RLS on `inventory_items` table
    - Add policies for business owners and staff to manage their inventory
*/

CREATE TABLE inventory_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) NOT NULL,
  name text NOT NULL,
  description text,
  quantity integer NOT NULL DEFAULT 0,
  price decimal(10,2) NOT NULL DEFAULT 0.00,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Trigger for updating the updated_at timestamp
CREATE OR REPLACE FUNCTION update_inventory_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_inventory_updated_at
  BEFORE UPDATE ON inventory_items
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies
CREATE POLICY "Users can view their business inventory"
  ON inventory_items
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_items.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Account owners can manage inventory"
  ON inventory_items
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_items.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_items.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );