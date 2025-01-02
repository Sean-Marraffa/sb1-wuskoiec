/*
  # Add Reservations Support
  
  1. New Tables
    - `reservations`
      - `id` (uuid, primary key)
      - `business_id` (uuid, references business_profiles)
      - `customer_name` (text)
      - `start_date` (timestamptz)
      - `end_date` (timestamptz)
      - `total_price` (decimal)
      - `status` (text)
      - Timestamps (created_at, updated_at)
      
  2. Security
    - Enable RLS
    - Add policies for business owners and staff
*/

-- Create reservations table
CREATE TABLE reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id uuid REFERENCES business_profiles(id) NOT NULL,
  customer_name text NOT NULL,
  start_date timestamptz NOT NULL,
  end_date timestamptz NOT NULL,
  total_price decimal(10,2) NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  -- Add constraint to ensure end_date is after start_date
  CONSTRAINT valid_date_range CHECK (end_date > start_date)
);

-- Enable RLS
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

-- Update trigger
CREATE TRIGGER update_reservations_updated_at
  BEFORE UPDATE ON reservations
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies
CREATE POLICY "Users can view their business reservations"
  ON reservations
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservations.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Account owners can manage reservations"
  ON reservations
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservations.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservations.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );