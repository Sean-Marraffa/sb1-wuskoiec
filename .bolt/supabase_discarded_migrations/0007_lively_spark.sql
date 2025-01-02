/*
  # Add detailed address fields to business profiles

  1. Changes
    - Add detailed address fields to business_profiles table
    - Add function to migrate existing address data
    - Add function to format full address

  2. New Fields
    - street_address_1
    - street_address_2
    - city
    - state_province
    - postal_code
    - country
*/

-- Add new address fields
ALTER TABLE business_profiles
ADD COLUMN street_address_1 text,
ADD COLUMN street_address_2 text,
ADD COLUMN city text,
ADD COLUMN state_province text,
ADD COLUMN postal_code text,
ADD COLUMN country text;

-- Function to format full address
CREATE OR REPLACE FUNCTION format_full_address(
  street1 text,
  street2 text,
  city text,
  state text,
  postal text,
  country text
) RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  full_address text;
BEGIN
  full_address := street1;
  
  IF street2 IS NOT NULL AND street2 <> '' THEN
    full_address := full_address || E'\n' || street2;
  END IF;
  
  full_address := full_address || E'\n' || city;
  
  IF state IS NOT NULL AND state <> '' THEN
    full_address := full_address || ', ' || state;
  END IF;
  
  IF postal IS NOT NULL AND postal <> '' THEN
    full_address := full_address || ' ' || postal;
  END IF;
  
  full_address := full_address || E'\n' || country;
  
  RETURN full_address;
END;
$$;