/*
  # Fix business profiles schema and RLS

  1. Changes
    - Make address column nullable since we use separate address fields now
    - Update RLS policies to ensure proper access for new address fields

  2. Security
    - Maintain existing RLS policies while fixing schema
*/

-- Make address column nullable since we use separate fields now
ALTER TABLE business_profiles 
ALTER COLUMN address DROP NOT NULL;

-- Drop and recreate insert policy to handle new fields
DROP POLICY IF EXISTS "Users can create business profiles" ON business_profiles;

CREATE POLICY "Users can create business profiles"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Ensure required fields are provided
    name IS NOT NULL AND
    type IS NOT NULL AND
    contact_email IS NOT NULL AND
    street_address_1 IS NOT NULL AND
    city IS NOT NULL AND
    state_province IS NOT NULL AND
    postal_code IS NOT NULL AND
    country IS NOT NULL
  );