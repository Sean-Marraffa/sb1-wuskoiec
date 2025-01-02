/*
  # Fix Reservation Customer Relationship

  1. Changes
    - Add customer_id column to reservations table
    - Add foreign key constraint to customers table
    - Add index for better query performance
    - Update RLS policies

  2. Security
    - Add RLS policy for customer access
    - Maintain existing business access policies
*/

-- Add customer_id column if it doesn't exist
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'reservations' AND column_name = 'customer_id'
  ) THEN
    ALTER TABLE reservations ADD COLUMN customer_id uuid REFERENCES customers(id);
  END IF;
END $$;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_reservations_customer_id ON reservations(customer_id);

-- Update RLS policies
DROP POLICY IF EXISTS "Customers can view their own reservations" ON reservations;

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

-- Function to get reservation details with customer info
CREATE OR REPLACE FUNCTION get_reservation_details(reservation_id uuid)
RETURNS TABLE (
  id uuid,
  business_id uuid,
  customer_id uuid,
  customer_name text,
  customer_email text,
  customer_phone text,
  start_date timestamptz,
  end_date timestamptz,
  total_price decimal,
  status text,
  created_at timestamptz,
  updated_at timestamptz
) SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT 
    r.id,
    r.business_id,
    r.customer_id,
    c.name as customer_name,
    c.email as customer_email,
    c.phone as customer_phone,
    r.start_date,
    r.end_date,
    r.total_price,
    r.status,
    r.created_at,
    r.updated_at
  FROM reservations r
  LEFT JOIN customers c ON c.id = r.customer_id
  WHERE r.id = reservation_id
  AND (
    -- Allow access if user is customer
    r.customer_id = auth.uid()
    OR
    -- Allow access if user has role in business
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = r.business_id
      AND user_roles.user_id = auth.uid()
    )
  );
END;
$$ LANGUAGE plpgsql;