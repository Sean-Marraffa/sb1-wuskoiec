/*
  # Add categories to inventory system

  1. New Tables
    - `inventory_categories`
      - `id` (uuid, primary key)
      - `business_id` (uuid, references business_profiles)
      - `name` (text)
      - `description` (text, optional)
      - `created_at` (timestamp)
      - `updated_at` (timestamp)

  2. Changes
    - Add category_id to inventory_items table
    - Add foreign key constraint

  3. Security
    - Enable RLS
    - Add policies for business owners and users
*/

-- Create categories table
CREATE TABLE inventory_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) NOT NULL,
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Add category to inventory items
ALTER TABLE inventory_items
ADD COLUMN category_id uuid REFERENCES inventory_categories(id);

-- Enable RLS
ALTER TABLE inventory_categories ENABLE ROW LEVEL SECURITY;

-- Update trigger for categories
CREATE TRIGGER update_inventory_categories_updated_at
  BEFORE UPDATE ON inventory_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies for inventory_categories

-- View policy
CREATE POLICY "Users can view their business categories"
  ON inventory_categories
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_categories.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

-- Manage policy for account owners
CREATE POLICY "Account owners can manage categories"
  ON inventory_categories
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_categories.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = inventory_categories.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );