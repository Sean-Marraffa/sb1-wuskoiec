/*
  # Fix business profile creation policy

  1. Changes
    - Drop and recreate the insert policy
    - Allow users to create their first business profile
    - Maintain validation of required fields

  2. Security
    - Ensure users can only create one business profile initially
    - Maintain field validation requirements
    - Keep existing access controls for other operations
*/

-- Drop the insert policy
DROP POLICY IF EXISTS "Users can create their own business profiles" ON business_profiles;
DROP POLICY IF EXISTS "Users can create business profiles" ON business_profiles;

-- Create new insert policy that allows initial profile creation
CREATE POLICY "Users can create their first business profile"
  ON business_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Allow creation if user doesn't have any existing roles
    NOT EXISTS (
      SELECT 1 FROM user_roles
      WHERE user_roles.user_id = auth.uid()
    )
    -- Ensure required fields are provided
    AND name IS NOT NULL
    AND type IS NOT NULL
    AND contact_email IS NOT NULL
    AND street_address_1 IS NOT NULL
    AND city IS NOT NULL
    AND state_province IS NOT NULL
    AND postal_code IS NOT NULL
    AND country IS NOT NULL
  );