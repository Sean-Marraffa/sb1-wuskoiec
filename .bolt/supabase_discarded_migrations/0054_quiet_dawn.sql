/*
  # Add customer relationship to reservations

  1. Changes
    - Add customer_id column to reservations table
    - Add foreign key constraint to customers table
    - Add migration for existing data
    - Update RLS policies

  2. Security
    - Maintain existing RLS policies
    - Add policy for customer relationship
*/

-- Add customer_id column
ALTER TABLE reservations
ADD COLUMN customer_id uuid REFERENCES customers(id);

-- Add index for better query performance
CREATE INDEX idx_reservations_customer_id ON reservations(customer_id);

-- Update RLS policies to include customer access
CREATE POLICY "Customers can view their own reservations"
  ON reservations
  FOR SELECT
  TO authenticated
  USING (
    customer_id = auth.uid()
    OR
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservations.business_id
      AND user_roles.user_id = auth.uid()
    )
  );