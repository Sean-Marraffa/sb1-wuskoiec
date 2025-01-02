/*
  # Add reservation status settings

  1. New Tables
    - `reservation_status_settings`
      - `business_id` (uuid, references business_profiles)
      - `status_key` (text)
      - `label` (text)
      - Composite primary key on (business_id, status_key)

  2. Security
    - Enable RLS
    - Add policies for viewing and managing status settings
*/

-- Create reservation status settings table
CREATE TABLE reservation_status_settings (
  business_id uuid REFERENCES business_profiles(id) NOT NULL,
  status_key text NOT NULL,
  label text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  PRIMARY KEY (business_id, status_key)
);

-- Enable RLS
ALTER TABLE reservation_status_settings ENABLE ROW LEVEL SECURITY;

-- Update trigger
CREATE TRIGGER update_reservation_status_settings_updated_at
  BEFORE UPDATE ON reservation_status_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_inventory_updated_at();

-- Policies
CREATE POLICY "Users can view their business status settings"
  ON reservation_status_settings
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservation_status_settings.business_id
      AND user_roles.user_id = auth.uid()
    )
  );

CREATE POLICY "Account owners can manage status settings"
  ON reservation_status_settings
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservation_status_settings.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.business_id = reservation_status_settings.business_id
      AND user_roles.user_id = auth.uid()
      AND user_roles.role = 'Account Owner'
    )
  );